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

  describe "validate_money/2" do
    test "accepts a valid, paired, non-negative amount" do
      changeset =
        %Budget{}
        |> Ecto.Changeset.cast(
          %{"budget_amount" => Decimal.new("19.99"), "budget_currency" => "EUR"},
          [:budget_amount, :budget_currency]
        )
        |> MobusMoney.Schema.validate_money(:budget)

      assert changeset.valid?
      assert changeset.errors == []
    end

    test "accepts a null/null pair" do
      changeset =
        %Budget{}
        |> Ecto.Changeset.cast(%{}, [:budget_amount, :budget_currency])
        |> MobusMoney.Schema.validate_money(:budget)

      assert changeset.valid?
    end

    test "rejects a half-set pair: amount set, currency nil" do
      changeset =
        %Budget{}
        |> Ecto.Changeset.cast(
          %{"budget_amount" => Decimal.new("19.99")},
          [:budget_amount, :budget_currency]
        )
        |> MobusMoney.Schema.validate_money(:budget)

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :budget_amount)
      assert Keyword.has_key?(changeset.errors, :budget_currency)
    end

    test "rejects a half-set pair: currency set, amount nil" do
      changeset =
        %Budget{}
        |> Ecto.Changeset.cast(%{"budget_currency" => "EUR"}, [:budget_amount, :budget_currency])
        |> MobusMoney.Schema.validate_money(:budget)

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :budget_amount)
      assert Keyword.has_key?(changeset.errors, :budget_currency)
    end

    test "rejects an unknown currency" do
      changeset =
        %Budget{}
        |> Ecto.Changeset.cast(
          %{"budget_amount" => Decimal.new("19.99"), "budget_currency" => "NOPE"},
          [:budget_amount, :budget_currency]
        )
        |> MobusMoney.Schema.validate_money(:budget)

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :budget_currency)
    end

    test "rejects a negative amount" do
      changeset =
        %Budget{}
        |> Ecto.Changeset.cast(
          %{"budget_amount" => Decimal.new("-0.01"), "budget_currency" => "EUR"},
          [:budget_amount, :budget_currency]
        )
        |> MobusMoney.Schema.validate_money(:budget)

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :budget_amount)

      # zero is a magnitude, not negative
      zero_changeset =
        %Budget{}
        |> Ecto.Changeset.cast(
          %{"budget_amount" => Decimal.new("0.00"), "budget_currency" => "EUR"},
          [:budget_amount, :budget_currency]
        )
        |> MobusMoney.Schema.validate_money(:budget)

      assert zero_changeset.valid?
    end
  end

  describe "read_money/2" do
    test "returns {:ok, nil} for a null/null pair" do
      assert MobusMoney.Schema.read_money(%Budget{}, :budget) == {:ok, nil}
    end

    test "returns {:ok, money} for a valid pair" do
      budget = %Budget{
        budget_amount: Decimal.new("19.99"),
        budget_currency: "EUR"
      }

      assert {:ok, money} = MobusMoney.Schema.read_money(budget, :budget)
      assert money == Money.new(:EUR, "19.99")
    end
  end
end
