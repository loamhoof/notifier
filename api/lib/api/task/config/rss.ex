defmodule Api.Task.Config.RSS do
  import Api.Validation, only: [validate: 1]

  validate do
    @required ["feed"]

    string "feed"

    list "filters", of: :map do
      @required ["field", "pattern"]

      elem "field", of: ~w|title|
      regex "pattern"
    end
  end
end
