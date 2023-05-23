import Config

config :bet_unfair, BetUnfair.Repo,
  username: "postgres",
  password: "postgres",
  database: "bet_unfair_db",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
