defmodule BioMonitor.Repo.Migrations.AddToleranceToRoutine do
  use Ecto.Migration

  def change do
    alter table(:routines) do
      add :temp_tolerance, :float, default: 1.0
      add :ph_tolerance, :float, default: 0.5
    end
  end
end
