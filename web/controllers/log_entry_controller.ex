defmodule BioMonitor.LogEntryController do
  use BioMonitor.Web, :controller

  def index(conn, %{"routine_id" => routine_id}) do
    with routine = Repo.get(BioMonitor.Routine, routine_id),
      true <- routine != nil
    do
      routine = Repo.preload(routine, :log_entries)
      render(conn, "index.json", log_entries: routine.log_entries)
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
end
