defmodule Api.Task.Config.Reminder do
  import Api.Validation, only: [validate: 1]

  validate do
    @required ["every", "description"]

    duration "every"
    string "description"
  end
end
