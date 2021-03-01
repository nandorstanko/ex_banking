defmodule ExBanking.User.Producer do
  use GenStage

  def init(counter) do
    {:producer, {:queue.new(), counter}}
  end

  def start_link([], user) do
    GenStage.start_link(__MODULE__, 0, name: registry_name(user))
  end

  def make_call(%{receiver: user} = data) do
    GenStage.call(registry_name(user), data)
  end

  defp registry_name(user), do: {:via, Registry, {Registry.User, user}}

  def handle_call(data, from, {queue, counter}) when counter > 0 do
    queue = :queue.in({from, data}, queue)

    send(self(), :new)

    {:noreply, [], {queue, counter - 1}}
  end

  def handle_call(%{type: :withdraw, is_send: true}, _from, {queue, counter}) do
    {:reply, {:error, :too_many_requests_to_sender}, [], {queue, counter}}
  end

  def handle_call(%{type: :deposit, is_send: true}, _from, {queue, counter}) do
    {:reply, {:error, :too_many_requests_to_receiver}, [], {queue, counter}}
  end

  def handle_call(_data, _from, {queue, counter}) do
    {:reply, {:error, :too_many_requests_to_user}, [], {queue, counter}}
  end

  def handle_info(:new, {queue, counter}) do
    case :queue.out(queue) do
      {{:value, data}, queue} -> {:noreply, [data], {queue, counter}}
      {:empty, queue} -> {:noreply, [], {queue, counter}}
    end
  end

  def handle_demand(demand, {queue, counter}) when demand > 0 do
    case :queue.out(queue) do
      {{:value, data}, queue} -> {:noreply, [data], {queue, demand + counter - 1}}
      {:empty, queue} -> {:noreply, [], {queue, demand + counter}}
    end
  end
end
