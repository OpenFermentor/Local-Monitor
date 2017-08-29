defmodule BioMonitor.RoutineControllerTest do
  use BioMonitor.ConnCase

  @moduledoc """
    Test cases for RoutineController
  """

  alias BioMonitor.Routine
  alias Ecto.DateTime, as: DateTime
  @valid_attrs %{title: Faker.File.file_name(), estimated_time_seconds: "#{Faker.Commerce.price()}", extra_notes: Faker.File.file_name(), medium: Faker.Beer.name(), strain: Faker.Beer.malt(), target_co2: "#{Faker.Commerce.price()}", target_density: "#{Faker.Commerce.price()}", target_ph: "#{Faker.Commerce.price()}", target_temp: "#{Faker.Commerce.price()}"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, routine_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    routine = Repo.insert! Routine.changeset(%Routine{}, @valid_attrs)
    conn = get conn, routine_path(conn, :show, routine)
    assert json_response(conn, 200)["data"] == %{
      "id" => routine.id,
      "uuid" => routine.uuid,
      "title" => routine.title,
      "strain" => routine.strain,
      "medium" => routine.medium,
      "target_temp" => routine.target_temp,
      "target_ph" => routine.target_ph,
      "target_co2" => routine.target_co2,
      "target_density" => routine.target_density,
      "estimated_time_seconds" => routine.estimated_time_seconds,
      "extra_notes" => routine.extra_notes,
      "inserted_at" => to_date_string(routine.inserted_at),
      "updated_at" => to_date_string(routine.updated_at),
    }
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, routine_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, routine_path(conn, :create), routine: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Routine, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, routine_path(conn, :create), routine: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    routine = Repo.insert! %Routine{}
    conn = put conn, routine_path(conn, :update, routine), routine: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Routine, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    routine = Repo.insert! %Routine{}
    conn = put conn, routine_path(conn, :update, routine), routine: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    routine = Repo.insert! %Routine{}
    conn = delete conn, routine_path(conn, :delete, routine)
    assert response(conn, 204)
    refute Repo.get(Routine, routine.id)
  end

  defp to_date_string(date) do
    {:ok, date_time} = date |> DateTime.cast
    date_time |> DateTime.to_iso8601
  end
end
