defmodule ApiWeb.V1.Task.AckController do
  use ApiWeb, :controller

  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query, only: [from: 2]

  alias Api.{Repo, Task.Result}

  @spec create(Plug.Conn.t(), %{required(String.t()) => String.t()}) :: Plug.Conn.t()
  def create(conn, params) do
    task_result = get_task_result(params)

    cond do
      is_nil(task_result) ->
        conn
        |> put_status(400)
        |> json(%{"message" => "No result yet"})

      not is_nil(task_result.acked_at) ->
        conn
        |> put_status(400)
        |> json(%{"message" => "Already acked"})

      is_nil(task_result.sent_at) ->
        conn
        |> put_status(400)
        |> json(%{"message" => "Cannot ack a result which has not been sent yet"})

      true ->
        acked_at = DateTime.utc_now() |> DateTime.truncate(:second)
        acked_with = get_body(conn)

        case ack(task_result, acked_at, acked_with) do
          {:ok, task_result} ->
            ApiWorker.EventManager.ack(
              ApiWorker.EventManager,
              task_result.task_id,
              acked_at,
              acked_with
            )

            json(conn, task_result)

          {:error, reason} ->
            conn
            |> put_status(400)
            |> json(reason)
        end
    end
  end

  @spec get_task_result(%{required(String.t()) => String.t()}) :: %Result{} | nil
  defp get_task_result(params)

  defp get_task_result(%{"task_id" => task_id}) do
    Repo.one(
      from r in Result,
        where: r.task_id == ^task_id,
        order_by: [desc: r.id],
        limit: 1
    )
  end

  defp get_task_result(%{"result_id" => result_id}) do
    Repo.get(Result, result_id)
  end

  @spec get_body(%Plug.Conn{}) :: term()
  defp get_body(%Plug.Conn{body_params: %{"_json" => json}}), do: json
  defp get_body(%Plug.Conn{body_params: json}) when json == %{}, do: nil
  defp get_body(%Plug.Conn{body_params: json}), do: json

  @spec ack(%Result{}, DateTime.t(), term()) :: Api.ok(%Result{}, String.t())
  defp ack(task_result, acked_at, acked_with) do
    result =
      task_result
      |> change(%{acked_at: acked_at, acked_with: Jason.encode!(acked_with)})
      |> Repo.update()

    case result do
      {:ok, task_result} -> {:ok, task_result}
      {:error, %{errors: errors}} -> {:error, inspect(errors)}
    end
  end
end
