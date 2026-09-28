defmodule MobusMoney.SchemaTest do
  use ExUnit.Case, async: true

  defmodule Budget do
    use Ecto.Schema
    import MobusMoney.Schema, only: [money_fields: 1]

    embedded_schema do
      money_fields(:budget)
      field(:note, :string)
    end
  end

  describe "money_fields/1" do
    test "declares the <name>_amount and <name>_currency pair" do
      assert Budget.__schema__(:type, :budget_amount) == :decimal
      assert Budget.__schema__(:type, :budget_currency) == :string
      # the caller-chosen prefix is the only coupling: both columns derive
      # from one atom, `:budget`
      assert :budget_amount in Budget.__schema__(:fields)
      assert :budget_currency in Budget.__schema__(:fields)
    end

    test "does not disturb other fields" do
      assert Budget.__schema__(:type, :note) == :string
    end
  end
end
