defmodule BioMonitor.Routine do
  use BioMonitor.Web, :model
  @moduledoc """
    Model used to define routines.
  """

  alias BioMonitor.LogEntry
  alias BioMonitor.Repo

  @log_types %{reading_error: "reading_error", base_cal: "base_cal", acid_cal: "acid_cal", temp_change: "temp_change", system_error: "system_error"}

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
    field :trigger_after, :integer
    field :trigger_for, :integer
    has_many :readings, BioMonitor.Reading, on_delete: :delete_all
    has_many :log_entries, BioMonitor.LogEntry, on_delete: :delete_all
    has_many :temp_ranges, BioMonitor.TempRange, on_delete: :delete_all, on_replace: :delete
    has_many :tags, BioMonitor.Tag, on_delete: :delete_all, on_replace: :delete

    timestamps()
  end

  @doc """
    Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :strain, :medium, :target_temp, :target_ph, :target_co2, :target_density, :estimated_time_seconds, :extra_notes, :uuid, :temp_tolerance, :ph_tolerance, :loop_delay, :balance_ph, :trigger_after, :trigger_for])
    |> cast_assoc(:temp_ranges, required: false)
    |> cast_assoc(:tags, required: false)
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

  def log_types, do: @log_types

  def log_entry(routine, type, description) do
    case Ecto.build_assoc(routine, :log_entries)
      |> LogEntry.changeset(%{type: type, description: description})
      |> Repo.insert() do
      {:ok, _log_entry} -> :ok
      {:error, _changeset} -> :error
    end
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
