defmodule BioMonitor.Repo.Migrations.AddUuidToRoutines do
  use Ecto.Migration

  def change do
    alter table(:routines) do
      add :uuid, :string
    end

    create index(:routines, [:uuid])
  end
end
