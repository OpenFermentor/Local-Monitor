defmodule BioMonitor.PhController do
  use BioMonitor.Web, :controller

  alias BioMonitor.SensorManager
  alias BioMonitor.RoutineMonitor
  alias BioMonitor.ErrorView

  def current(conn, _params) do
    case SensorManager.get_ph() do
      {:ok, ph_value} ->
        conn
        |> render("show.json", current_value: ph_value)
      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, "error.json", %{message: message})
    end
  end

  def calibration_status(conn, _params) do
    status = RoutineMonitor.ph_cal_status()
    conn
    |> render("status.json", status)
  end

  def set_base(conn, _params) do
    conn |> start_calibration(10)
  end

  def set_acid(conn, _params) do
    conn |> start_calibration(4)
  end

  def set_neutral(conn, _params) do
    conn |> start_calibration(7)
  end

  defp start_calibration(conn, target) do
    case RoutineMonitor.start_ph_cal(target) do
      :ok ->
        conn |> render("cal_started.json")
      :routine_in_progress ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(
          ErrorView,
          "error.json",
          %{message: "No se puede calibrar el sensor mientras este corriendo un experimento"}
        )
    end
  end
end
