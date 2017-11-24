defmodule BioMonitor.Repo.Migrations.AddParamsToReadings do
  use Ecto.Migration

  def change do
    alter table(:readings) do
      add :biomass, :float, default: 0
      add :observancy, :float, default: 0
      add :substratum, :float, default: 0
      remove :co2
      remove :density
    end
  end
end
