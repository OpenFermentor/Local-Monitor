defmodule BioMonitor.Repo.Migrations.CreateLogEntry do
  use Ecto.Migration

  def change do
    create table(:log_entries) do
      add :type, :string
      add :description, :string
      add :routine_id, references(:routines, on_delete: :nothing)

      timestamps()
    end
    create index(:log_entries, [:routine_id])

  end
end
