defmodule BioMonitor.PhView do
  use BioMonitor.Web, :view

  def render("show.json", %{current_value: value}) do
    render_current_value(value)
  end

  defp render_current_value(value) do
    %{current_value: value}
  end
end
