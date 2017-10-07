defmodule BioMonitor.Repo.Migrations.AddBalancePhToRoutine do
  use Ecto.Migration

  def change do
    alter table(:routines) do
      add :balance_ph, :boolean, default: false
    end
  end
end
