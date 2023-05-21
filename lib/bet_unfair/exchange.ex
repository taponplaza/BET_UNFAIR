defmodule BetUnfair.Exchange do
  use GenServer

  # Client

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: {:global, name})
  end

  def stop(name) do
    GenServer.cast({:global, name}, :stop)
  end

  def clean(name) do
    stop(name)
    # Here you could add some code to delete data from the database or filesystem.
    :ok
  end

  # Server (callbacks)

  def init(name) do
    # You can replace this line with your code to recover the existing data
    # For now, we will start with an empty list.
    {:ok, %{name: name, data: []}}
  end

  def handle_cast(:stop, _state) do
    {:stop, :normal, []}
  end
end
