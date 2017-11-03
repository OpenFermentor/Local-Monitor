defmodule BioMonitor.Tag do
  use BioMonitor.Web, :model

  schema "tags" do
    field :value, :string
    belongs_to :routine, BioMonitor.Routine

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:value])
    |> validate_required([:value])
  end
end
