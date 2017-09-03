defmodule BioMonitor.PhSetting do
  use BioMonitor.Web, :model

  schema "ph_settings" do
    field :base, :string
    field :acid, :string
    field :neutral, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:base, :acid, :neutral])
  end
end
