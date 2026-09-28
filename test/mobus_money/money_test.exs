defmodule MobusMoney.MoneyTest do
  use ExUnit.Case, async: true

  alias MobusMoney.InvalidMoneyError

  # `Money` below is ex_money's struct module: MobusMoney.Money is a thin
  # wrapper with no struct of its own — Money.t() IS this library's value
  # type (design D1) — so values are matched as %Money{} directly.

  describe "new/2" do
    test "builds a money value from an integer, Decimal, and decimal string" do
      assert {:ok, %Money{} = m} = MobusMoney.Money.new(1999, :EUR)
      assert m == Money.new(:EUR, 1999)

      assert {:ok, dm} = MobusMoney.Money.new(Decimal.new("19.99"), :USD)
      assert dm == Money.new(:USD, "19.99")

      assert {:ok, sm} = MobusMoney.Money.new("19.99", :EUR)
      assert sm == Money.new(:EUR, "19.99")
    end

    test "refuses a float amount with :float_amount" do
      assert MobusMoney.Money.new(19.99, :EUR) == {:error, :float_amount}
      assert MobusMoney.Money.new(0.0, :EUR) == {:error, :float_amount}
    end

    test "refuses a nil amount with :nil_amount, never treating it as zero" do
      assert MobusMoney.Money.new(nil, :EUR) == {:error, :nil_amount}

      assert {:ok, zero} = MobusMoney.Money.new(0, :EUR)
      assert Money.zero?(zero)
      # nil is a different fact from a real zero: distinct results
      refute MobusMoney.Money.new(nil, :EUR) == {:ok, zero}
    end

    test "refuses an unknown currency with :unknown_currency" do
      assert MobusMoney.Money.new(100, :NOPE) == {:error, :unknown_currency}
      assert MobusMoney.Money.new("10.00", "NOPE") == {:error, :unknown_currency}
    end

    test "refuses an unparseable amount with :unparseable_amount" do
      assert MobusMoney.Money.new("abc", :USD) == {:error, :unparseable_amount}
    end

    test "accepts lowercase codes per ex_money's own behavior" do
      assert {:ok, m} = MobusMoney.Money.new(100, "usd")
      assert m == Money.new(:USD, 100)
    end
  end

  describe "new!/2" do
    test "returns the money value on success" do
      assert MobusMoney.Money.new!("19.99", :EUR) == Money.new(:EUR, "19.99")
    end

    test "raises InvalidMoneyError with the reason from new/2" do
      assert_raise InvalidMoneyError, ~r/:float_amount/, fn ->
        MobusMoney.Money.new!(1.5, :EUR)
      end

      assert_raise InvalidMoneyError, ~r/:nil_amount/, fn ->
        MobusMoney.Money.new!(nil, :EUR)
      end

      assert_raise InvalidMoneyError, ~r/:unknown_currency/, fn ->
        MobusMoney.Money.new!(100, :NOPE)
      end

      assert_raise InvalidMoneyError, ~r/:unparseable_amount/, fn ->
        MobusMoney.Money.new!("abc", :EUR)
      end
    end
  end
end
