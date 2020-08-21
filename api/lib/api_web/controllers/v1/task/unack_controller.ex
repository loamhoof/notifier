defmodule ApiWeb.V1.Task.UnackController do
  use ApiWeb, :controller

  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query, only: [from: 2]

  alias Api.{Repo, Task.Result}

  @spec create(Plug.Conn.t(), %{required(String.t()) => String.t()}) :: Plug.Conn.t()
  def create(conn, params) do
    task_result =
      case params do
        %{"task_id" => task_id} ->
          Repo.one(
            from r in Result,
              where: r.task_id == ^task_id,
              order_by: [desc: r.id],
              limit: 1
          )

        %{"result_id" => result_id} ->
          Repo.get(Result, result_id)
      end

    cond do
      is_nil(task_result) ->
        conn
        |> put_status(400)
        |> json(%{"message" => "No result yet"})

      is_nil(task_result.acked_at) ->
        conn
        |> put_status(400)
        |> json(%{"message" => "Not acked"})

      true ->
        result =
          task_result
          |> change(%{acked_at: nil, acked_with: nil})
          |> Repo.update()

        case result do
          {:ok, task_result} ->
            ApiWorker.EventManager.unack(ApiWorker.EventManager, task_result.task_id)
            json(conn, task_result)

          {:error, %{errors: errors}} ->
            conn
            |> put_status(400)
            |> json(errors)
        end
    end
  end
end
