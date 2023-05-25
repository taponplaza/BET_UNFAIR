defmodule BetUnfair.Market do
  use Ecto.Schema
  import Ecto.Changeset
  alias BetUnfair.{Repo, Bet}

  schema "markets" do
    field :name, :string
    field :description, :string
    field :status, :string, default: "active"
    has_many :bets, Bet

    timestamps()
  end

  def changeset(market, attrs) do
    market
    |> cast(attrs, [:name, :description, :status])
    |> validate_required([:name, :description, :status])
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
        |> Ecto.Changeset.change(status: {:settled, result})
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


  def market_get(market_id) do
    case Repo.get_by(__MODULE__, name: market_id) do
      nil ->
        {:error, "Market does not exist."}

      market ->
        {:ok,
          %{
            name: market.name,
            description: market.description,
            status: market.status
          }
        }
    end
  end
end
