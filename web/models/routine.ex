defmodule BioMonitor.Routine do
  use BioMonitor.Web, :model

  @moduledoc """
    Model used to define routines.
  """

  schema "routines" do
    field :title, :string
    field :strain, :string
    field :medium, :string
    field :target_temp, :float
    field :target_ph, :float
    field :target_co2, :float
    field :target_density, :float
    field :estimated_time_seconds, :float
    field :extra_notes, :string
    has_many :readings, BioMonitor.Reading

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :strain, :medium, :target_temp, :target_ph, :target_co2, :target_density, :estimated_time_seconds, :extra_notes])
    |> validate_required([:title, :strain, :medium, :target_temp, :target_ph, :target_density, :estimated_time_seconds])
  end
end
