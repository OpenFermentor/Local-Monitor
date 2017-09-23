defmodule BioMonitor.Repo.Migrations.AddStartedToRoutine do
  use Ecto.Migration

  def change do
    alter table(:routines) do
      add :started, :boolean, default: false
      add :started_date, :naive_datetime
    end
  end
end
