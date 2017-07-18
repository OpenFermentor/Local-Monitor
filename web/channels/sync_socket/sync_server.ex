defmodule BioMonitor.SyncServer do
  @moduledoc """
    Wrapper around socket communication with the cloud backend.
  """
  use GenServer

  alias BioMonitor.SyncSocket
  alias BioMonitor.SyncChannel

  @topic "sync"
  @error_message "Could not connect to sync socket."
  @name SyncServer

  # User API
  def start_link do
    start_server()
  end

  def start_server do
    GenServer.start_link(__MODULE__, :ok, [name: @name])
  end

  def send(message, payload) do
    GenServer.call(@name, {:send, message, payload})
  end

  # GenServer Callbacks
  def init(:ok) do
    case join_channel() do
      {:ok, socket, channel} ->
        {:ok, %{socket: socket, channel: channel}}
      {:error, message} ->
        IO.puts("Failed to start socket connection: #{message}")
        {:error, message}
    end
  end

  def handle_call({:send, message, payload}, _from, state) do
    SyncChannel.push(message, payload)
    {:reply, :ok, state}
  end

  # Helpers
  defp join_channel do
    with {:ok, socket} <- SyncSocket.start_link(),
      {:ok, channel} <- PhoenixChannelClient.channel(
        SyncChannel,
        socket: SyncSocket,
        topic: @topic
      ),
      _push <- SyncChannel.join()
    do
      {:ok, socket, channel}
    else
      _ ->
        IO.puts(@error_message)
        {:error, @error_message}
    end
  end
end
