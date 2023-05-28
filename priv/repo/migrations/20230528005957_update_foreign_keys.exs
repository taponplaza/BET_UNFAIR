defmodule BetUnfair.Repo.Migrations.UpdateForeignKeys do
  use Ecto.Migration

  def up do
    drop constraint(:matches, "matches_back_bet_id_fkey")
    drop constraint(:matches, "matches_lay_bet_id_fkey")

    alter table(:matches) do
      modify :back_bet_id, references(:bets, on_delete: :delete_all)
      modify :lay_bet_id, references(:bets, on_delete: :delete_all)
    end
  end

  def down do
    alter table(:matches) do
      modify :back_bet_id, references(:bets)
      modify :lay_bet_id, references(:bets)
    end

    execute "ALTER TABLE matches ADD CONSTRAINT matches_back_bet_id_fkey FOREIGN KEY (back_bet_id) REFERENCES bets (id)"
    execute "ALTER TABLE matches ADD CONSTRAINT matches_lay_bet_id_fkey FOREIGN KEY (lay_bet_id) REFERENCES bets (id)"
  end
end
