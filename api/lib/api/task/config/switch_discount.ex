defmodule Api.Task.Config.SwitchDiscount do
  import Api.Validation, only: [validate: 1]

  validate do
    integer "id", >: 0
    string "country"
    string "link"
  end
end
