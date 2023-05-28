defmodule Betunfair.BetTest do
  use ExUnit.Case, async: true
  alias Betunfair.{Repo, Bet, User, Market}

  setup do
    # Clear the database before each test
    Repo.delete_all(Bet)
    Repo.delete_all(Market)
    Repo.delete_all(User)

    # This will be run before each test
    user_id = "test_user_id"
    name = "Test User"
    {:ok, user_id} = User.user_create(user_id, name)
    User.user_deposit(user_id, 200)
    {:ok, market_id} = Market.market_create("Test Market", "This is a test market")

    {:ok, user_id: user_id, market_id: market_id}
  end

  test "bet_back places a back bet", context do
    {:ok, bet_id} = Bet.bet_back(context.user_id, context.market_id, 100, 2)
    bet = Repo.get(Bet, bet_id)
    assert bet.user_id == context.user_id
    assert bet.market_id == context.market_id
    assert bet.amount == 100
    assert bet.odds == 2
    assert bet.bet_type == "back"
  end

  test "bet_lay places a lay bet", context do
    {:ok, bet_id} = Bet.bet_lay(context.user_id, context.market_id, 100, 2)
    bet = Repo.get(Bet, bet_id)
    assert bet.user_id == context.user_id
    assert bet.market_id == context.market_id
    assert bet.amount == 100
    assert bet.odds == 2
    assert bet.bet_type == "lay"
  end

  test "bet_cancel cancels a bet", context do
    {:ok, bet_id} = Bet.bet_back(context.user_id, context.market_id, 100, 2)
    Bet.bet_cancel(bet_id)
    bet = Repo.get(Bet, bet_id)
    assert bet.status == "cancelled"
  end

  test "bet_get retrieves a bet", context do
    {:ok, bet_id} = Bet.bet_back(context.user_id, context.market_id, 100, 2)
    {:ok, bet} = Bet.bet_get(bet_id)
    assert bet.id == bet_id
  end
end
