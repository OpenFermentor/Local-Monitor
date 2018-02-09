defmodule BioMonitor.LogEntry do
  use BioMonitor.Web, :model

  schema "log_entries" do
    field :type, :string
    field :description, :string
    belongs_to :routine, BioMonitor.Routine

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:type, :description, :routine_id])
    |> validate_required([:type, :description, :routine_id])
  end
end
