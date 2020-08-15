defmodule Sunstone.Store do
  use Agent

  def start_link(initial_value) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def state do
    Agent.get(__MODULE__, & &1)
  end

  def update_user_location(user) do
    Agent.update(__MODULE__, fn(state) -> state ++ [user] end)
     
  end
end
