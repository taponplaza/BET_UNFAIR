import Config

config :bet_unfair, :ecto_repos, [Betunfair.Repo]

import_config "#{Mix.env()}.exs"
