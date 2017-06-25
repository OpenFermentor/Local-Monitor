defmodule BioMonitor.RoutineTest do
  use BioMonitor.ModelCase

  alias BioMonitor.Routine

  @valid_attrs %{title: Faker.File.file_name(), estimated_time_seconds: "#{Faker.Commerce.price()}", extra_notes: Faker.File.file_name(), medium: Faker.Beer.name(), strain: Faker.Beer.malt(), target_co2: "#{Faker.Commerce.price()}", target_density: "#{Faker.Commerce.price()}", target_ph: "#{Faker.Commerce.price()}", target_temp: "#{Faker.Commerce.price()}"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Routine.changeset(%Routine{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Routine.changeset(%Routine{}, @invalid_attrs)
    refute changeset.valid?
  end
end
