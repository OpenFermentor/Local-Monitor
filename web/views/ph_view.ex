defmodule BioMonitor.PhView do
  use BioMonitor.Web, :view

  def render("show.json", %{current_value: value}) do
    render_current_value(value)
  end

  def render("status.json", %{target: target, status: status}) do
    %{
      calibration_target: target,
      calibration_status: status
    }
  end

  def render("cal_started.json", _params) do
    %{message: "Comenzó la calibración, no quite el sensor de la solución"}
  end

  defp render_current_value(value) do
    %{current_value: value}
  end
end
