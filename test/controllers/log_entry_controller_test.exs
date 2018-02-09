defmodule BioMonitor.LogEntryControllerTest do
  use BioMonitor.ConnCase

  alias BioMonitor.LogEntry
  alias BioMonitor.Routine
  alias Ecto.DateTime, as: DateTime

  @routine_valid_attrs %{title: Faker.File.file_name(), estimated_time_seconds: "#{Faker.Commerce.price()}", extra_notes: Faker.File.file_name(), medium: Faker.Beer.name(), strain: Faker.Beer.malt(), target_co2: "#{Faker.Commerce.price()}", target_density: "#{Faker.Commerce.price()}", target_ph: "#{Faker.Commerce.price()}", target_temp: "#{Faker.Commerce.price()}"}
  @valid_attrs %{description: "some content", type: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    routine = Routine.changeset(%Routine{}, @routine_valid_attrs)
    |> Repo.insert!()
    conn = get conn, routine_log_entry_path(conn, :index, routine.id)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    routine = Routine.changeset(%Routine{}, @routine_valid_attrs)
      |> Repo.insert!()
    log_entry = Ecto.build_assoc(routine, :log_entries, @valid_attrs)
      |> Repo.insert!()
    conn = get conn, routine_log_entry_path(conn, :index, routine.id)
    assert json_response(conn, 200)["data"] == [%{
      "id" => log_entry.id,
      "type" => log_entry.type,
      "description" => log_entry.description,
      "inserted_at" => log_entry.inserted_at |> to_date_string()
    }]
  end

  defp to_date_string(date) do
    {:ok, date_time} = date |> DateTime.cast
    date_time |> DateTime.to_iso8601
  end
end
