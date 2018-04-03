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

  def calculations_to_csv(conn, %{"routine_id" => id}) do
    with routine = Repo.get(Routine, id),
      true <- routine != nil
    do
      case routine.started_date do
        nil ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(BioMonitor.ErrorView, "error.json", message: "Este experimento no fue ejecutado todavia.")
        started_date ->
          readings = Repo.preload(routine, :readings).readings
          calculations = RoutineCalculations.build_csv_calculations(readings, started_date)
          path = "#{routine.title}_calculations.csv"
          file = File.open!(Path.expand(path), [:write, :utf8])
          calculations
            |> CSV.encode(headers: [:time_in_seconds, :biomass_performance, :product_performance, :product_biomass_performance, :product_volumetric_performance, :biomass_volumetric_performance, :specific_ph_velocity, :specific_biomass_velocity, :specific_product_velocity])
            |> Enum.each(&IO.write(file, &1))

          conn = conn
            |> put_resp_header("Content-Disposition", "attachment; filename=#{path}")
            |> send_file(200, path)

          File.close(file)
          File.rm(path)
          conn
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
        BioMonitor.RoutineMessageBroker.send_reading(reading, routine)
        conn
          |> put_status(:created)
          |> render("created_reading.json", reading: reading)
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
