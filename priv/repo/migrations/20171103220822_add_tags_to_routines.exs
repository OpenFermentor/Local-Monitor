defmodule BioMonitor.Repo.Migrations.AddTagsToRoutines do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :value, :string
      add :routine_id, references(:routines, on_delete: :nothing)

      timestamps()
    end
    create index(:tags, [:routine_id])
  end
end
