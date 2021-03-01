defmodule ExBanking.User.Consumer do
  use GenStage

  alias ExBanking.Store

  def init(_) do
    {:consumer, :ok}
  end

  def start_link([], user) do
    {:ok, consumer} =
      GenStage.start_link(__MODULE__, user,
        name: {:via, Registry, {Registry.User, "#{user}_consumer"}}
      )

    GenStage.sync_subscribe(consumer,
      to: {:via, Registry, {Registry.User, user}},
      max_demand: 10,
      min_demand: 1
    )

    {:ok, consumer}
  end

  def handle_events(events, _from, state) do
    for {sender, data} <- events do
      GenStage.reply(sender, Store.process_data(data))
    end

    {:noreply, [], state}
  end
end
