defmodule ExBanking do
  alias ExBanking.User.{UserSupervisor, Producer}

  @type banking_error ::
          {:error,
           :wrong_arguments
           | :user_already_exists
           | :user_does_not_exist
           | :not_enough_money
           | :sender_does_not_exist
           | :receiver_does_not_exist
           | :too_many_requests_to_user
           | :too_many_requests_to_sender
           | :too_many_requests_to_receiver}

  defguard is_valid_amount(value) when is_number(value) and value >= 0

  @spec create_user(user :: String.t()) :: :ok | banking_error
  def create_user(user) when is_binary(user) do
    UserSupervisor.start_child(user)
  end

  def create_user(_), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency)
      when is_binary(user) and is_valid_amount(amount) and is_binary(currency) do
    case UserSupervisor.producer_in_registry?(user) do
      true ->
        Producer.make_call(%{
          type: :deposit,
          receiver: user,
          amount: round(amount * 100),
          currency: currency
        })
        |> format_amounts

      false ->
        {:error, :user_does_not_exist}
    end
  end

  def deposit(_, _, _), do: {:error, :wrong_arguments}

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency)
      when is_binary(user) and is_valid_amount(amount) and is_binary(currency) do
    case UserSupervisor.producer_in_registry?(user) do
      true ->
        Producer.make_call(%{
          type: :withdraw,
          receiver: user,
          amount: round(amount * 100),
          currency: currency
        })
        |> format_amounts

      false ->
        {:error, :user_does_not_exist}
    end
  end

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number} | banking_error
  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    case UserSupervisor.producer_in_registry?(user) do
      true ->
        Producer.make_call(%{
          type: :get_balance,
          receiver: user,
          currency: currency
        })
        |> format_amounts

      false ->
        {:error, :user_does_not_exist}
    end
  end

  def get_balance(_, _), do: {:error, :wrong_arguments}

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_valid_amount(amount) and
             is_binary(currency) do
    with true <- check_sender(from_user),
         true <- check_receiver(to_user),
         {:ok, sender_balance} <-
           Producer.make_call(%{
             type: :withdraw,
             receiver: from_user,
             is_send: true,
             amount: round(amount * 100),
             currency: currency
           }),
         {:ok, receiver_balance} <-
           Producer.make_call(%{
             type: :deposit,
             receiver: to_user,
             is_send: true,
             amount: round(amount * 100),
             currency: currency
           }) do
      {:ok, sender_balance, receiver_balance}
      |> format_amounts
    end
  end

  def send(_, _, _, _), do: {:error, :wrong_arguments}

  defp check_sender(user) do
    if UserSupervisor.producer_in_registry?(user),
      do: true,
      else: {:error, :sender_does_not_exist}
  end

  defp check_receiver(user) do
    if UserSupervisor.producer_in_registry?(user),
      do: true,
      else: {:error, :receiver_does_not_exist}
  end

  defp format_amounts({:ok, value}),
    do: {:ok, value / 100}

  defp format_amounts({:ok, value1, value2}),
    do: {:ok, value1 / 100, value2 / 100}

  defp format_amounts({:error, _} = error), do: error
end
