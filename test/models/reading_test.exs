defmodule BioMonitor.ReadingTest do
  use BioMonitor.ModelCase

  alias BioMonitor.Reading
  alias BioMonitor.Routine

  @routine_valid_attrs %{title: Faker.File.file_name(), estimated_time_seconds: "#{Faker.Commerce.price()}", extra_notes: Faker.File.file_name(), medium: Faker.Beer.name(), strain: Faker.Beer.malt(), target_co2: "#{Faker.Commerce.price()}", target_density: "#{Faker.Commerce.price()}", target_ph: "#{Faker.Commerce.price()}", target_temp: "#{Faker.Commerce.price()}"}
  @valid_attrs %{product: "120.5", biomass: "120.5", substratum: "20.20", ph: "120.5", temp: "120.5"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    routine = Routine.changeset(%Routine{}, @routine_valid_attrs)
      |> Repo.insert!()
    changeset = Ecto.build_assoc(routine, :readings, %{})
      |> Reading.changeset(@valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Reading.changeset(%Reading{}, @invalid_attrs)
    refute changeset.valid?
  end
end
