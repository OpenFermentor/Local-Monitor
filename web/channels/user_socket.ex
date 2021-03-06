defmodule BioMonitor.UserSocket do
  use Phoenix.Socket

  channel "routine", BioMonitor.RoutineChannel
  channel "sensors", BioMonitor.SensorChannel
  channel "instructions", BioMonitor.InstructionsChannel

  transport :websocket, Phoenix.Transports.WebSocket

  def connect(_params, socket) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
