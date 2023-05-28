defmodule BetUnfair.BetTest do
  use ExUnit.Case, async: true
  alias BetUnfair.{Repo, Bet, User, Market, Match}

  setup do
    # Clear the database before each test
    Repo.delete_all(Bet)
    Repo.delete_all(Market)
    Repo.delete_all(User)
    Repo.delete_all(Match)

    :ok  # This will be the return value of the setup block
  end


  test "user_create_deposit_get" do
    assert :ok = BetUnfair.clean("testdb")
    assert :ok = BetUnfair.start_link("testdb")
    assert {:ok,u1} = BetUnfair.user_create("u1","Francisco Gonzalez")
    assert is_error(BetUnfair.user_create("u1","Francisco Gonzalez"))
    assert is_ok(BetUnfair.user_deposit(u1,2000))
    assert is_error(BetUnfair.user_deposit(u1,-1))
    assert is_error(BetUnfair.user_deposit(u1,0))
    assert is_error(BetUnfair.user_deposit("u11",0))
    assert {:ok,%{balance: 2000}} = BetUnfair.user_get(u1)
  end

  test "user_bet1" do
    assert :ok = BetUnfair.clean("testdb")
    assert :ok = BetUnfair.start_link("testdb")
    assert {:ok,u1} = BetUnfair.user_create("u1","Francisco Gonzalez")
    assert is_ok(BetUnfair.user_deposit(u1,2000))
    assert {:ok,%{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok,m1} = BetUnfair.market_create("rmw","Real Madrid wins")
    assert {:ok,b} = BetUnfair.bet_back(u1,m1,1000,150)
    assert {:ok,%{id: ^b, bet_type: :back, stake: 1000, odds: 150, status: :active}} = BetUnfair.bet_get(b)
    assert {:ok,markets} = BetUnfair.market_list()
    assert 1 = length(markets)
    assert {:ok,markets} = BetUnfair.market_list_active()
    assert 1 = length(markets)
  end

  test "user_persist" do
    assert :ok = BetUnfair.clean("testdb")
    assert :ok = BetUnfair.start_link("testdb")
    assert {:ok,u1} = BetUnfair.user_create("u1","Francisco Gonzalez")
    assert is_ok(BetUnfair.user_deposit(u1,2000))
    assert {:ok,%{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok,m1} = BetUnfair.market_create("rmw","Real Madrid wins")
    assert {:ok,b} = BetUnfair.bet_back(u1,m1,1000,150)
    assert {:ok,%{id: ^b, bet_type: :back, stake: 1000, odds: 150, status: :active}} = BetUnfair.bet_get(b)
    assert is_ok(BetUnfair.stop())
    :timer.sleep(50)  # wait for 1 second
    assert :ok = BetUnfair.start_link("testdb")
    assert {:ok,%{balance: 1000}} = BetUnfair.user_get(u1)
    assert {:ok,markets} = BetUnfair.market_list()
    assert 1 = length(markets)
    assert {:ok,markets} = BetUnfair.market_list_active()
    assert 1 = length(markets)
  end

  test "match_bets1" do
    assert :ok = BetUnfair.clean("testdb")
    assert :ok = BetUnfair.start_link("testdb")
    assert {:ok,u1} = BetUnfair.user_create("u1","Francisco Gonzalez")
    assert {:ok,u2} = BetUnfair.user_create("u2","Maria Fernandez")
    assert is_ok(BetUnfair.user_deposit(u1,2000))
    assert is_ok(BetUnfair.user_deposit(u2,2000))
    assert {:ok,%{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok,m1} = BetUnfair.market_create("rmw","Real Madrid wins")
    assert {:ok,bb1} = BetUnfair.bet_back(u1,m1,1000,150)
    assert {:ok,bb2} = BetUnfair.bet_back(u1,m1,1000,153)
    assert {:ok,%{balance: 0}} = BetUnfair.user_get(u1)
    assert true = (bb1 != bb2)
    assert {:ok,bl1} = BetUnfair.bet_lay(u2,m1,500,140)
    assert {:ok,bl2} = BetUnfair.bet_lay(u2,m1,500,150)
    assert {:ok,%{balance: 1000}} = BetUnfair.user_get(u2)
    assert {:ok, backs} = BetUnfair.market_pending_backs(m1)
    assert [^bb1,^bb2] = Enum.to_list(backs) |> Enum.map(fn (e) -> elem(e,1) end)
    assert {:ok,lays} = BetUnfair.market_pending_lays(m1)
    assert [^bl2,^bl1] = Enum.to_list(lays) |> Enum.map(fn (e) -> elem(e,1) end)
    assert is_ok(BetUnfair.market_match(m1))
    assert {:ok,%{stake: 0}} = BetUnfair.bet_get(bb1)
    assert {:ok,%{stake: 0}} = BetUnfair.bet_get(bl2)
  end

  defp is_error(:error),do: true
  defp is_error({:error,_}), do: true
  defp is_error(_), do: false

  defp is_ok(:ok), do: true
  defp is_ok({:ok,_}), do: true
  defp is_ok(_), do: false
end
