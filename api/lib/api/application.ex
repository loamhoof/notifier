defmodule Api.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Api.Repo,
      ApiWeb.Endpoint,
      ApiWorker.Supervisor
    ]

    opts = [strategy: :one_for_one, name: Api.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
