defmodule SunstoneWeb.PageLive do
  use SunstoneWeb, :live_view
  alias Sunstone.Accounts.Guardian
  alias Sunstone.Chats
  alias Sunstone.Accounts
  @impl true
  def mount(%{"hash_id" => hash_id}, %{"guardian_default_token" => token}, socket) do
    {_, user, _} = Guardian.resource_from_token(token)
    office_id = SunstoneWeb.UserController.decode_id(hash_id)
    if connected?(socket) do
      Accounts.subscribe(office_id)
      SunstoneWeb.Live.LiveMonitor.monitor(self(), __MODULE__, %{user: user, office_id: office_id})
    end 
    tables = Chats.list_tables(office_id)
    office = Chats.get_office!(office_id)
    {:ok, assign(socket, user: user, tables: tables, chat_list: [], office_id: office_id, office: office)}
  end

  def handle_event("active", %{"peer-id" => peer_id}, socket) do
    user = socket.assigns.user
    office_id = socket.assigns.office_id
    {:ok, user} = Accounts.update_user_active(user, %{is_active: true, peer_id: peer_id}, office_id)
    tables = Chats.list_tables(office_id)
    {:noreply, assign(socket, user: user,  tables: tables, chat_list: [])}
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

    
    {:noreply, assign(socket, user: user, tables: tables, chat_list: table.users)}
  end

  def handle_info({:user_updated}, socket) do
     user = socket.assigns.user
     office_id = socket.assigns.office_id
     tables = Chats.list_tables(office_id)
    {:noreply, assign(socket, user: user, tables: tables)}
  end

    def handle_info({:user_inactive}, socket) do
     user = socket.assigns.user
     office_id = socket.assigns.office_id
     tables = Chats.list_tables(office_id)
    {:noreply, assign(socket, user: user, tables: tables)}
  end
  @impl true
  def unmount(_, %{user: user, office_id: office_id}) do
     user = Accounts.get_user!(user.id)
     Accounts.update_user_inactive(user, office_id)
    :ok
  end
  
end

