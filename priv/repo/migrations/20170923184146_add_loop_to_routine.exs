defmodule BioMonitor.Repo.Migrations.AddLoopToRoutine do
  use Ecto.Migration

  def change do
    alter table(:routines) do
      add :loop_delay, :integer, default: 2_000
    end
  end
end
