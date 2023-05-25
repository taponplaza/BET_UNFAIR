defmodule BetUnfair.UserTest do
  use ExUnit.Case, async: true
  alias BetUnfair.{Repo, Bet, User, Market}


  setup do
    # Clear the database before each test
    Repo.delete_all(User)

    # This will be run before each test
    user_id = "test_user_id"
    name = "Test User"
    {:ok, user_id} = User.user_create(user_id, name)
    User.user_deposit(user_id, 200)
    {:ok, user_id: user_id}
  end

  test "user_withdraw updates the user's balance", context do
    User.user_withdraw(context.user_id, 100)
    user = Repo.get_by(User, user_id: context.user_id)
    assert user.balance == 100
  end

  test "user_withdraw does not allow overdrawing", context do
    {:error, _} = User.user_withdraw(context.user_id, 300)
    user = Repo.get_by(User, user_id: context.user_id)
    assert user.balance == 200
  end

  test "user_get retrieves a user", context do
    {:ok, user} = User.user_get(context.user_id)
    assert user.id == context.user_id
    assert user.balance == 200
  end
end
