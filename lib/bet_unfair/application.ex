defmodule Betunfair.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Betunfair.Repo,
      Betunfair
      # Starts a worker by calling: Betunfair.Worker.start_link(arg)
      # {Betunfair.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Betunfair.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
