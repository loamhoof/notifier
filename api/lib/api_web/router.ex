defmodule ApiWeb.Router do
  use ApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    # plug ApiWeb.Plug.Authenticate
  end

  scope "/api", ApiWeb do
    pipe_through :api

    scope "/v1", V1, as: :v1 do
      resources "/users", UserController, except: [:edit, :new]
      resources "/tasks", TaskController, except: [:edit, :new]
      resources "/task_results", Task.ResultController, only: [:index, :show, :delete]
      resources "/task_results/:result_id/ack", Task.AckController, only: [:create]
      resources "/task_results/:result_id/unack", Task.UnackController, only: [:create]

      scope "/tasks", Task, as: :task do
        resources "/:task_id/results", ResultController, only: [:index]
        resources "/:task_id/last_result", LastResultController, only: [:index]
        resources "/:task_id/ack", AckController, only: [:create]
        resources "/:task_id/unack", UnackController, only: [:create]
      end
    end
  end
end
