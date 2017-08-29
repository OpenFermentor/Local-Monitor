defmodule BioMonitor.PhController do
  use BioMonitor.Web, :controller

  alias BioMonitor.SensorManager
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

  def set_offset(conn, %{"offset" => offset}) do
    with :ok <- SensorManager.set_ph_offset(offset),
      {:ok, ph_value} <- SensorManager.get_ph()
    do
      conn
      |> render("show.json", current_value: ph_value)
    else
      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, "error.json", %{message: message})
      _ ->
        conn
        |> put_status(500)
        |> render(ErrorView, "500.json")
    end
  end
end
