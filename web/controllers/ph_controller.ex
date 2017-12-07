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
    case RoutineMonitor.ph_cal_status() do
      %{target: _target, status: {:error, message}} ->
        conn
        |> put_status(:internal_server_error)
        |> render(ErrorView, "error.json", %{message: message})
      status = %{target: _target, status: _status} ->
        conn
        |> render("status.json", status)
    end
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

  def test_acid_drop(conn, _params) do
    case SensorManager.pump_acid() do
      :ok -> send_resp(conn, :no_content, "")
      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, "error.json", %{message: message})
    end
  end

  def test_base_drop(conn, _params) do
    case SensorManager.pump_base() do
      :ok -> send_resp(conn, :no_content, "")
      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, "error.json", %{message: message})
    end
  end

  def push_acid(conn, _params) do
    case SensorManager.push_acid() do
      :ok -> send_resp(conn, :no_content, "")
      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, "error.json", %{message: message})
    end
  end

  def push_base(conn, _params) do
    case SensorManager.push_base() do
      :ok -> send_resp(conn, :no_content, "")
      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, "error.json", %{message: message})
    end
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
