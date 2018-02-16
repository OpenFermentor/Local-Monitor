defmodule BioMonitor.StateContainer do
  @moduledoc """
    Simple module that stores the state of the routine monitor process isolatedly.
  """

  defmodule InternalState do
    defstruct retry_count: 0, state: nil
  end

  @name StateContainer

  # Starts the state with a empty set.
  def start_link() do
    Agent.start_link(fn -> %InternalState{} end, name: @name)
  end

  def update_state(new_state) do
    IO.puts "============ NEW STATE ================"
    IO.inspect new_state
    Agent.update(@name, fn state -> %{state | state: new_state} end)
  end

  def update_retry_count(new_count) do
    IO.puts "============ Retry Count ================"
    IO.inspect new_count
    Agent.update(@name, fn state -> %{state | retry_count: new_count} end)
  end

  def reset() do
    Agent.update(@name, fn state -> %InternalState{} end)
  end

  def state() do
    Agent.get(@name, fn state -> state.state end)
  end

  def retry_count() do
    Agent.get(@name, fn state -> state.retry_count end)
  end
end
