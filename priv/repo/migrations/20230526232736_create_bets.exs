defmodule BetUnfair.Repo.Migrations.CreateBets do
  use Ecto.Migration

  def change do
    create table(:bets) do
      add :user_id, references(:users, type: :string, column: :user_id), null: false
      add :market_id, references(:markets, type: :string, column: :name), null: false
      add :amount, :integer
      add :odds, :integer
      add :bet_type, :string
      add :original_stake, :integer
      add :remaining_stake, :integer
      add :status, :string

      timestamps()
    end
  end
end
