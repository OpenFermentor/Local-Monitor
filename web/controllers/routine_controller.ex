defmodule BioMonitor.RoutineController do
  use BioMonitor.Web, :controller

  alias BioMonitor.Routine
  alias BioMonitor.CloudSync

  @routines_per_page "100"

  def index(conn, params) do
    {routines, rummage} =
      Routine |>
      Rummage.Ecto.rummage(%{
        "paginate" => %{
          "per_page" => @routines_per_page,
          "page" => "#{params["page"] || 1}"
        },
        "search" => %{
          "title" => %{"assoc" => [], "search_type" => "ilike", "search_term" => params["title"]},
          "strain" => %{"assoc" => [], "search_type" => "ilike", "search_term" => params["strain"]},
          "medium" => %{"assoc" => [], "search_type" => "ilike", "search_term" => params["medium"]},
          "value" => %{"assoc" => ["tags"], "search_type" => "ilike", "search_term" => params["tag"]}
        }
      })
    routines = Repo.all(routines) |> Repo.preload([:temp_ranges, :tags])
    render(conn, "index.json", routine: routines, page_info: rummage)
  end

  def create(conn, %{"routine" => routine_params}) do
    changeset = Routine.changeset(%Routine{}, routine_params)
    case Repo.insert(changeset) do
      {:ok, routine} ->
        routine = routine |> Repo.preload([:temp_ranges, :tags])
        CloudSync.new_routine(%{"routine" => Map.put(routine_params, :uuid, routine.uuid)})
        conn
        |> put_status(:created)
        |> put_resp_header("location", routine_path(conn, :show, routine))
        |> render("show.json", routine: routine)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(BioMonitor.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    routine = Repo.get!(Routine, id) |> Repo.preload([:temp_ranges, :tags])
    render(conn, "show.json", routine: routine)
  end

  def update(conn, %{"id" => id, "routine" => routine_params}) do
    routine = Repo.get!(Routine, id) |> Repo.preload([:temp_ranges, :tags])
    changeset = Routine.changeset(routine, routine_params)
    case Repo.update(changeset) do
      {:ok, routine} ->
        CloudSync.update_routine(%{"routine" => routine_params}, routine.uuid)
        render(conn, "show.json", routine: routine)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(BioMonitor.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    routine = Repo.get!(Routine, id)
    Repo.delete!(routine)
    CloudSync.delete_routine(routine.uuid)
    send_resp(conn, :no_content, "")
  end

  def stop(conn, _params) do
    if BioMonitor.RoutineMonitor.is_running?() do
      {:ok, routine} = BioMonitor.RoutineMonitor.stop_routine()
      routine_updated = Repo.get!(Routine, routine.id) |> Repo.preload([:temp_ranges, :tags, :log_entries])
      routine_updated
        |> CloudSync.routine_to_map
        |> CloudSync.update_routine(routine.uuid)
    end
    send_resp(conn, :no_content, "")
  end

  def start(conn, %{"id" => id}) do
    routine = Repo.get!(Routine, id) |> Repo.preload([:temp_ranges, :tags])
    with running = BioMonitor.RoutineMonitor.is_running?(),
      {:ok, false} <- running,
      :ready <- already_run(routine),
      :ok <- BioMonitor.RoutineMonitor.start_routine(routine)
    do
      render(conn, "show.json", routine: routine)
    else
      {:error, _, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(BioMonitor.ErrorView, "error.json", message: message)
      {:ok, true} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(BioMonitor.RoutineView, "unavailable.json")
      :already_run ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(BioMonitor.RoutineView, "already_run.json")
      _ ->
        conn
        |> put_status(500)
        |> render(BioMonitor.RoutineView, "500.json")
    end
  end

  def to_csv(conn, %{"routine_id" => id}) do
    routine =
      Routine
      |> Repo.get!(id)
      |> Repo.preload(:readings)

    path = "#{routine.title}_readings.csv"
    file = File.open!(Path.expand(path), [:write, :utf8])

    routine.readings
      |> CSV.encode(headers: [:temp, :ph, :inserted_at])
      |> Enum.each(&IO.write(file, &1))

    conn = conn
      |> put_resp_header("Content-Disposition", "attachment; filename=#{path}")
      |> send_file(200, path)

    File.close(file)
    File.rm(path)
    conn
  end

  def restart(conn, _params) do
    BioMonitor.RoutineMonitor.start_loop()
    send_resp(conn, :no_content, "")
  end

  def current(conn, _params) do
    case BioMonitor.RoutineMonitor.current_routine() do
      :not_running ->
        send_resp(conn, :no_content, "")
      {:ok, routine} ->
        conn
        |> render("show.json", routine: routine)
    end
  end

  defp already_run(routine) do
    case routine.started do
      true -> :already_run
      false -> :ready
    end
  end
end
