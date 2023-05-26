defmodule BetUnfair.Repo.Migrations.CreateMatches do
  use Ecto.Migration

  def change do
    create table(:matches) do
      add :back_bet_id, references(:bets, on_delete: :nothing), null: false
      add :lay_bet_id, references(:bets, on_delete: :nothing), null: false
      add :matched_amount, :integer

      timestamps()
    end

    create unique_index(:matches, [:back_bet_id, :lay_bet_id])
  end
end
