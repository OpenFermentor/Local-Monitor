defmodule BioMonitor.ReadingController do
  use BioMonitor.Web, :controller

  import Ecto.Query
  alias BioMonitor.Reading
  alias BioMonitor.Routine
  @readings_per_page "30"

  def index(conn, %{"routine_id" => routine_id} = params) do
    with routine = Repo.get(Routine, routine_id),
      true <- routine != nil
    do
      query = from r in Reading,
        where: r.routine_id == ^routine_id
      {readings, rummage} =
        query |>
        Rummage.Ecto.rummage(%{
          "paginate" => %{
            "per_page" => @readings_per_page,
            "page" => "#{params["page"] || 1}"
          }
        })
      readings = Repo.all(readings)
      render(conn, "index.json", readings: readings, page_info: rummage)
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
      reading <- Ecto.build_assoc(routine, :readings),
      changeset <- Reading.changeset(reading, reading_params),
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

  def show(conn, %{"routine_id" => routine_id, "id" => id}) do
    reading = Repo.get!(Reading, id)
    render(conn, "show.json", routine_id: routine_id, reading: reading)
  end

  def delete(conn, %{"id" => id}) do
    reading = Repo.get!(Reading, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(reading)

    send_resp(conn, :no_content, "")
  end
end
