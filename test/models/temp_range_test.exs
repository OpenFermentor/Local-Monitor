defmodule BioMonitor.TempRangeTest do
  use BioMonitor.ModelCase

  alias BioMonitor.TempRange

  @valid_attrs %{from_second: 42, temp: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = TempRange.changeset(%TempRange{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = TempRange.changeset(%TempRange{}, @invalid_attrs)
    refute changeset.valid?
  end
end
