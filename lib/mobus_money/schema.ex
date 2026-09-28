defmodule MobusMoney.Schema do
  @moduledoc """
  An optional two-column storage-pair convention for persisted money
  (design D5).

  `money_fields/1` declares an `<name>_amount` + `<name>_currency` column
  pair on an Ecto schema, `validate_money/2` enforces the pair's contract at
  the changeset boundary, and `read_money/2` builds one
  `MobusMoney.Money` value back from the two columns.

  Ecto is an **optional** dependency of this library: when Ecto is not
  present, this module compiles with no functions — the rest of the library
  is unaffected (guarded via `Code.ensure_loaded?/1` at the module boundary).
  A consumer needing only the value type and arithmetic never pulls Ecto in.

  ## Migration shape

  The declared pair is stored as plain columns — two columns, not a composite
  type or `jsonb` (design D5 rejects both):

      alter table(:budgets) do
        add :budget_amount,   :numeric, precision: 28, scale: 8
        add :budget_currency, :varchar, size: 3
      end

  Scale 8, not 2: per-token provider prices are sub-cent at the small-model
  end (15¢ per million tokens is 1.5e-7 dollars per token).
  """

  if Code.ensure_loaded?(Ecto) do
    @doc """
    Declares the `<name>_amount` (`:decimal`, migration `numeric(28,8)`) and
    `<name>_currency` (`:string`, migration `varchar(3)`) field pair on an
    Ecto schema, where `name` is the atom prefix the caller chooses.

    Call it inside a `schema`/`embedded_schema` block, with the macro
    imported:

        defmodule Budget do
          use Ecto.Schema
          import MobusMoney.Schema, only: [money_fields: 1]

          schema "budgets" do
            money_fields :budget
            # -> budget_amount   :decimal (numeric(28,8) in the migration)
            # -> budget_currency :string  (varchar(3) in the migration)
          end
        end

    See the moduledoc for the migration shape.
    """
    defmacro money_fields(name) when is_atom(name) do
      quote do
        field(:"#{unquote(name)}_amount", :decimal)
        field(:"#{unquote(name)}_currency", :string)
      end
    end

    @doc """
    Validates the `name` pair on a changeset: both columns set or both nil
    (pairing), the currency a known ISO 4217 code (per
    `MobusMoney.Currency.valid?/1`), and the amount non-negative.

    Non-negativity is scoped to this persisted pair deliberately (design
    D5): every surveyed holding is a magnitude (a budget cap, a usage cost,
    a spend total), never a signed balance — a signed-arithmetic bug
    reaching a persisted magnitude column undetected is exactly what this
    rejects. `name` is the same atom prefix `money_fields/1` declared.
    """
    def validate_money(%Ecto.Changeset{} = changeset, name) when is_atom(name) do
      amount_field = field_name(name, :amount)
      currency_field = field_name(name, :currency)
      amount = Ecto.Changeset.get_field(changeset, amount_field)
      currency = Ecto.Changeset.get_field(changeset, currency_field)

      changeset
      |> validate_pairing(amount_field, currency_field, amount, currency)
      |> validate_registry(currency_field, currency)
      |> validate_non_negative(amount_field, amount)
    end

    defp validate_pairing(changeset, amount_field, currency_field, amount, currency) do
      case {amount, currency} do
        {nil, nil} ->
          changeset

        {nil, _currency} ->
          changeset
          |> Ecto.Changeset.add_error(amount_field, "must be set together with #{currency_field}")
          |> Ecto.Changeset.add_error(currency_field, "must be set together with #{amount_field}")

        {_amount, nil} ->
          changeset
          |> Ecto.Changeset.add_error(amount_field, "must be set together with #{currency_field}")
          |> Ecto.Changeset.add_error(currency_field, "must be set together with #{amount_field}")

        {_amount, _currency} ->
          changeset
      end
    end

    defp validate_registry(changeset, _currency_field, nil), do: changeset

    defp validate_registry(changeset, currency_field, currency) do
      if MobusMoney.Currency.valid?(currency) do
        changeset
      else
        Ecto.Changeset.add_error(
          changeset,
          currency_field,
          "is not a valid ISO 4217 currency code"
        )
      end
    end

    defp validate_non_negative(changeset, _amount_field, nil), do: changeset

    defp validate_non_negative(changeset, amount_field, amount) do
      if negative?(amount) do
        Ecto.Changeset.add_error(changeset, amount_field, "must be non-negative")
      else
        changeset
      end
    end

    defp negative?(%Decimal{} = amount), do: Decimal.negative?(amount)
    defp negative?(amount) when is_integer(amount), do: amount < 0

    @doc """
    Builds one `MobusMoney.Money` from the `name` pair on a schema struct.

    Returns `{:ok, nil}` for a null/null pair, `{:ok, money}` for a set
    pair, and `{:error, {:half_set_pair, missing_field}}` — where
    `missing_field` is `:amount` or `:currency`, whichever column is nil —
    for a pair with exactly one column set, NEVER a raise. A half-set pair
    is reachable outside `validate_money/2`'s reach (raw SQL, a migration
    backfill, a hand-written fixture); a named error is strictly better
    than an unreachable-in-theory crash (design D5, PE-3 fold).
    """
    def read_money(%{__struct__: _} = struct, name) when is_atom(name) do
      amount = Map.get(struct, field_name(name, :amount))
      currency = Map.get(struct, field_name(name, :currency))

      case {amount, currency} do
        {nil, nil} ->
          {:ok, nil}

        {nil, _currency} ->
          {:error, {:half_set_pair, :amount}}

        {_amount, nil} ->
          {:error, {:half_set_pair, :currency}}

        {amount, currency} ->
          MobusMoney.Money.new(amount, currency)
      end
    end

    defp field_name(name, :amount), do: :"#{name}_amount"
    defp field_name(name, :currency), do: :"#{name}_currency"
  end
end
