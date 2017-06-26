defmodule BioMonitor.RoutineChannel do
  use Phoenix.Channel

  def join("routine:updates", _message, socket) do
    {:ok, socket}
  end

  def handle_out("reading_update", payload, socket) do
    push socket, "update", payload
    {:noreply, socket}
  end

  def handle_out("alert", payload, socket) do
    push socket, "alert", payload
    {:noreply, socket}
  end

  def handle_out("routine_started", payload, socket) do
    push socket, "new_msg", payload
    {:noreply, socket}
  end

  def handle_out("routine_finished", payload, socket) do
    push socket, "routine_finished", payload
    {:noreply, socket}
  end
end
