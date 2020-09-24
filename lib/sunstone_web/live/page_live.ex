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
      {:ok, assign(socket, user: user, tables: tables, chat_list: [], office_id: office_id, office: office, changeset: changeset, broadcast: nil)}
    else
      {:ok, redirect(socket, to: Routes.office_path(socket, :uninvited, hash_id))}
    end



  end

  def send_office_notification(office, user) do
    colleagues = office.users
    Enum.each(colleagues, fn colleague -> 
      colleague = Accounts.get_user!(colleague.id)
      if(colleague.id != user.id && colleague.notifications != nil ) do
        send_notification(colleague, "#{user.name} has entered #{office.name}")
      end
    end)
  end
  def send_notification(user, text) do
    body = ~s({"body": "#{text}"})
    subscription = %{keys: %{p256dh: user.notifications.p256dh, auth: user.notifications.auth }, endpoint: user.notifications.endpoint}
    gcm_api_key = "BGQpjZfJ_qNF5I6n-jfeyCDM48sAYqyqRw1smJLVwMrHT4ifYVX77fjchc5Bb8wnj-IyxW3bQz3eu_hMDUpgFTQ"

    # or just send the push
    WebPushEncryption.send_web_push(body, subscription, gcm_api_key)
    
  end

  def handle_event("subscribe-notification", param, socket) do
    user = socket.assigns.user
    Accounts.create_update_notifications(param,user)
    {:noreply, assign(socket, nothing: [])}
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
    {:ok, user} = Accounts.update_user(user, %{table_id: table_id}, office_id)
    tables = Chats.list_tables(office_id)
    table = Chats.get_table!(user.table_id)
    {:noreply, assign(socket, user: user, tables: tables, chat_list: table.users)}
  end

  def handle_event("leave", value, socket) do
    user = socket.assigns.user
    office_id = socket.assigns.office_id
    {:ok, user} = Accounts.leave_table(user, office_id)
    table = Chats.get_table!(user.table_id)
    tables = Chats.list_tables(office_id)

    if (table.broadcast_id === user.id) do
       Chats.broadcast_reset_table(table, user, office_id)
     end
    {:noreply, assign(socket, user: user, tables: tables, chat_list: table.users)}
  end
  
  def handle_event("start-sharing-screen", value, socket) do
    user = socket.assigns.user
    office_id = socket.assigns.office_id
    table = Chats.get_table!(user.table_id)
    Chats.broadcast_on_table(table, user, office_id)

    
    {:noreply, assign(socket, user: user)}
  end

  def handle_event("stop-sharing-screen", value, socket) do
    user = socket.assigns.user
    office_id = socket.assigns.office_id
    table = Chats.get_table!(user.table_id)
    Chats.broadcast_reset_table(table, user, office_id)
    
    {:noreply, assign(socket, user: user)}
  end

  

  def handle_info({:table_updated}, socket) do
     user = socket.assigns.user
     office_id = socket.assigns.office_id
     tables = Chats.list_tables(office_id)
     table = Chats.get_table!(user.table_id)
    {:noreply, assign(socket, broadcast: table.broadcast, tables: tables)}
  end




  def handle_info({:user_updated}, socket) do
     user = socket.assigns.user
     office_id = socket.assigns.office_id
     tables = Chats.list_tables(office_id)
     table = Chats.get_table!(user.table_id)
     
    {:noreply, assign(socket, user: user, tables: tables, chat_list: table.users, broadcast: table.broadcast)}
  end

  def handle_info({:user_inactive}, socket) do
     user = socket.assigns.user
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

