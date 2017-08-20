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
    has_many :readings, BioMonitor.Reading

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :strain, :medium, :target_temp, :target_ph, :target_co2, :target_density, :estimated_time_seconds, :extra_notes, :uuid])
    |> validate_required([:title, :strain, :medium, :target_temp, :target_ph, :target_density, :estimated_time_seconds])
    |> generate_uuid
  end

  defp generate_uuid(changeset) do
    with true <- changeset.data.uuid == nil,
      true <- Map.get(changeset.params, "uuid") == nil
    do
      IO.puts("===here====")
      put_change(changeset, :uuid, UUID.uuid1())
    else
      _ -> changeset
    end
  end
end
