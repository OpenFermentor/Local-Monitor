defmodule BioMonitor.TempRange do
  use BioMonitor.Web, :model

  schema "temp_ranges" do
    field :temp, :integer
    field :from_second, :integer
    belongs_to :routine, BioMonitor.Routine

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:temp, :from_second])
    |> validate_required([:temp, :from_second])
  end
end
