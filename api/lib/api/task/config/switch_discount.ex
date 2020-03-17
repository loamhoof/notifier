defmodule Api.Task.Config.SwitchDiscount do
  import Api.Validation, only: [validate: 1]

  validate do
    @required ["id", "country", "link"]

    string "id", regex: ~r/^\d+$/
    string "country"
    string "link"
  end
end
