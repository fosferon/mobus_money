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
  end
end
