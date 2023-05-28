defmodule Betunfair.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :user_id, :string, primary_key: true
      add :name, :string
      add :balance, :integer, default: 0

      timestamps()
    end

    create unique_index(:users, [:user_id])
  end
end
