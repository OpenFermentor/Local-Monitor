defmodule BioMonitor.RoutineController do
  use BioMonitor.Web, :controller

  alias BioMonitor.Routine

  def index(conn, _params) do
    routine = Repo.all(Routine)
    render(conn, "index.json", routine: routine)
  end

  def create(conn, %{"routine" => routine_params}) do
    changeset = Routine.changeset(%Routine{}, routine_params)
    with {:ok, false} <- BioMonitor.RoutineMonitor.is_running?() do
      case Repo.insert(changeset) do
      {:ok, routine} ->
        BioMonitor.RoutineMonitor.start_routine(routine)
        conn
        |> put_status(:created)
        |> put_resp_header("location", routine_path(conn, :show, routine))
        |> render("show.json", routine: routine)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(BioMonitor.ChangesetView, "error.json", changeset: changeset)
      end
    else
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(BioMonitor.RoutineView, "unavailable.json")
    end
  end

  def show(conn, %{"id" => id}) do
    routine = Repo.get!(Routine, id)
    render(conn, "show.json", routine: routine)
  end

  def update(conn, %{"id" => id, "routine" => routine_params}) do
    routine = Repo.get!(Routine, id)
    changeset = Routine.changeset(routine, routine_params)

    case Repo.update(changeset) do
      {:ok, routine} ->
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
    send_resp(conn, :no_content, "")
  end

  def stop(conn, _params) do
    BioMonitor.RoutineMonitor.stop_routine()
    send_resp(conn, :no_content, "")
  end

  def start(conn, %{"id" => id}) do
    routine = Repo.get!(Routine, id)
    case BioMonitor.RoutineMonitor.is_running?() do
      {:ok, false} ->
        BioMonitor.RoutineMonitor.start_routine(routine)
        render(conn, "show.json", routine: routine)
      {:ok, true} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(BioMonitor.RoutineView, "unavailable.json")
    end
  end
end
