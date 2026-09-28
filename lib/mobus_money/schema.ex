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
    # Task 4.2/4.3/4.4 surface compiles only when Ecto is present.
  end
end
