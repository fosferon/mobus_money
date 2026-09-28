defmodule MobusMoney.CurrencyTest do
  use ExUnit.Case, async: true

  alias MobusMoney.Currency

  describe "valid?/1" do
    test "accepts known ISO 4217 codes as atoms and binaries" do
      assert Currency.valid?(:EUR)
      assert Currency.valid?(:USD)
      assert Currency.valid?(:JPY)
      assert Currency.valid?(:XXX)
      assert Currency.valid?("EUR")
      # lowercase accepted per ex_money's own behavior (verified, not assumed)
      assert Currency.valid?("eur")
    end

    test "rejects a non-code string and an unknown atom" do
      refute Currency.valid?("not-a-code")
      refute Currency.valid?(:NOPE)
      refute Currency.valid?("")
    end
  end

  describe "exponent/1" do
    test "matches ex_money's registry for 0, 2, and 3-decimal currencies" do
      # 0 minor units
      assert Currency.exponent(:JPY) == 0
      # 2 minor units
      assert Currency.exponent(:EUR) == 2
      assert Currency.exponent(:USD) == 2
      assert Currency.exponent(:GBP) == 2
      # 3 minor units; IQD diverges between CLDR digits (0) and ISO (3) —
      # the ISO figure is what this library reports
      assert Currency.exponent(:BHD) == 3
      assert Currency.exponent(:IQD) == 3
    end

    test "returns nil for an unknown code" do
      assert Currency.exponent(:NOPE) == nil
      assert Currency.exponent("not-a-code") == nil
    end
  end

  describe "all_codes/0" do
    test "returns ex_money's full tender set, uncurated" do
      codes = Currency.all_codes()

      assert is_list(codes) and codes != []
      assert :EUR in codes and :USD in codes and :JPY in codes and :IQD in codes
      assert Enum.all?(codes, &is_atom/1)
    end
  end

  describe "default_rounding_mode/0" do
    test "returns the house :half_up, not ex_money's native :half_even" do
      assert Currency.default_rounding_mode() == :half_up

      # Proves the assertion checks the OVERRIDE, not merely that some mode
      # comes back: it must differ from ex_money's own native default
      # (Money.round/2's @default_rounding_mode is :half_even).
      assert Currency.default_rounding_mode() != :half_even

      assert Money.round(Money.new(:JPY, "100.5"),
               rounding_mode: Currency.default_rounding_mode()
             ) ==
               Money.new(:JPY, "101")
    end
  end
end
