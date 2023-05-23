defmodule BetUnfair.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :user_id, :string
      add :name, :string
      add :balance, :integer, default: 0

      timestamps()
    end

    create unique_index(:users, [:user_id])
  end
end
