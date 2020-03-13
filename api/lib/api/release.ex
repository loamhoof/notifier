defmodule Api.Release do
  @app :api

  @spec migrate() :: :ok
  def(migrate()) do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    :ok
  end

  @spec rollback(Ecto.Repo.t(), String.t()) :: :ok
  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
    :ok
  end

  @spec repos() :: list(Ecto.Repo.t())
  defp repos() do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
