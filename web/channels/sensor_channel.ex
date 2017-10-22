defmodule BioMonitor.SensorChannel do
  @moduledoc """
    Channel used to broadcast all updates for the rutine events.
     * Routines starting.
     * New readings.
     * Alerts.
     * Routines finishing.
  """
  use Phoenix.Channel
  intercept(["status", "error"])

  def join("sensors", _payload, socket) do
    {:ok, socket}
  end

  def handle_out("status", payload, socket) do
    push socket, "status", payload
    {:noreply, socket}
  end

  def handle_out("error", payload, socket) do
    push socket, "error", payload
    {:noreply, socket}
  end
end
