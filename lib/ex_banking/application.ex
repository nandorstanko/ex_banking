defmodule ExBanking.Application do
  use Application

  def start(_type, _args) do
    children = [
      {ExBanking.User.UserSupervisor, []},
      %{
        id: Eternal,
        start:
          {Eternal, :start_link,
           [ExBanking.Store, [:set, {:read_concurrency, true}, {:write_concurrency, true}]]}
      },
      {Registry, keys: :unique, name: Registry.User}
    ]

    opts = [strategy: :one_for_one, name: ExBanking.Application]
    Supervisor.start_link(children, opts)
  end
end
