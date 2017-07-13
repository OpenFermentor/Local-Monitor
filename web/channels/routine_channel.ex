defmodule BioMonitor.RoutineChannel do
  @moduledoc """
    Channel used to broadcast all updates for the sensors status.
     * Sensor status updates.
     * Errors.
  """
  use Phoenix.Channel
  intercept(["update", "alert", "started", "finished"])

  def join("routine", _payload, socket) do
    {:ok, socket}
  end

  def handle_out("update", payload, socket) do
    push socket, "update", payload
    {:noreply, socket}
  end

  def handle_out("alert", payload, socket) do
    push socket, "alert", payload
    {:noreply, socket}
  end

  def handle_out("started", payload, socket) do
    push socket, "started", payload
    {:noreply, socket}
  end

  def handle_out("finished", payload, socket) do
    push socket, "routine_finished", payload
    {:noreply, socket}
  end
end
