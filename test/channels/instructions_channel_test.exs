defmodule BioMonitor.InstructionsChannelTest do
  use BioMonitor.ChannelCase

  alias BioMonitor.InstructionsChannel

  setup do
    {:ok, _, socket} =
      socket("user_id", %{some: :assign})
      |> subscribe_and_join(InstructionsChannel, "instructions:lobby")

    {:ok, socket: socket}
  end
end
