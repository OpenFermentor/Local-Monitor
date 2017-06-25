defmodule BioMonitor.Repo.Migrations.CreateReading do
  use Ecto.Migration

  def change do
    create table(:readings) do
      add :temp, :float
      add :ph, :float
      add :co2, :float
      add :density, :float
      add :routine_id, references(:routines, on_delete: :nothing)

      timestamps()
    end
    create index(:readings, [:routine_id])

  end
end
