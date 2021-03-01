defmodule ExBanking.Store do
  def process_data(%{
        type: :deposit,
        receiver: receiver,
        amount: amount,
        currency: currency
      }) do
    balance =
      :ets.update_counter(__MODULE__, {receiver, currency}, amount, {{receiver, currency}, 0})

    {:ok, balance}
  end

  def process_data(%{
        type: :withdraw,
        receiver: receiver,
        amount: amount,
        currency: currency
      }) do
    case :ets.lookup(__MODULE__, {receiver, currency}) do
      [{_key, current_balance}] when amount > current_balance ->
        {:error, :not_enough_money}

      [{key, current_balance}] ->
        balance = current_balance - amount
        :ets.insert(__MODULE__, {key, balance})
        {:ok, balance}

      _ ->
        {:error, :not_enough_money}
    end
  end

  def process_data(%{
        type: :get_balance,
        receiver: receiver,
        currency: currency
      }) do
    case :ets.lookup(__MODULE__, {receiver, currency}) do
      [{_key, current_balance}] -> {:ok, current_balance}
      _ -> {:ok, 0}
    end
  end
end
