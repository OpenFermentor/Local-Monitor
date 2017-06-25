defmodule BioMonitor.Reading do
  use BioMonitor.Web, :model

  @moduledoc """
    Reading model used to register metrics from the micro controller.
  """

  schema "readings" do
    field :temp, :float
    field :ph, :float
    field :co2, :float
    field :density, :float
    belongs_to :routine, BioMonitor.Routine

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:temp, :ph, :co2, :density, :routine_id])
    |> validate_required([:temp, :routine_id])
  end
end
