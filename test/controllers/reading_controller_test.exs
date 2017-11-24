defmodule BioMonitor.ReadingControllerTest do
  use BioMonitor.ConnCase

  alias BioMonitor.Routine
  alias BioMonitor.Reading
  alias Ecto.DateTime, as: DateTime

  @routine_valid_attrs %{title: Faker.File.file_name(), estimated_time_seconds: "#{Faker.Commerce.price()}", extra_notes: Faker.File.file_name(), medium: Faker.Beer.name(), strain: Faker.Beer.malt(), target_co2: "#{Faker.Commerce.price()}", target_density: "#{Faker.Commerce.price()}", target_ph: "#{Faker.Commerce.price()}", target_temp: "#{Faker.Commerce.price()}"}
  @valid_attrs %{observancy: "120.5", biomass: "120.5", substratum: "20.20", ph: "120.5", temp: "120.5"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    routine = Routine.changeset(%Routine{}, @routine_valid_attrs)
    |> Repo.insert!()
    conn = get conn, routine_reading_path(conn, :index, routine.id)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    routine = Routine.changeset(%Routine{}, @routine_valid_attrs)
      |> Repo.insert!()
    reading = Ecto.build_assoc(routine, :readings, %{})
      |> Reading.changeset(@valid_attrs)
      |> Repo.insert!()
    conn = get conn, routine_reading_path(conn, :show, routine.id, reading)
    assert json_response(conn, 200)["data"] == %{"id" => reading.id,
      "temp" => reading.temp,
      "ph" => reading.ph,
      "substratum" => reading.substratum,
      "observancy" => reading.observancy,
      "biomass" => reading.biomass,
      "inserted_at" => to_date_string(reading.inserted_at),
      "routine_id" => reading.routine_id}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, routine_reading_path(conn, :show, 1, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    routine = Routine.changeset(%Routine{}, @routine_valid_attrs)
      |> Repo.insert!()
    conn = post conn, routine_reading_path(conn, :create, routine.id), reading: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Reading, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    routine = Routine.changeset(%Routine{}, @routine_valid_attrs)
      |> Repo.insert!()
    conn = post conn, routine_reading_path(conn, :create, routine.id), reading: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    routine = Routine.changeset(%Routine{}, @routine_valid_attrs)
      |> Repo.insert!()
    reading = Ecto.build_assoc(routine, :readings, %{})
      |> Reading.changeset(@valid_attrs)
      |> Repo.insert!()
    conn = delete conn, routine_reading_path(conn, :delete, routine.id, reading)
    assert response(conn, 204)
    refute Repo.get(Reading, reading.id)
  end

  defp to_date_string(date) do
    {:ok, date_time} = date |> DateTime.cast
    date_time |> DateTime.to_iso8601
  end
end
