defmodule BioMonitor.SyncChannel do
  @moduledoc """
    Channel that handles the sync between the local monitor
    and the cloud backend.
  """
  use PhoenixChannelClient

  @started_msg "start"
  @stopped_msg "stop"
  @update_msg "update"

  def handle_in(@started_msg, _payload, state) do
    IO.puts("Started routine")
    {:noreply, state}
  end

  def handle_in(@stopped_msg, _payload, state) do
    IO.puts("Stopped routine")
    {:noreply, state}
  end

  def handle_in(@update_msg, %{"id"=> routine_id}, state) do
    IO.puts("New update for routine id #{routine_id}")
    {:noreply, state}
  end

  def handle_reply({:ok, :join, _payload, _ref}, state) do
    IO.puts("Successfuly joined channel")
    {:noreply, state}
  end

  def handle_reply({:error, message, _payload, _ref}, state) do
    IO.puts("Unexpected error on reply #{message}")
    {:noreply, state}
  end

  def handle_reply({:timeout, :join, _ref}, state) do
    IO.puts("Join Timed out.")
    {:noreply, state}
  end

  def handle_reply({:timeout, message, _ref}, state) do
    IO.puts("Message #{message} Timed out.")
    {:noreply, state}
  end

  def handle_close(_reason, state) do
    IO.puts("Channel closed")
    {:noreply, state}
  end
end
