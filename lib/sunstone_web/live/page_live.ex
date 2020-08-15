defmodule SunstoneWeb.PageLive do
  use SunstoneWeb, :live_view
  alias Sunstone.Accounts.Guardian
  alias Sunstone.Chats
  alias Sunstone.Accounts
  @impl true
  def mount(_params, %{"guardian_default_token" => token}, socket) do
    {_, user, _} = Guardian.resource_from_token(token)
    if connected?(socket) do
      Accounts.subscribe()
      SunstoneWeb.Live.LiveMonitor.monitor(self(), __MODULE__, %{user: user})
    end 
    tables = Chats.list_tables
    table = Chats.get_table!(user.table_id)
    {:ok, assign(socket, user: user, tables: tables, chat_list: [])}
  end

  def handle_event("active", %{"peer-id" => peer_id}, socket) do
    user = socket.assigns.user
    {:ok, user} = Accounts.update_user_active(user, %{is_active: true, peer_id: peer_id})
    tables = Chats.list_tables
    table = Chats.get_table!(user.table_id)
    {:noreply, assign(socket, user: user,  tables: tables, chat_list: [])}
  end

  def handle_event("join", %{"table-id" => table_id}, socket) do
    user = socket.assigns.user
    {:ok, user} = Accounts.update_user(user, %{table_id: table_id})
    tables = Chats.list_tables
    table = Chats.get_table!(user.table_id)
    {:noreply, assign(socket, user: user, tables: tables, chat_list: table.users)}
  end

  def handle_event("leave", value, socket) do
    user = socket.assigns.user
    {:ok, user} = Accounts.leave_table(user)
    table = Chats.get_table!(user.table_id)
    tables = Chats.list_tables

    
    {:noreply, assign(socket, user: user, tables: tables, chat_list: table.users)}
  end

  def handle_info({:user_updated}, socket) do
     user = socket.assigns.user
     tables = Chats.list_tables
    {:noreply, assign(socket, user: user, tables: tables)}
  end

    def handle_info({:user_inactive}, socket) do
     user = socket.assigns.user
     tables = Chats.list_tables
    {:noreply, assign(socket, user: user, tables: tables)}
  end
  @impl true
  def unmount(_, %{user: user}) do
     user = Accounts.get_user!(user.id)
     Accounts.update_user_inactive(user)
    :ok
  end
  
end

