defmodule BioMonitor.ReadingController do
  use BioMonitor.Web, :controller

  alias BioMonitor.Reading
  alias BioMonitor.Routine
  alias BioMonitor.SensorManager
  alias BioMonitor.RoutineCalculations

  def index(conn, %{"routine_id" => routine_id}) do
    with routine = Repo.get(Routine, routine_id),
      true <- routine != nil
    do
      routine = Repo.preload(routine, :readings)
      render(conn, "index.json", readings: routine.readings)
    else
      false ->
        conn
        |> put_status(:not_found)
        |> render(BioMonitor.ErrorView, "404.json")
      _ ->
        conn
        |> put_status(500)
        |> render(BioMonitor.ErrorView, "500.json")
    end
  end

  def calculations(conn, %{"routine_id" => routine_id}) do
    with routine = Repo.get(Routine, routine_id),
      true <- routine != nil
    do
      case routine.started_date do
        nil ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(BioMonitor.ErrorView, "error.json", message: "Este experimento no fue ejecutado todavia.")
        started_date ->
          readings = Repo.preload(routine, :readings).readings
          calculations = RoutineCalculations.build_calculations(readings, started_date)
          render(conn, "calculations.json", values: calculations)
      end
    else
      false ->
        conn
        |> put_status(:not_found)
        |> render(BioMonitor.ErrorView, "404.json")
      _ ->
        conn
        |> put_status(500)
        |> render(BioMonitor.ErrorView, "500.json")
    end
  end

  def create(conn, %{"routine_id" => routine_id, "reading" => reading_params}) do
    with routine = Repo.get(Routine, routine_id),
      true <- routine != nil,
      {:ok, reading_data} <- SensorManager.get_readings()
    do
      with reading_data_string_keys = reading_data |> Enum.reduce(%{}, fn {k, v}, map -> Map.put(map, Atom.to_string(k), v) end),
        all_reading_params = Map.merge(reading_data_string_keys, reading_params),
        reading <- Ecto.build_assoc(routine, :readings),
        changeset <- Reading.changeset(reading, all_reading_params),
        {:ok, reading} <- Repo.insert(changeset)
      do
        conn
          |> put_status(:created)
          |> put_resp_header("location", routine_reading_path(conn, :show, reading.routine_id, reading))
          |> render("show.json", reading: reading)
      else
        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(BioMonitor.ChangesetView, "error.json", changeset: changeset)
        _ ->
          conn
          |> put_status(500)
          |> render(BioMonitor.ErrorView, "500.json")
      end
    else
      false ->
        conn
        |> put_status(:not_found)
        |> render(BioMonitor.ErrorView, "404.json")
      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(BioMonitor.ErrorView, "error.json", message: message)
    end
  end

  def delete(conn, %{"id" => id}) do
    reading = Repo.get!(Reading, id)
    Repo.delete!(reading)
    send_resp(conn, :no_content, "")
  end
end
