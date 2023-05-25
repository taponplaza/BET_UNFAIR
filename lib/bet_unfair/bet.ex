defmodule BetUnfair.Bet do
  use Ecto.Schema
  import Ecto.Changeset
  alias BetUnfair.{Repo, Market, User}

  schema "bets" do
    belongs_to :user, User, foreign_key: :user_id, type: :string
    belongs_to :market, Market, foreign_key: :market_id, type: :string
    field :amount, :integer
    field :odds, :integer
    field :bet_type, :string
    field :original_stake, :integer
    field :remaining_stake, :integer
    field :matched_bets, {:array, :integer}
    field :status, :string

    timestamps()
  end

  def changeset(bet, attrs) do
    bet
    |> cast(attrs, [:user_id, :market_id, :amount, :odds, :bet_type, :original_stake, :remaining_stake, :matched_bets, :status])
    |> validate_required([:user_id, :market_id, :amount, :odds, :bet_type, :original_stake, :remaining_stake, :matched_bets, :status])
  end

  def bet_back(user_id, market_id, stake, odds) do
    bet_changeset =
      %__MODULE__{}
      |> changeset(%{user_id: user_id, market_id: market_id, amount: stake, odds: odds, bet_type: "back", original_stake: stake, remaining_stake: stake, matched_bets: [], status: "active"})
    case Repo.insert(bet_changeset) do
      {:ok, bet} -> {:ok, bet.id}
      _ -> {:error, "Failed to place back bet."}
    end
  end

  def bet_lay(user_id, market_id, stake, odds) do
    bet_changeset =
      %__MODULE__{}
      |> changeset(%{user_id: user_id, market_id: market_id, amount: stake, odds: odds, bet_type: "lay", original_stake: stake, remaining_stake: stake, matched_bets: [], status: "active"})
    case Repo.insert(bet_changeset) do
      {:ok, bet} -> {:ok, bet.id}
      _ -> {:error, "Failed to place lay bet."}
    end
  end

  def bet_cancel(bet_id) do
    case Repo.get(__MODULE__, bet_id) do
      nil -> {:error, "Bet not found."}
      bet ->
        bet
        |> Ecto.Changeset.change(%{status: "cancelled"})
        |> Repo.update()
    end
  end

  def bet_get(bet_id) do
    case Repo.get(__MODULE__, bet_id) do
      nil -> {:error, "Bet not found."}
      bet -> {:ok, bet}
    end
  end


  def get_unmatched_bets(market_id, bet_type) do
    from(b in __MODULE__,
      where: b.market_id == ^market_id and b.bet_type == ^bet_type and b.status == "active",
      order_by: [desc: b.odds, asc: b.inserted_at]
    )
    |> Repo.all()
  end




  def match_bets(market_id) do
    back_bets = get_unmatched_bets(market_id, "back")
    lay_bets = get_unmatched_bets(market_id, "lay")

    for back_bet <- back_bets, lay_bet <- lay_bets do
      if back_bet.odds <= lay_bet.odds do
        match_amount = min(back_bet.remaining_stake, lay_bet.remaining_stake)

        # Update the bets
        Bet.update_remaining_stake(back_bet, back_bet.remaining_stake - match_amount)
        Bet.update_remaining_stake(lay_bet, lay_bet.remaining_stake - match_amount)

        # Record the match
        create_match(back_bet, lay_bet, match_amount)
      end
    end
  end

  def update_remaining_stake(bet, new_stake) do
    new_status = if new_stake == 0, do: "matched", else: "active"

    bet
    |> Ecto.Changeset.change(%{remaining_stake: new_stake, status: new_status})
    |> Repo.update()
  end

end
