defmodule SunstoneWeb.PageLive do
  use SunstoneWeb, :live_view
  alias Sunstone.Accounts.Guardian
  alias Sunstone.Chats
  alias Sunstone.Accounts
  alias Sunstone.Accounts.Social
  @impl true
  def mount(%{"hash_id" => hash_id}, %{"guardian_default_token" => token}, socket) do
    {_, user, _} = Guardian.resource_from_token(token)
    office_id = SunstoneWeb.UserController.decode_id(hash_id)
    tables = Chats.list_tables(office_id)
    office = Chats.get_office!(office_id)
    if connected?(socket) do
      Accounts.subscribe(office_id)
      SunstoneWeb.Live.LiveMonitor.monitor(self(), __MODULE__, %{user: user, office_id: office_id})
      
    end 
    if Chats.user_is_listed_in_office(office, user) do
      changeset = case user.socials do
        nil -> Social.changeset(%Social{}, %{}, user)
        social -> 
        social = Accounts.get_social!(social.id)
        Social.changeset(social, %{}, user)
      end
      {:ok, assign(socket, user: user, tables: tables, chat_list: [], office_id: office_id, office: office, changeset: changeset, broadcast: nil, connected_list: [], show_sub_btn: false, nudge_list: [], join_notification_list: [], leave_notification_list: [])}
    else
      {:ok, redirect(socket, to: Routes.office_path(socket, :uninvited, hash_id))}
    end



  end

  def send_office_notification(office, user) do
    colleagues = office.users
    Enum.each(colleagues, fn colleague -> 
      colleague = Accounts.get_user!(colleague.id)
      if(colleague.id != user.id && colleague.notifications != nil ) do
        send_notification(colleague, "#{user.name} has entered #{office.name}.")
      end
    end)
  end
  def send_table_notification(table, user) do
    colleagues = table.users
    Enum.each(colleagues, fn colleague -> 
      colleague = Accounts.get_user!(colleague.id)
      if(colleague.id != user.id && colleague.notifications != nil ) do
        send_notification(colleague, "#{user.name} has join your desk.")
      end
    end)
  end
  def send_notification(user, text) do
    case user.notifications do
      nil -> {:error}
      notification ->
        body = ~s({"body": "#{text}"})
        subscription = %{keys: %{p256dh: notification.p256dh, auth: notification.auth }, endpoint: notification.endpoint}
        gcm_api_key = nil

        # or just send the push
        WebPushEncryption.send_web_push(body, subscription, gcm_api_key)
    end

    
  end

  def handle_event("subscribe-notification", param, socket) do
    user = socket.assigns.user
    Accounts.create_update_notifications(param,user)
    {:noreply, assign(socket, nothing: [])}
  end
  
  def handle_event("nudge", %{"peer-id" => peer_id}, socket) do
    user = socket.assigns.user
    office_id = socket.assigns.office_id
    nudgedUser = Accounts.get_user!(peer_id)
    text = "#{user.name} nudged you."
    send_notification(nudgedUser, text) 
    
    Phoenix.PubSub.broadcast(Sunstone.PubSub, "users:#{office_id}", {:nudge, peer_id: peer_id})
    {:noreply, socket}
  end


  def handle_event("active", %{"peer-id" => peer_id}, socket) do
    user = socket.assigns.user
    office_id = socket.assigns.office_id
    
    {:ok, user} = Accounts.update_user_active(user, %{is_active: true, peer_id: peer_id}, office_id)
    tables = Chats.list_tables(office_id)
    office = Chats.get_office!(office_id)

    send_office_notification(office, user)
    {:noreply, assign(socket, user: user,  tables: tables, chat_list: [], office: office)}
  end

  def handle_event("save", %{"social" => social_param}, socket) do
    user = socket.assigns.user
    office_id = socket.assigns.office_id
    Accounts.create_update_social(social_param, user, office_id)
    user = Accounts.get_user!(user.id)
    social = Accounts.get_social!(user.socials.id)
    changeset = Social.changeset(social, %{}, user)
    {:noreply, assign(socket, user: user, changeset: changeset)}
  end



  def handle_event("join", %{"table-id" => table_id}, socket) do
    user = socket.assigns.user
    office_id = socket.assigns.office_id
    Phoenix.PubSub.broadcast(Sunstone.PubSub, "users:#{office_id}", {:join_notification, table_id: table_id})
    {:ok, user} = Accounts.update_user(user, %{table_id: table_id}, office_id)
    tables = Chats.list_tables(office_id)
    table = Chats.get_table!(user.table_id)
    send_table_notification(table, user)
    {:noreply, assign(socket, user: user, tables: tables, chat_list: table.users)}
  end

  def handle_event("leave", value, socket) do
    user = socket.assigns.user
    office_id = socket.assigns.office_id
    Phoenix.PubSub.broadcast(Sunstone.PubSub, "users:#{office_id}", {:leave_notification, table_id: user.table_id})
    {:ok, user} = Accounts.leave_table(user, office_id)
    table = Chats.get_table!(user.table_id)
    tables = Chats.list_tables(office_id)

    if (table.broadcast_id === user.id) do
       Chats.broadcast_reset_table(table, user, office_id)
    end
    
    {:noreply, assign(socket, user: user, tables: tables, chat_list: table.users, connected_list: [])}
  end

  def handle_event("toggle-mute", value, socket) do
    user = socket.assigns.user
    office_id = socket.assigns.office_id
    {:ok, user} = Accounts.update_user(user, %{is_muted: !user.is_muted}, office_id)
    {:noreply, assign(socket, user: user)}
  end
  def handle_event("toggle-locked", value, socket) do
    user = socket.assigns.user
    table = Chats.get_table!(user.table_id)
    office_id = socket.assigns.office_id
    Chats.locked_table(table, %{is_locked: !table.is_locked}, office_id)
    {:noreply, assign(socket, user: user)}
  end

  def handle_event("connected", %{"peer-id" => peer_id}, socket) do
    connected_list = socket.assigns.connected_list ++ [peer_id]
    {:noreply, assign(socket, connected_list: connected_list)}
  end

  def handle_event("disconnected", %{"peer-id" => peer_id}, socket) do
    connected_list = socket.assigns.connected_list -- [peer_id]
    {:noreply, assign(socket, connected_list: connected_list)}
  end


  
  def handle_event("start-sharing-screen", value, socket) do
    user = socket.assigns.user
    office_id = socket.assigns.office_id
    table = Chats.get_table!(user.table_id)
    Chats.broadcast_on_table(table, user, office_id)
    user = Accounts.get_user!(user.id)
    
    {:noreply, assign(socket, user: user)}
  end

  def handle_event("stop-sharing-screen", value, socket) do
    user = socket.assigns.user
    office_id = socket.assigns.office_id
    table = Chats.get_table!(user.table_id)
    Chats.broadcast_reset_table(table, user, office_id)
    user = Accounts.get_user!(user.id)

    {:noreply, assign(socket, user: user)}
  end

  def handle_event("show_sub_btn", _, socket) do

    {:noreply, assign(socket, show_sub_btn: true)}
  end
  def handle_event("hide_sub_btn", _, socket) do
    {:noreply, assign(socket, show_sub_btn: false)}
  end

  

  def handle_info({:table_updated}, socket) do
     user = socket.assigns.user
     user = Accounts.get_user!(user.id)
     office_id = socket.assigns.office_id
     tables = Chats.list_tables(office_id)
     table = Chats.get_table!(user.table_id)

    {:noreply, assign(socket, user: user, broadcast: table.broadcast, tables: tables)}
  end

  def handle_info({:nudge, param}, socket) do
      user = socket.assigns.user
      {id, _}= Integer.parse(param[:peer_id])
      case user.id == id do
        true -> 
        nudge_list = socket.assigns.nudge_list
        nudge_list = nudge_list ++ [1]
        {:noreply, assign(socket, nudge_list: nudge_list)}
        false -> {:noreply, socket}
      end
  end
  def handle_info({:leave_notification, param}, socket) do
      user = socket.assigns.user
      case user.table_id == param[:table_id] do
        true -> 
        leave_notification_list = socket.assigns.leave_notification_list
        leave_notification_list = leave_notification_list ++ [1]
        {:noreply, assign(socket, leave_notification_list: leave_notification_list)}
        false -> {:noreply, socket}
      end
  end
  def handle_info({:join_notification, param}, socket) do
      user = socket.assigns.user
      {id, _}= Integer.parse(param[:table_id])
      case user.table_id == id do
        true -> 
        join_notification_list = socket.assigns.join_notification_list
        join_notification_list = join_notification_list ++ [1]
        {:noreply, assign(socket, join_notification_list: join_notification_list)}
        false -> {:noreply, socket}
      end
  end





  def handle_info({:user_updated}, socket) do
     user = socket.assigns.user
     user = Accounts.get_user!(user.id)
     office_id = socket.assigns.office_id
     tables = Chats.list_tables(office_id)
     table = Chats.get_table!(user.table_id)
     office = Chats.get_office!(office_id)
    {:noreply, assign(socket, user: user, tables: tables, chat_list: table.users, broadcast: table.broadcast, office: office)}
  end

  def handle_info({:user_inactive}, socket) do
     user = socket.assigns.user
     user = Accounts.get_user!(user.id)
     office_id = socket.assigns.office_id
     tables = Chats.list_tables(office_id)
     office = Chats.get_office!(office_id)
     table = Chats.get_table!(user.table_id)

    {:noreply, assign(socket, user: user, tables: tables, office: office)}
  end


  @impl true
  def unmount(_, %{user: user, office_id: office_id}) do
     user = Accounts.get_user!(user.id)
     table = Chats.get_table!(user.table_id)
     Accounts.update_user_inactive(user, office_id)
    if (table.broadcast_id === user.id) do
       Chats.broadcast_reset_table(table, user, office_id)
     end
    :ok
  end
  
end

