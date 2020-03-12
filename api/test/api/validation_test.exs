defmodule Api.ValidationTest do
  use ExUnit.Case, async: true

  setup do
    module = Module.safe_concat(__MODULE__, Validator)

    :code.delete(module)
    :code.purge(module)

    :ok
  end

  test "empty validator" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
      end
    end

    errors = Validator.validate(%{})
    assert [] = errors
  end

  test "required" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        @required [:foo]
      end
    end

    errors = Validator.validate(%{foo: :bar})
    assert [] = errors

    errors = Validator.validate(%{})
    assert [{[], _}] = errors
  end

  test "string" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        string :foo
      end
    end

    errors = Validator.validate(%{:foo => "bar"})
    assert [] = errors

    errors = Validator.validate(%{:foo => :bar})
    assert [{[:foo], _}] = errors
  end

  test "returns all errors" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        string :foo
        string :bar
      end
    end

    errors = Validator.validate(%{foo: :foo, bar: :bar})
    assert [{[:foo], _}, {[:bar], _}] = errors
  end

  test "integer" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        integer :foo
      end
    end

    errors = Validator.validate(%{:foo => 1})
    assert [] = errors

    errors = Validator.validate(%{:foo => :NaN})
    assert [{[:foo], _}] = errors
  end

  test "integer: >" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        integer :foo, >: 0
      end
    end

    errors = Validator.validate(%{:foo => 1})
    assert [] = errors

    errors = Validator.validate(%{:foo => 0})
    assert [{[:foo], _}] = errors
  end

  test "integer: >=" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        integer :foo, >=: 0
      end
    end

    errors = Validator.validate(%{:foo => 0})
    assert [] = errors

    errors = Validator.validate(%{:foo => 1})
    assert [] = errors

    errors = Validator.validate(%{:foo => -1})
    assert [{[:foo], _}] = errors
  end

  test "integer: <" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        integer :foo, <: 0
      end
    end

    errors = Validator.validate(%{:foo => -1})
    assert [] = errors

    errors = Validator.validate(%{:foo => 0})
    assert [{[:foo], _}] = errors
  end

  test "integer: <=" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        integer :foo, <=: 0
      end
    end

    errors = Validator.validate(%{:foo => 0})
    assert [] = errors

    errors = Validator.validate(%{:foo => -1})
    assert [] = errors

    errors = Validator.validate(%{:foo => 1})
    assert [{[:foo], _}] = errors
  end

  test "elem" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        elem :foo, of: [:bar]
      end
    end

    errors = Validator.validate(%{:foo => :bar})
    assert [] = errors

    errors = Validator.validate(%{:foo => :foo})
    assert [{[:foo], _}] = errors
  end

  test "regex" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        regex :foo
      end
    end

    errors = Validator.validate(%{:foo => ".+"})
    assert [] = errors

    errors = Validator.validate(%{:foo => "+"})
    assert [{[:foo], _}] = errors

    errors = Validator.validate(%{:foo => :bar})
    assert [{[:foo], _}] = errors
  end

  test "duration" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        duration :foo
      end
    end

    errors = Validator.validate(%{:foo => 1})
    assert [] = errors

    errors = Validator.validate(%{:foo => 0})
    assert [{[:foo], _}] = errors

    errors = Validator.validate(%{:foo => :bar})
    assert [{[:foo], _}] = errors
  end

  test "map" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        map :foo
      end
    end

    errors = Validator.validate(%{:foo => %{}})
    assert [] = errors

    errors = Validator.validate(%{:foo => :bar})
    assert [{[:foo], _}] = errors
  end

  test "map with block" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        map :foo do
          @required [:bar]
        end
      end
    end

    errors = Validator.validate(%{:foo => %{bar: :bar}})
    assert [] = errors

    errors = Validator.validate(%{:foo => %{}})
    assert [{[:foo], _}] = errors
  end

  test "list" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        list :foo
      end
    end

    errors = Validator.validate(%{:foo => []})
    assert [] = errors

    errors = Validator.validate(%{:foo => :bar})
    assert [{[:foo], _}] = errors
  end

  test "list: >" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        list :foo, >: 0
      end
    end

    errors = Validator.validate(%{:foo => [:bar]})
    assert [] = errors

    errors = Validator.validate(%{:foo => []})
    assert [{[:foo], _}] = errors
  end

  test "list: >=" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        list :foo, >=: 1
      end
    end

    errors = Validator.validate(%{:foo => [:foo, :bar]})
    assert [] = errors

    errors = Validator.validate(%{:foo => [:bar]})
    assert [] = errors

    errors = Validator.validate(%{:foo => []})
    assert [{[:foo], _}] = errors
  end

  test "list: <" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        list :foo, <: 1
      end
    end

    errors = Validator.validate(%{:foo => []})
    assert [] = errors

    errors = Validator.validate(%{:foo => [:bar]})
    assert [{[:foo], _}] = errors
  end

  test "list: <=" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        list :foo, <=: 1
      end
    end

    errors = Validator.validate(%{:foo => []})
    assert [] = errors

    errors = Validator.validate(%{:foo => [:bar]})
    assert [] = errors

    errors = Validator.validate(%{:foo => [:foo, :bar]})
    assert [{[:foo], _}] = errors
  end

  test "list subtype" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        list :foo, of: :integer
      end
    end

    errors = Validator.validate(%{:foo => [0]})
    assert [] = errors

    errors = Validator.validate(%{:foo => [0, :foo]})
    assert [{[:foo, 1], _}] = errors
  end

  test "list with block" do
    defmodule Validator do
      import Api.Validation, only: [validate: 1]

      validate do
        list :foo, of: :map do
          @required [:bar]
        end
      end
    end

    errors = Validator.validate(%{:foo => [%{bar: :bar}]})
    assert [] = errors

    errors = Validator.validate(%{:foo => [%{}]})
    assert [{[:foo, 0], _}] = errors
  end
end
