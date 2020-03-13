defmodule ApiWeb.V1.Task.ResultController do
  use ApiWeb, :controller

  import Ecto.Query, only: [from: 1, where: 2]

  alias Api.{Repo, Task.Result}

  @spec index(Plug.Conn.t(), %{}) :: Plug.Conn.t()
  def index(conn, params) do
    results =
      Result
      |> from()
      |> maybe_task_id_filter(params)
      |> Repo.all()

    json(conn, results)
  end

  @spec show(Plug.Conn.t(), %{required(String.t()) => String.t()}) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    case Repo.get(Result, id) do
      nil -> send_resp(conn, 404, "Not found")
      result -> json(conn, result)
    end
  end

  @spec delete(Plug.Conn.t(), %{required(String.t()) => String.t()}) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    case Repo.get(Result, id) do
      nil ->
        send_resp(conn, 404, "Not found")

      result ->
        Repo.delete(result)
        json(conn, result)
    end
  end

  defp maybe_task_id_filter(query, params) do
    case Map.fetch(params, "task_id") do
      {:ok, task_id} -> where(query, task_id: ^task_id)
      :error -> query
    end
  end
end
