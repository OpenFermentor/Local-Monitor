defmodule BioMonitor.PhSettingTest do
  use BioMonitor.ModelCase

  alias BioMonitor.PhSetting

  @valid_attrs %{acid: "some content", base: "some content", neutral: "some content"}

  test "changeset with valid attributes" do
    changeset = PhSetting.changeset(%PhSetting{}, @valid_attrs)
    assert changeset.valid?
  end
end
