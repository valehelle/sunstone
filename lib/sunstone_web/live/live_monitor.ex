defmodule SunstoneWeb.Live.LiveMonitor do
  use GenServer

  def monitor(pid, view_module, meta) do
    
    genpid = GenServer.whereis({:global, __MODULE__})
    GenServer.call(genpid, {:monitor, pid, view_module, meta})
  end

  def init(_) do
    {:ok, %{views: %{}}}
  end

  def handle_call({:monitor, pid, view_module, meta}, _, %{views: views} = state) do
    Process.monitor(pid)
    {:reply, :ok, %{state | views: Map.put(views, pid, {view_module, meta})}}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    {{module, meta}, new_views} = Map.pop(state.views, pid)
    module.unmount(reason,meta)
    {:noreply, %{state | views: new_views}}
  end

  def start_link(default) when is_list(default)  do
    GenServer.start_link(__MODULE__, default, name: {:global, __MODULE__})
  end

  
end