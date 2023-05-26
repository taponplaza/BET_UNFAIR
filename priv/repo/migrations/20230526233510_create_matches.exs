defmodule BetUnfair.Repo.Migrations.CreateMatches do
  use Ecto.Migration

  def change do
    create table(:matches) do
      add :back_bet_id, references(:bets, type: :id), null: false
      add :lay_bet_id, references(:bets, type: :id), null: false
      add :matched_amount, :integer

      timestamps()
    end
  end
end
