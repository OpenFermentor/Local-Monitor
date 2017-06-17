defmodule BioMonitor.Repo.Migrations.CreateRoutine do
  use Ecto.Migration

  def change do
    create table(:routines) do
      add :title, :string
      add :strain, :string
      add :medium, :string
      add :target_temp, :float
      add :target_ph, :float
      add :target_co2, :float
      add :target_density, :float
      add :estimated_time_seconds, :float
      add :extra_notes, :string

      timestamps()
    end

  end
end
