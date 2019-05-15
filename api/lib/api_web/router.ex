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
      resources "/task_results", Task.ResultController, only: [:index, :show]

      scope "/tasks", Task, as: :task do
        resources "/:task_id/results", ResultController, only: [:index]
      end
    end
  end
end
