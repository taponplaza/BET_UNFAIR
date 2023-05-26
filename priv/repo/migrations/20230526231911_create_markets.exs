defmodule BetUnfair.Repo.Migrations.CreateMarkets do
  use Ecto.Migration

  def change do
    create table(:markets, primary_key: false) do
      add :name, :string, primary_key: true
      add :description, :string
      add :status, :string, default: "active"
      add :result, :boolean

      timestamps()
    end
  end
end
