defmodule ExBanking.User.UserSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def producer_in_registry?(name) do
    length(Registry.lookup(Registry.User, name)) > 0
  end

  def start_child(name) do
    case producer_in_registry?(name) do
      true ->
        {:error, :user_already_exists}

      _ ->
        DynamicSupervisor.start_child(__MODULE__, {ExBanking.User.Producer, name})
        DynamicSupervisor.start_child(__MODULE__, {ExBanking.User.Consumer, name})

        :ok
    end
  end

  @impl true
  def init(init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [init_arg]
    )
  end
end
