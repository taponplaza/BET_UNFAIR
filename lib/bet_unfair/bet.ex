defmodule BetUnfair.Bet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bets" do
    belongs_to :user, BetUnfair.User, foreign_key: :user_id, type: :string

    field :amount, :integer

    timestamps()
  end

  def changeset(bet, attrs) do
    bet
    |> cast(attrs, [:user_id, :amount])
    |> validate_required([:user_id, :amount])
  end
end
