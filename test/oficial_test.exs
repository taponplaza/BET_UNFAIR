defmodule BetUnfair.BetTest do
  use ExUnit.Case, async: true
  alias BetUnfair.{Repo, Bet, User, Market}

  setup do
    # Clear the database before each test
    Repo.delete_all(Bet)
    Repo.delete_all(Market)
    Repo.delete_all(User)
  end

  test "user_create_deposit_get" do
    assert {:ok,_} = Betunfair.clean("testdb")
    assert  {:ok,_} = Betunfair.start_link("testdb")
    assert {:ok,u1} = Betunfair.user_create("u1","Francisco Gonzalez")
    assert is_error(Betunfair.user_create("u1","Francisco Gonzalez"))
    assert is_ok(Betunfair.user_deposit(u1,2000))
    assert is_error(Betunfair.user_deposit(u1,-1))
    assert is_error(Betunfair.user_deposit(u1,0))
    assert is_error(Betunfair.user_deposit("u11",0))
    assert {:ok,%{balance: 2000}} = Betunfair.user_get(u1)
  end

  defp is_error(:error),do: true
  defp is_error({:error,_}), do: true
  defp is_error(_), do: false

  defp is_ok(:ok), do: true
  defp is_ok({:ok,_}), do: true
  defp is_ok(_), do: false
end
