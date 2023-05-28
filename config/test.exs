import Config

config :bet_unfair, Betunfair.Repo,
  username: "postgres",
  password: "postgres",
  database: "bet_unfair_db",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
