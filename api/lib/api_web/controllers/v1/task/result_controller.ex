defmodule ApiWeb.V1.Task.ResultController do
  use ApiWeb, :controller

  import Ecto.Query, only: [from: 1, where: 2]

  alias Api.{Repo, Task.Result}

  def index(conn, params) do
    results =
      from(Result)
      |> maybe_task_id_filter(params)
      |> Repo.all()

    json(conn, results)
  end

  def show(conn, %{"id" => id}) do
    case Repo.get(Result, id) do
      nil -> Plug.Conn.send_resp(conn, 404, "Not found")
      result -> json(conn, result)
    end
  end

  defp maybe_task_id_filter(query, params) do
    case Map.fetch(params, "task_id") do
      {:ok, task_id} -> where(query, task_id: ^task_id)
      :error -> query
    end
  end
end
