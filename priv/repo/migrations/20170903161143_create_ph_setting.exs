defmodule BioMonitor.Repo.Migrations.CreatePhSetting do
  use Ecto.Migration

  def change do
    create table(:ph_settings) do
      add :base, :string
      add :acid, :string
      add :neutral, :string

      timestamps()
    end

  end
end
