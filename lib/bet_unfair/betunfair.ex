defmodule Betunfair do
  use GenServer
  alias Betunfair.{User, Bet, Market, Repo, Match}

  # Client
  def start_link(_) do
    case GenServer.start_link(__MODULE__, %{}, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      :ignore -> {:error, :ignore}
      {:error, {:already_started, _pid}} -> {:ok, _pid}
      other -> other
    end
  end

  def clean(_), do: GenServer.call(__MODULE__, :clean)

  def stop do
    GenServer.cast(__MODULE__, :stop)
  end

  # These functions represent the main operations of the exchange.

  def user_create(user_id, name), do: GenServer.call(__MODULE__, {:user_create, user_id, name})

  def market_create(name, description), do: GenServer.call(__MODULE__, {:market_create, name, description})

  def cancel_bet(bet_id), do: GenServer.call(__MODULE__, {:cancel_bet, bet_id})

  def user_deposit(user_id, amount), do: GenServer.call(__MODULE__, {:user_deposit, user_id, amount})

  def user_withdraw(user_id, amount), do: GenServer.call(__MODULE__, {:user_withdraw, user_id, amount})

  def user_get(user_id), do: GenServer.call(__MODULE__, {:user_get, user_id})

  def user_bets(user_id), do: GenServer.call(__MODULE__, {:user_bets, user_id})

  def market_list(), do: GenServer.call(__MODULE__, :market_list)

  def market_list_active(), do: GenServer.call(__MODULE__, :market_list_active)

  def market_cancel(market_id), do: GenServer.call(__MODULE__, {:market_cancel, market_id})

  def market_freeze(market_id), do: GenServer.call(__MODULE__, {:market_freeze, market_id})

  def market_settle(market_id, result), do: GenServer.call(__MODULE__, {:market_settle, market_id, result})

  def market_bets(market_id), do: GenServer.call(__MODULE__, {:market_bets, market_id})

  def market_pending_backs(market_id), do: GenServer.call(__MODULE__, {:market_pending_backs, market_id})

  def market_pending_lays(market_id), do: GenServer.call(__MODULE__, {:market_pending_lays, market_id})

  def market_get(market_id), do: GenServer.call(__MODULE__, {:market_get, market_id})

  def market_match(market_id), do: GenServer.call(__MODULE__, {:market_match, market_id})

  def bet_back(user_id, market_id, stake, odds), do: GenServer.call(__MODULE__, {:bet_back, user_id, market_id, stake, odds})

  def bet_lay(user_id, market_id, stake, odds), do: GenServer.call(__MODULE__, {:bet_lay, user_id, market_id, stake, odds})

  def bet_cancel(bet_id), do: GenServer.call(__MODULE__, {:bet_cancel, bet_id})

  def bet_get(bet_id), do: GenServer.call(__MODULE__, {:bet_get, bet_id})




  # Server

  def init(_) do
    {:ok, %{}}
  end

  def handle_call(:clean, _from, state) do
    try do
      Repo.transaction(fn ->
        Repo.delete_all(Match)
        Repo.delete_all(Bet)
        Repo.delete_all(Market)
        Repo.delete_all(User)
      end)
      IO.puts "Clean operation completed successfully"
      {:reply, {:ok, :cleaned}, state}
    rescue
      _e in Ecto.StaleEntryError ->
        IO.puts "Failed to complete clean operation"
        {:reply, {:error, :failed_to_clean}, state}
    end
  end


  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end


  def handle_call({:user_create, user_id, name}, _from, state) do
    {:reply, User.user_create(user_id, name), state}
  end

  def handle_call({:market_create, name, description}, _from, state) do
    {:reply, Market.market_create(name, description), state}
  end

  def handle_call({:cancel_bet, bet_id}, _from, state) do
    {:reply, Bet.bet_cancel(bet_id), state}
  end

  def handle_call({:user_deposit, user_id, amount}, _from, state) do
    {:reply, User.user_deposit(user_id, amount), state}
  end

  def handle_call({:user_withdraw, user_id, amount}, _from, state) do
    {:reply, User.user_withdraw(user_id, amount), state}
  end

  def handle_call({:user_get, user_id}, _from, state) do
    {:reply, User.user_get(user_id), state}
  end

  def handle_call({:user_bets, user_id}, _from, state) do
    {:reply, User.user_bets(user_id), state}
  end

  def handle_call(:market_list, _from, state) do
    {:reply, Market.market_list(), state}
  end

  def handle_call(:market_list_active, _from, state) do
    {:reply, Market.market_list_active(), state}
  end

  def handle_call({:market_cancel, market_id}, _from, state) do
    {:reply, Market.market_cancel(market_id), state}
  end

  def handle_call({:market_freeze, market_id}, _from, state) do
    {:reply, Market.market_freeze(market_id), state}
  end

  def handle_call({:market_settle, market_id, result}, _from, state) do
    {:reply, Market.market_settle(market_id, result), state}
  end

  def handle_call({:market_bets, market_id}, _from, state) do
    {:reply, Market.market_bets(market_id), state}
  end

  def handle_call({:market_pending_backs, market_id}, _from, state) do
    {:reply, Market.market_pending_backs(market_id), state}
  end

  def handle_call({:market_pending_lays, market_id}, _from, state) do
    {:reply, Market.market_pending_lays(market_id), state}
  end

  def handle_call({:market_get, market_id}, _from, state) do
    {:reply, Market.market_get(market_id), state}
  end

  def handle_call({:market_match, market_id}, _from, state) do
    {:reply, Market.market_match(market_id), state}
  end

  def handle_call({:bet_back, user_id, market_id, stake, odds}, _from, state) do
    {:reply, Bet.bet_back(user_id, market_id, stake, odds), state}
  end

  def handle_call({:bet_lay, user_id, market_id, stake, odds}, _from, state) do
    {:reply, Bet.bet_lay(user_id, market_id, stake, odds), state}
  end

  def handle_call({:bet_cancel, bet_id}, _from, state) do
    {:reply, Bet.bet_cancel(bet_id), state}
  end

  def handle_call({:bet_get, bet_id}, _from, state) do
    {:reply, Bet.bet_get(bet_id), state}
  end



  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end
