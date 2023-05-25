defmodule BetUnfair.Repo.Migrations.CreateMarkets do
  use Ecto.Migration

  def change do
    create table(:markets) do
      add :name, :string
      add :description, :string
      add :status, :string, default: "active"

      timestamps()
    end

    create unique_index(:markets, :name)
  end
end
