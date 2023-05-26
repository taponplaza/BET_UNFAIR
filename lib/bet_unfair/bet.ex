defmodule BetUnfair.Bet do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias BetUnfair.{Repo, Market, User, Bet, Match}

  @bet_statuses ["active", "cancelled", "market_cancelled", "market_settled"]
  @bet_types ["back", "lay"]

  schema "bets" do
    belongs_to :user, User, foreign_key: :user_id, type: :string
    belongs_to :market, Market, foreign_key: :market_id, type: :string
    field :amount, :integer
    field :odds, :integer
    field :bet_type, :string
    field :original_stake, :integer
    field :remaining_stake, :integer
    field :status, :string

    timestamps()
  end

  def changeset(bet, attrs) do
    bet
    |> cast(attrs, [:user_id, :market_id, :amount, :odds, :bet_type, :original_stake, :remaining_stake, :status])
    |> validate_required([:user_id, :market_id, :amount, :odds, :bet_type, :original_stake, :remaining_stake, :status])
    |> validate_inclusion(:status, @bet_statuses)
    |> validate_inclusion(:bet_type, @bet_types)
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
      nil ->
        {:error, "Bet not found."}

      bet ->
        matched_bets = Match.get_matched_bets(bet_id)

        bet_details =
          case bet.status do
            "market_settled" ->
              # fetch the market result
              {:ok, market} = Market.market_get(bet.market_id)
              market_result = case market.status do
                {:settled, result} -> result
                _ -> nil
              end

              %{bet_type: String.to_atom(bet.bet_type),
                market_id: bet.market_id,
                user_id: bet.user_id,
                odds: bet.odds,
                original_stake: bet.original_stake,
                remaining_stake: bet.remaining_stake,
                matched_bets: matched_bets,
                status: {:market_settled, market_result}}
            _ ->
              %{bet_type: String.to_atom(bet.bet_type),
                market_id: bet.market_id,
                user_id: bet.user_id,
                odds: bet.odds,
                original_stake: bet.original_stake,
                remaining_stake: bet.remaining_stake,
                matched_bets: matched_bets,
                status: String.to_atom(bet.status)}
          end
        {:ok, bet_details}
    end
  end


  defp get_unmatched_bets(market_id, bet_type) do
    from(b in Bet,
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

        # Compute new stakes and statuses
        new_back_stake = back_bet.remaining_stake - match_amount
        new_lay_stake = lay_bet.remaining_stake - match_amount
        new_back_status = if(new_back_stake == 0, do: "matched", else: "active")
        new_lay_status = if(new_lay_stake == 0, do: "matched", else: "active")

        # Begin a new multi operation
        multi =
          Ecto.Multi.new()
          |> Ecto.Multi.update(:update_back_bet, Bet.changeset(back_bet, %{remaining_stake: new_back_stake, status: new_back_status}))
          |> Ecto.Multi.update(:update_lay_bet, Bet.changeset(lay_bet, %{remaining_stake: new_lay_stake, status: new_lay_status}))
          |> Ecto.Multi.insert(:create_match, Match.changeset(%Match{}, %{back_bet_id: back_bet.id, lay_bet_id: lay_bet.id, amount: match_amount}))

        case Repo.transaction(multi) do
          {:ok, _} ->
            :ok

          {:error, failed_operation, failed_value, _changes_so_far} ->
            IO.inspect(failed_operation)
            IO.inspect(failed_value)
            {:error, "Failed to match bets."}
        end
      end
    end
  end
end
