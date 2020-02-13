defmodule Api.Task.Config.SwitchDiscount do
  import Api.Validation, only: [validate: 1]

  validate do
    @required ["id", "country", "link"]

    integer "id", >: 0
    string "country"
    string "link"
  end
end
