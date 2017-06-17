defmodule BioMonitor.RoutineController do
  use BioMonitor.Web, :controller

  alias BioMonitor.Routine

  def index(conn, _params) do
    title = Repo.all(Routine)
    render(conn, "index.json", title: title)
  end

  def create(conn, %{"routine" => routine_params}) do
    changeset = Routine.changeset(%Routine{}, routine_params)

    case Repo.insert(changeset) do
      {:ok, routine} ->
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
end
