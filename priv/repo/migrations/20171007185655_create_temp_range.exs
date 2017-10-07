defmodule BioMonitor.Repo.Migrations.CreateTempRange do
  use Ecto.Migration

  def change do
    create table(:temp_ranges) do
      add :temp, :integer
      add :from_second, :integer
      add :routine_id, references(:routines, on_delete: :nothing)

      timestamps()
    end
    create index(:temp_ranges, [:routine_id])

  end
end
