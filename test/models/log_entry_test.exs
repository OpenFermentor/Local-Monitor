defmodule BioMonitor.LogEntryTest do
  use BioMonitor.ModelCase

  alias BioMonitor.LogEntry
  alias BioMonitor.Routine

  @routine_valid_attrs %{title: Faker.File.file_name(), estimated_time_seconds: "#{Faker.Commerce.price()}", extra_notes: Faker.File.file_name(), medium: Faker.Beer.name(), strain: Faker.Beer.malt(), target_co2: "#{Faker.Commerce.price()}", target_density: "#{Faker.Commerce.price()}", target_ph: "#{Faker.Commerce.price()}", target_temp: "#{Faker.Commerce.price()}"}
  @valid_attrs %{description: "some content", type: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    routine = Routine.changeset(%Routine{}, @routine_valid_attrs)
    |> Repo.insert!()
    changeset = Ecto.build_assoc(routine, :log_entries, %{})
      |> LogEntry.changeset(@valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = LogEntry.changeset(%LogEntry{}, @invalid_attrs)
    refute changeset.valid?
  end
end
