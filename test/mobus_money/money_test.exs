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

  describe "zero/1" do
    test "returns {:ok, zero money} for a known currency" do
      assert MobusMoney.Money.zero(:EUR) == {:ok, Money.new(:EUR, 0)}
    end

    test "returns {:error, :unknown_currency} for an unknown code" do
      assert MobusMoney.Money.zero(:NOPE) == {:error, :unknown_currency}
    end
  end

  describe "add/2, sub/2, compare/2" do
    test "same-currency operands delegate to ex_money" do
      assert MobusMoney.Money.add(Money.new(:EUR, "1.10"), Money.new(:EUR, "2.20")) ==
               {:ok, Money.new(:EUR, "3.30")}

      assert MobusMoney.Money.sub(Money.new(:EUR, "3.30"), Money.new(:EUR, "1.10")) ==
               {:ok, Money.new(:EUR, "2.20")}

      assert MobusMoney.Money.compare(Money.new(:EUR, "1.10"), Money.new(:EUR, "2.20")) ==
               :lt

      assert MobusMoney.Money.compare(Money.new(:EUR, "2.20"), Money.new(:EUR, "2.20")) ==
               :eq

      assert MobusMoney.Money.compare(Money.new(:EUR, "3.30"), Money.new(:EUR, "2.20")) ==
               :gt
    end

    test "mixed currencies error with both codes, never a converted value" do
      mismatch = {:error, {:currency_mismatch, :EUR, :USD}}

      assert MobusMoney.Money.add(Money.new(:EUR, 1), Money.new(:USD, 1)) == mismatch
      assert MobusMoney.Money.sub(Money.new(:EUR, 1), Money.new(:USD, 1)) == mismatch
      assert MobusMoney.Money.compare(Money.new(:EUR, 1), Money.new(:USD, 1)) == mismatch
    end
  end

  describe "sum/2" do
    test "folds a same-currency list into one total" do
      assert MobusMoney.Money.sum([Money.new(:EUR, "1.10"), Money.new(:EUR, "2.20")], :EUR) ==
               {:ok, Money.new(:EUR, "3.30")}
    end
  end

  describe "mult/2" do
    test "multiplies by an integer or Decimal" do
      assert MobusMoney.Money.mult(Money.new(:EUR, "1.25"), 3) ==
               {:ok, Money.new(:EUR, "3.75")}

      assert MobusMoney.Money.mult(Money.new(:EUR, "1.25"), Decimal.new("0.5")) ==
               {:ok, Money.new(:EUR, "0.625")}
    end
  end

  describe "negative?/1 and zero?/1" do
    test "classify the value" do
      assert MobusMoney.Money.negative?(Money.new(:EUR, "-1.00"))
      refute MobusMoney.Money.negative?(Money.new(:EUR, "1.00"))

      assert MobusMoney.Money.zero?(Money.new(:EUR, 0))
      refute MobusMoney.Money.zero?(Money.new(:EUR, "0.01"))
    end
  end

  describe "round/2" do
    test "defaults to the house :half_up mode" do
      # JPY has 0 minor units: 100.5 rounds UP under the house default
      assert MobusMoney.Money.round(Money.new(:JPY, "100.5")) == Money.new(:JPY, "101")
    end

    test "accepts an explicit mode override" do
      assert MobusMoney.Money.round(Money.new(:JPY, "100.5"), :half_even) ==
               Money.new(:JPY, "100")

      assert MobusMoney.Money.round(Money.new(:EUR, "1.005"), :half_even) ==
               Money.new(:EUR, "1.00")
    end
  end

  describe "format/1" do
    test "returns {:ok, string} for a 2-decimal currency" do
      assert {:ok, s} = MobusMoney.Money.format(Money.new(:EUR, 1234))
      assert is_binary(s) and s =~ "1,234.00"
    end

    test "returns {:ok, string} for a 0-decimal currency" do
      assert {:ok, s} = MobusMoney.Money.format(Money.new(:JPY, 1234))
      assert is_binary(s) and s =~ "1,234"
      refute s =~ "1,234."
    end
  end

  describe "to_integer_exp/1 and from_integer/2" do
    test "returns minor units with the negative-digit-count exponent" do
      assert {:USD, 20000, -2, _remainder} =
               MobusMoney.Money.to_integer_exp(Money.new(:USD, "200.00"))
    end

    test "rounds to the minor unit with the house mode" do
      # 0.005 USD: half_up -> 1 minor unit; ex_money's native half_even -> 0
      assert {:USD, 1, -2, _} = MobusMoney.Money.to_integer_exp(Money.new(:USD, "0.005"))

      assert {:USD, 0, -2, _} =
               Money.to_integer_exp(Money.new(:USD, "0.005"), rounding_mode: :half_even)
    end

    test "from_integer/2 reads the per-currency exponent from the registry" do
      assert MobusMoney.Money.from_integer(20000, :USD) == Money.new(:USD, "200.00")
      assert MobusMoney.Money.from_integer(20012, :IQD) == Money.new(:IQD, "20.012")
    end
  end
end
