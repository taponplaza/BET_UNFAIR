defmodule BetUnfair.Repo.Migrations.CreateBets do
  use Ecto.Migration

  def change do
    create table(:bets) do
      add :user_id, references(:users, column: :user_id, type: :string, on_delete: :delete_all)
      add :amount, :integer

      timestamps()
    end
  end
end
