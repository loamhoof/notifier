defmodule Api.Task.Result do
  use Ecto.Schema
  @derive {Jason.Encoder, only: [:id, :task_id, :load]}

  schema "task_results" do
    field :task_id, :id
    field :load, :map
    field :sent, :boolean, default: false
    field :error, :boolean, default: false
    field :error_reason, :string
    field :error_reported, :boolean, default: false

    timestamps()
  end
end
