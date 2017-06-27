defmodule BioMonitor.RoutineChannel do
  use Phoenix.Channel
  intercept(["routine:update", "alert", "routine:started", "routine:finished"])

  def join("routine:updates", _message, socket) do
    {:ok, socket}
  end

  def handle_out("routine:update", payload, socket) do
    push socket, "update", payload
    {:noreply, socket}
  end

  def handle_out("alert", payload, socket) do
    push socket, "alert", payload
    {:noreply, socket}
  end

  def handle_out("routine:started", payload, socket) do
    push socket, "new_msg", payload
    {:noreply, socket}
  end

  def handle_out("routine:finished", payload, socket) do
    push socket, "routine_finished", payload
    {:noreply, socket}
  end
end
