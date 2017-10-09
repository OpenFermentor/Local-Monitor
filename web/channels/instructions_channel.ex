defmodule BioMonitor.InstructionsChannel do
  use BioMonitor.Web, :channel
  intercept(["instruction"])

  def join("instructions", _payload, socket) do
    {:ok, socket}
  end

  def handle_out("instruction", payload, socket) do
    push socket, "instruction", payload
    {:noreply, socket}
  end
end
