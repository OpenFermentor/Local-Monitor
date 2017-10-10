defmodule BioMonitor.Repo.Migrations.AddTriggerToRoutine do
  use Ecto.Migration

  def change do
    alter table(:routines) do
      add :trigger_after, :integer
      add :trigger_for, :integer, default: 60_000
    end
  end
end
