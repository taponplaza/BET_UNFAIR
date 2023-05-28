defmodule Betunfair.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Betunfair.{Repo, Bet}

  @primary_key {:user_id, :string, autogenerate: false}
  schema "users" do
    field :name, :string
    field :balance, :integer, default: 0
    has_many :bets, Betunfair.Bet, foreign_key: :user_id
    timestamps()
  end


  def changeset(user, attrs) do
    user
    |> cast(attrs, [:user_id, :name, :balance])
    |> validate_required([:user_id, :name])
    |> unique_constraint(:user_id)
  end

  def user_create(user_id, name) do
    existing_user = Repo.get_by(__MODULE__, user_id: user_id)

    if existing_user do
      :error
    else
      user_changeset =
        %__MODULE__{}
        |> changeset(%{user_id: user_id, name: name})

      case Repo.insert(user_changeset, returning: true, return_sources: true) do
        {:ok, user} ->
          {:ok, user.user_id}

        _ ->
          :error
      end
    end
  end


  def user_deposit(user_id, amount) when is_integer(amount) and amount > 0 do
    Repo.transaction(fn ->
      case Repo.get_by(__MODULE__, user_id: user_id) do
        nil ->
          {:error, "User does not exist."}

        user ->
          user
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.put_change(:balance, user.balance + amount)
          |> Repo.update()

          amount
      end
    end)
  end

  def user_deposit(_, amount) when is_integer(amount) and amount <= 0, do: {:error, "Invalid deposit amount"}

  def user_deposit(_, _), do: {:error, "Invalid deposit amount"}




  def user_withdraw(user_id, amount) when is_integer(amount) and amount > 0 do
    case Repo.get_by(__MODULE__, user_id: user_id) do
      nil ->
        {:error, "User does not exist."}

      user ->
        if user.balance < amount do
          {:error, "Insufficient balance."}
        else
          Repo.transaction(fn ->
            user
            |> Ecto.Changeset.change()
            |> Ecto.Changeset.put_change(:balance, user.balance - amount)
            |> Repo.update()
          end)
          {:ok, amount}
        end
    end
  end


  def user_get(user_id) do
    case Repo.get_by(__MODULE__, user_id: user_id) do
      nil ->
        {:error, "User does not exist."}

      user ->
        {:ok, %{
          name: user.name,
          id: user.user_id,
          balance: user.balance
        }}
    end
  end

  def user_bets(user_id) do
    case Repo.get_by(__MODULE__, user_id: user_id) do
      nil ->
        {:error, "User does not exist."}

      user ->
        user_bets =
          user
          |> Repo.preload(:bets)
          |> Map.get(:bets)
          |> Enum.map(& &1.id)

        {:ok, user_bets}
    end
  end
end
