defmodule Betunfair.Bet do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Betunfair.{Repo, Market, User, Bet, Match}

  @bet_statuses ["active", "cancelled", "market_cancelled", "market_settled", "matched"]
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
    case Market.market_get(market_id) do
      {:ok, %{status: "active"}} ->
        case User.user_withdraw(user_id, stake) do
          {:ok, _} ->
            bet_changeset =
              %__MODULE__{}
              |> changeset(%{user_id: user_id, market_id: market_id, amount: stake, odds: odds, bet_type: "back", original_stake: stake, remaining_stake: stake, matched_bets: [], status: "active"})
            case Repo.insert(bet_changeset) do
              {:ok, bet} -> {:ok, bet.id}
              _ -> {:error, "Failed to place back bet."}
            end
          {:error, _} -> {:error, "Insufficient balance to place bet."}
        end
      _ -> {:error, "Market is not active"}
    end
  end

  def bet_lay(user_id, market_id, stake, odds) do
    case Market.market_get(market_id) do
      {:ok, %{status: "active"}} ->
        case User.user_withdraw(user_id, stake) do
          {:ok, _} ->
            bet_changeset =
              %__MODULE__{}
              |> changeset(%{user_id: user_id, market_id: market_id, amount: stake, odds: odds, bet_type: "lay", original_stake: stake, remaining_stake: stake, matched_bets: [], status: "active"})
            case Repo.insert(bet_changeset) do
              {:ok, bet} -> {:ok, bet.id}
              _ -> {:error, "Failed to place lay bet."}
            end
          {:error, _} -> {:error, "Insufficient balance to place bet."}
        end
      _ -> {:error, "Market is not active"}
    end
  end



  def bet_cancel(bet_id) do
    Repo.transaction(fn ->
      bet = Repo.get(__MODULE__, bet_id)

      case {bet, bet && bet.status} do
        {nil, _} ->
          {:error, "Bet not found."}

        {_, "cancelled"} ->
          {:error, "Bet already cancelled."}

        {_, "active"} ->
          user = Repo.get(User, bet.user_id)

          user
          |> Ecto.Changeset.change(%{balance: user.balance + bet.remaining_stake})
          |> Repo.update!()

          bet
          |> Ecto.Changeset.change(%{status: "cancelled", original_stake: bet.original_stake - bet.remaining_stake, remaining_stake: 0})
          |> Repo.update!()

          :ok

        {_, _} ->
          {:error, "Cannot cancel a bet in current state."}
      end
    end)
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
                id: bet.id,
                odds: bet.odds,
                stake: bet.remaining_stake,
                original_stake: bet.original_stake,
                remaining_stake: bet.remaining_stake,
                matched_bets: matched_bets,
                status: {:market_settled, market_result}}
            _ ->
              %{bet_type: String.to_atom(bet.bet_type),
                market_id: bet.market_id,
                user_id: bet.user_id,
                id: bet.id,
                odds: bet.odds,
                original_stake: bet.original_stake,
                remaining_stake: bet.remaining_stake,
                stake: bet.remaining_stake,
                matched_bets: matched_bets,
                status: String.to_atom(bet.status)}
          end
        {:ok, bet_details}
    end
  end
end
