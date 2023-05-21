import Config

config :bet_unfair, :ecto_repos, [BetUnfair.Repo]

import_config "#{Mix.env()}.exs"
