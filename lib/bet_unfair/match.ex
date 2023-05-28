defmodule Betunfair.Match do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Betunfair.{Repo, Bet, Match}

  schema "matches" do
    belongs_to :back_bet, Bet, foreign_key: :back_bet_id
    belongs_to :lay_bet, Bet, foreign_key: :lay_bet_id
    field :matched_amount, :integer

    timestamps()
  end

  def changeset(match, attrs) do
    match
    |> cast(attrs, [:back_bet_id, :lay_bet_id, :matched_amount])
    |> validate_required([:back_bet_id, :lay_bet_id, :matched_amount])
  end

  def create_match(back_bet, lay_bet, matched_amount) do
    match_changeset =
      %__MODULE__{}
      |> changeset(%{back_bet_id: back_bet.id, lay_bet_id: lay_bet.id, matched_amount: matched_amount})

    case Repo.insert(match_changeset) do
      {:ok, _match} ->
        {:ok, "Match created."}

      {:error, _changeset} ->
        {:error, "Failed to create a match."}
    end
  end

  def get_matched_bets(bet_id) do
    query = from m in Match,
      where: m.back_bet_id == ^bet_id or m.lay_bet_id == ^bet_id,
      select: %{id: m.id, back_bet_id: m.back_bet_id, lay_bet_id: m.lay_bet_id, matched_amount: m.matched_amount}

    Repo.all(query)
  end


end
