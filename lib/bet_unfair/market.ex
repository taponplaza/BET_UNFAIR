defmodule BetUnfair.Market do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias BetUnfair.{Repo, Bet}

  @market_statuses ["active", "frozen", "cancelled", "settled"]

  schema "markets" do
    field :name, :string, primary_key: true
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
    |> unique_constraint(:name, message: "This market name is already taken")
  end

  def market_create(name, description) do
    market_changeset =
      %__MODULE__{}
      |> changeset(%{name: name, description: description, status: "active"})

    case Repo.insert(market_changeset) do
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
      query = from(b in Bet, where: b.market_id == ^market.id and b.bet_type == "back" and b.status == "active", order_by: [:asc, :odds])
      bets = Repo.all(query)
      {:ok, Enum.map(bets, fn bet -> {bet.odds, bet.id} end)}
    else
      {:error, "Market does not exist."}
    end
  end

  def market_pending_lays(market_id) do
    market = Repo.get_by(__MODULE__, name: market_id)
    if market do
      query = from(b in Bet, where: b.market_id == ^market.id and b.bet_type == "lay" and b.status == "active", order_by: [:desc, :odds])
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
            %{name: market.name, description: market.description, status: String.to_atom(market.status)}
          end

        {:ok, market_details}
    end
  end


  def market_match(market_id) do
    case Repo.get_by(__MODULE__, name: market_id) do
      nil ->
        {:error, "Market does not exist."}

      market ->
        Bet.match_bets(market_id)
        :ok
    end
  end
end
