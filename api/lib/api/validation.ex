defmodule Api.Validation do
  @callback validate(value :: any()) :: [{[atom() | String.t() | non_neg_integer()], String.t()}]

  defmacro validate(do: nil), do: []

  defmacro validate(do: block) do
    quote do
      @behaviour unquote(__MODULE__)

      def validate(value) do
        Api.Validation.validate_map(value, [], do: unquote(block))
        |> List.wrap()
        |> List.flatten()
      end
    end
  end

  defmacro validate_block(_value, _ctx, do: nil), do: []

  defmacro validate_block(value, ctx, do: block) do
    exprs =
      case block do
        {:__block__, _, exprs} -> exprs
        expr when is_tuple(expr) -> [expr]
        expr -> raise "not a valid expression `#{expr}`"
      end

    new_block =
      Enum.map(exprs, fn
        {:@, _, [{type, _, args}]} ->
          args = if is_nil(args), do: [], else: args

          validator_f = "validate_#{type}" |> String.to_atom()

          unless macro_exported?(Api.Validation, validator_f, 2 + length(args)) do
            raise "unknown validator: `#{type}"
          end

          quote bind_quoted: [value: value, ctx: ctx], unquote: true do
            Api.Validation.unquote(validator_f)(value, ctx, unquote_splicing(args))
          end
        {type, _, [field | args]} ->
          validator_f = "validate_#{type}" |> String.to_atom()

          unless macro_exported?(Api.Validation, validator_f, 2 + length(args)) do
            raise "unknown type: `#{type}`"
          end

          quote bind_quoted: [value: value, ctx: ctx, field: field], unquote: true do
            case Map.fetch(value, field) do
              :error ->
                []

              {:ok, value} ->
                Api.Validation.unquote(validator_f)(value, ctx ++ [field], unquote_splicing(args))
            end
        end
      end)

    quote do
      unquote(new_block) |> List.flatten()
    end
  end

  defmacro validate_required(value, ctx, fields) do
    quote bind_quoted: [value: value, ctx: ctx, fields: fields] do
      fields
      |> Stream.filter(&Map.has_key?(value, &1))
      |> Enum.map(&{ctx, "no field #{&1}"})
    end
  end

  defmacro validate_map(value, ctx) do
    quote do
      Api.Validation.validate_map(unquote(value), unquote(ctx), [], do: nil)
    end
  end

  defmacro validate_map(value, ctx, do: block) do
    quote do
      Api.Validation.validate_map(unquote(value), unquote(ctx), [], do: unquote(block))
    end
  end

  defmacro validate_map(value, ctx, opts) do
    quote do
      Api.Validation.validate_map(unquote(value), unquote(ctx), unquote(opts), do: nil)
    end
  end

  defmacro validate_map(value, ctx, opts, do: block) do
    quote bind_quoted: [value: value, ctx: ctx, opts: opts], unquote: true do
      cond do
        not is_map(value) ->
          {ctx, "not a map"}

        true ->
          validators = %{}

          Api.Validation.validate_options(validators, opts) ++
            Api.Validation.validate_block(value, ctx, do: unquote(block))
      end
    end
  end

  defmacro validate_list(value, ctx, opts \\ []) do
    quote do
      Api.Validation.validate_list(unquote(value), unquote(ctx), unquote(opts), do: nil)
    end
  end

  defmacro validate_list(value, ctx, opts, do: block) do
    {list_opts, subtype_opts} = Enum.split_while(opts, &(not match?({:of, _}, &1)))

    validate_sublist =
      if length(subtype_opts) == 0 do
        []
      else
        [{:of, subtype} | subtype_opts] = subtype_opts
        validator_f = "validate_#{subtype}" |> String.to_atom()

        unless macro_exported?(Api.Validation, validator_f, 2 + length(subtype_opts)) do
          raise "unknown subtype: `#{subtype}`"
        end

        quote bind_quoted: [value: value, ctx: ctx, subtype: subtype, subtype_opts: subtype_opts],
              unquote: true do
          value
          |> Stream.with_index()
          |> Stream.map(fn {v, i} ->
            unless subtype == :map do
              Api.Validation.unquote(validator_f)(v, ctx ++ [i], subtype_opts)
            else
              Api.Validation.unquote(validator_f)(v, ctx ++ [i], subtype_opts, do: unquote(block))
            end
          end)
          |> Enum.find([], &(&1 != []))
          |> List.wrap()
        end
      end

    quote bind_quoted: [value: value, ctx: ctx, list_opts: list_opts],
          unquote: true do
      cond do
        not is_list(value) ->
          {ctx, "not a list"}

        true ->
          validators = %{
            >: {&(&1 >= length(value)), &{ctx, "length not > #{&1}"}},
            <: {&(&1 <= length(value)), &{ctx, "length not < #{&1}"}},
            <=: {&(&1 < length(value)), &{ctx, "length not <= #{&1}"}},
            >=: {&(&1 > length(value)), &{ctx, "length not >= #{&1}"}}
          }

          Api.Validation.validate_options(validators, list_opts) ++ unquote(validate_sublist)
      end
    end
  end

  defmacro validate_integer(value, ctx, opts \\ []) do
    quote bind_quoted: [value: value, ctx: ctx, opts: opts] do
      cond do
        not is_integer(value) ->
          {ctx, "not an integer"}

        true ->
          validators = %{
            >: {&(&1 >= value), &{ctx, "not > #{&1}"}},
            <: {&(&1 <= value), &{ctx, "not < #{&1}"}},
            <=: {&(&1 < value), &{ctx, "not <= #{&1}"}},
            >=: {&(&1 > value), &{ctx, "not >= #{&1}"}}
          }

          Api.Validation.validate_options(validators, opts)
      end
    end
  end

  defmacro validate_string(value, ctx, opts \\ []) do
    quote bind_quoted: [value: value, ctx: ctx, opts: opts] do
      cond do
        not is_binary(value) ->
          {ctx, "not a string"}

        true ->
          validators = %{}

          Api.Validation.validate_options(validators, opts)
      end
    end
  end

  defmacro validate_elem(value, ctx, [{:of, values} | opts]) do
    quote bind_quoted: [value: value, ctx: ctx, values: values, opts: opts] do
      cond do
        not Enum.member?(values, value) ->
          {ctx, "should be one of #{inspect(values)}"}

        true ->
          validators = %{}

          Api.Validation.validate_options(validators, opts)
      end
    end
  end

  defmacro validate_elem(_value, _ctx, _opts) do
    raise "missing elem values"
  end

  defmacro validate_regex(value, ctx, opts \\ []) do
    quote bind_quoted: [value: value, ctx: ctx, opts: opts] do
      case Regex.compile(value) do
        {:error, error} ->
          {ctx, "not a valid regex: #{inspect(error)}"}

        {:ok, _} ->
          validators = %{}

          Api.Validation.validate_options(validators, opts)
      end
    end
  end

  defmacro validate_duration(value, ctx, opts \\ []) do
    quote bind_quoted: [value: value, ctx: ctx, opts: opts] do
      Api.Validation.validate_integer(value, ctx, Keyword.put_new(opts, :>, 0))
    end
  end

  defmacro validate_options(validators, opts) do
    quote do
      unquote(opts)
      |> Enum.map(fn {opt_key, opt_value} ->
        case Map.fetch(unquote(validators), opt_key) do
          :error ->
            raise "unknown option #{opt_key}"

          {:ok, {cond_f, error_f}} ->
            if cond_f.(opt_value) do
              error_f.(opt_value)
            else
              []
            end
        end
      end)
      |> List.flatten()
    end
  end
end
