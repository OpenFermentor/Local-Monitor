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
    field :uuid, :string
    field :started, :boolean
    field :started_date, :naive_datetime
    field :temp_tolerance, :float
    field :ph_tolerance, :float
    field :balance_ph, :boolean
    field :loop_delay, :integer
    has_many :readings, BioMonitor.Reading, on_delete: :delete_all

    timestamps()
  end

  @doc """
    Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :strain, :medium, :target_temp, :target_ph, :target_co2, :target_density, :estimated_time_seconds, :extra_notes, :uuid, :temp_tolerance, :ph_tolerance, :loop_delay, :balance_ph])
    |> validate_required([:title, :strain, :medium, :target_temp, :target_ph, :target_density, :estimated_time_seconds])
    |> generate_uuid
  end

  @doc """
    Builds a changeset to update the started status of a routine.
  """
  def started_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:started, :started_date])
    |> validate_required([:started, :started_date])
  end

  defp generate_uuid(changeset) do
    with true <- changeset.data.uuid == nil,
      true <- Map.get(changeset.params, "uuid") == nil
    do
      put_change(changeset, :uuid, UUID.uuid1())
    else
      _ -> changeset
    end
  end
end
