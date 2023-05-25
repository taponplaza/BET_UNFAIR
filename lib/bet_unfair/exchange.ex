defmodule BetUnfair.Exchange do
  use GenServer
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias BetUnfair.{Repo, Bet, User, Market}

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: String.to_atom(name))
  end

  def init(name) do
    # You might want to load previously saved data for this exchange here.
    {:ok, %{name: name}}
  end

  def stop(name) do
    GenServer.cast(String.to_atom(name), :stop)
  end

  def clean(name) do
    GenServer.call(String.to_atom(name), :clean)
  end

  def handle_cast(:stop, state) do
    # You might want to save the current state of the exchange here.
    {:stop, :normal, state}
  end

  def handle_call(:clean, _from, state) do
    Repo.delete_all(User)
    Repo.delete_all(Bet)
    Repo.delete_all(Market)
    {:reply, :ok, %{name: state.name}}
  end

  def create_match(back_bet, lay_bet, match_amount) do
    # Implementation depends on how you want to store this information.
  end

end
