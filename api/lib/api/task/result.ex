defmodule Api.Task.Result do
  use Ecto.Schema

  @derive {Jason.Encoder,
           only: [:id, :task_id, :body, :url, :notify_at, :sent_at, :acked_at, :inserted_at]}

  schema "task_results" do
    field :task_id, :id
    field :body, :string
    field :url, :string
    field :notify_at, :utc_datetime
    field :sent_at, :utc_datetime
    field :acked_at, :utc_datetime

    timestamps()
  end
end
