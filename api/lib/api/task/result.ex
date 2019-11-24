defmodule Api.Task.Result do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:id, :task_id, :body, :url, :sent, :sent_at, :inserted_at]}

  schema "task_results" do
    field :task_id, :id
    field :body, :string
    field :url, :string
    field :sent, :boolean, default: false
    field :sent_at, :utc_datetime

    timestamps()
  end
end
