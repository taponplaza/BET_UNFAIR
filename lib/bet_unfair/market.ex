defmodule Betunfair.Market do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Betunfair.{Repo, Bet, Match, Market}

  @primary_key {:name, :string, autogenerate: false}
  @market_statuses ["active", "frozen", "cancelled", "settled"]

  schema "markets" do
    field :description, :string
    field :status, :string, default: "active"
    field :result, :boolean

    timestamps()
  end

  def changeset(market, attrs) do
    market
    |> cast(attrs, [:name, :description, :status, :result])
    |> validate_required([:name, :description, :status])
    |> validate_inclusion(:status, @market_statuses)
    |> unique_constraint(:name)
  end

  def market_create(name, description) do
    market_changeset =
      %__MODULE__{}
      |> changeset(%{name: name, description: description, status: "active"})

    case Repo.insert(market_changeset, returning: false) do
      {:ok, market} ->
        {:ok, market.name}

      {:error, _changeset} ->
        {:error, "A market with the same name already exists."}
    end
  end


  def market_list() do
    markets = Repo.all(__MODULE__)
    {:ok, Enum.map(markets, & &1.name)}
  end

  def market_list_active() do
    markets = Repo.all(from m in __MODULE__, where: m.status == "active")
    {:ok, Enum.map(markets, & &1.name)}
  end

  def market_cancel(market_id) do
    case Repo.get_by(__MODULE__, name: market_id) do
      nil ->
        {:error, "Market does not exist."}

      market ->
        market
        |> Ecto.Changeset.change(status: "cancelled")
        |> Repo.update()

        bets = Betunfair.Bet |> Ecto.Query.where(market_id: ^market_id) |> Repo.all()

        Enum.each(bets, fn bet ->
          Betunfair.User.user_deposit(bet.user_id, bet.original_stake)

          bet
          |> Ecto.Changeset.change(status: "market_cancelled")
          |> Repo.update()
        end)

        :ok
      end
  end


  def market_freeze(market_id) do
    case Repo.get_by(__MODULE__, name: market_id) do
      nil ->
        {:error, "Market does not exist."}

      market ->
        market
        |> Ecto.Changeset.change(status: "frozen")
        |> Repo.update()

        bets = Bet |> Ecto.Query.where(market_id: ^market_id) |> Repo.all()

        :ok
    end
  end

  def market_settle(market_id, result) when is_boolean(result) do
    case Repo.get_by(__MODULE__, name: market_id) do
      nil ->
        {:error, "Market does not exist."}

      market ->
        market
        |> Ecto.Changeset.change(status: "settled", result: result)
        |> Repo.update()

        bets = Bet |> Ecto.Query.where(market_id: ^market_id) |> Repo.all()

        Enum.each(bets, fn bet ->
          matches =  Match.get_matched_bets(bet.id)
          has_won = result == (bet.bet_type == "back")

          if has_won do
            total_matched_amount  = Enum.reduce(matches, 0, fn match, acc ->
                acc + match.matched_amount
            end)

            if bet.bet_type != "back" do
              winnings = bet.original_stake + total_matched_amount
              Betunfair.User.user_deposit(bet.user_id, winnings)
            else
              total_matched_amount = trunc(total_matched_amount * (bet.odds / 100 - 1))
              winnings = bet.original_stake + total_matched_amount
              Betunfair.User.user_deposit(bet.user_id, winnings)
            end
          else
            Betunfair.User.user_deposit(bet.user_id, bet.remaining_stake)
          end

          bet
          |> Ecto.Changeset.change(status: "market_settled")
          |> Repo.update()
        end)

        :ok
      end
  end


  def market_bets(market_id) do
    case Repo.get_by(__MODULE__, name: market_id) do
      nil ->
        {:error, "Market does not exist."}

      market ->
        bets = market
        |> Repo.preload(:bets)
        |> Map.get(:bets)
        |> Enum.map(& &1.id)

        {:ok, bets}
    end
  end

  def market_pending_backs(market_id) do
    market = Repo.get_by(__MODULE__, name: market_id)
    if market do
      query = from(b in Bet,
             where: b.market_id == ^market.name and
                    b.bet_type == "back" and
                    b.status == "active",
             order_by: [asc: b.odds])
      bets = Repo.all(query)
      {:ok, Enum.map(bets, fn bet -> {bet.odds, bet.id} end)}
    else
      {:error, "Market does not exist."}
    end
  end

  def market_pending_lays(market_id) do
    market = Repo.get_by(__MODULE__, name: market_id)
    if market do
      query = from(b in Bet,
             where: b.market_id == ^market.name and
                    b.bet_type == "lay" and
                    b.status == "active",
             order_by: [desc: b.odds])
      bets = Repo.all(query)
      {:ok, Enum.map(bets, fn bet -> {bet.odds, bet.id} end)}
    else
      {:error, "Market does not exist."}
    end
  end

  def market_get(market_id) do
    case Repo.get_by(__MODULE__, name: market_id) do
      nil ->
        {:error, "Market does not exist."}

      market ->
        market_details =
          if market.status == "settled" do
            %{name: market.name, description: market.description, status: {:settled, market.result}}
          else
            %{name: market.name, description: market.description, status: market.status}
          end

        {:ok, market_details}
    end
  end


  def market_match(market_id) do
    case {market_pending_backs(market_id), market_pending_lays(market_id)} do
      {{:ok, back_bets}, {:ok, lay_bets}} when length(back_bets) > 0 and length(lay_bets) > 0 ->
        match_bets(back_bets, lay_bets, market_id)

      _ ->
        {:ok, "No match found."}
    end
  end

  defp match_bets([], _, _), do: {:ok, "Matching done."}
  defp match_bets(_, [], _), do: {:ok, "Matching done."}
  defp match_bets([{back_odds, back_bet_id} | back_bets_tail], [{lay_odds, lay_bet_id} | lay_bets_tail] = lay_bets, market_id) do
    if back_odds <= lay_odds do
      back_bet = Repo.get(Bet, back_bet_id)
      lay_bet = Repo.get(Bet, lay_bet_id)

      {new_back_stake, new_lay_stake, match_amount} =
        if back_bet.remaining_stake * back_odds / 100 - back_bet.remaining_stake >= lay_bet.remaining_stake do
          match_amount = trunc(lay_bet.remaining_stake / (back_odds / 100 - 1))
          new_back_stake = back_bet.remaining_stake - match_amount
          new_lay_stake = 0
          {new_back_stake, new_lay_stake, match_amount}
        else
          match_amount = trunc(back_bet.remaining_stake * back_odds / 100  - back_bet.remaining_stake)
          new_back_stake = 0
          new_lay_stake = lay_bet.remaining_stake - match_amount
          {new_back_stake, new_lay_stake, match_amount}
        end


      # Compute new stakes and statuses
      new_back_status = if(new_back_stake == 0, do: "matched", else: "active")
      new_lay_status = if(new_lay_stake == 0, do: "matched", else: "active")

      # Begin a new multi operation
      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.update(:update_back_bet, Bet.changeset(back_bet, %{remaining_stake: new_back_stake, status: new_back_status}))
        |> Ecto.Multi.update(:update_lay_bet, Bet.changeset(lay_bet, %{remaining_stake: new_lay_stake, status: new_lay_status}))
        |> Ecto.Multi.insert(:create_match, Match.changeset(%Match{}, %{back_bet_id: back_bet.id, lay_bet_id: lay_bet.id, matched_amount: match_amount}))

        case Repo.transaction(multi) do
          {:ok, _} ->
            new_back_bets = if new_back_stake > 0, do: [{back_odds, back_bet_id} | back_bets_tail], else: back_bets_tail
            new_lay_bets = if new_lay_stake > 0, do: [{lay_odds, lay_bet_id} | lay_bets_tail], else: lay_bets_tail
            match_bets(new_back_bets, new_lay_bets, market_id) # Recursive call with updated lists

          {:error, failed_operation, failed_value, _changes_so_far} ->
            IO.inspect(failed_operation)
            IO.inspect(failed_value)
            {:error, "Failed to match bets."}
        end

    else
      {:ok, "Matching done."}
    end
  end
end
