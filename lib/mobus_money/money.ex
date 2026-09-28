defmodule MobusMoney.Money do
  @moduledoc """
  A currency-carrying money value type wrapping `Money.t()` (ex_money).

  The amount and its currency always travel together; a float amount and a
  `nil` amount are refused with a reason atom rather than converted or
  zeroed; mixed-currency arithmetic errors instead of converting (design D1).

  This module returns the money values of `ex_money` directly — `Money.t()`
  IS this library's value type — but the contracts around them (reason
  atoms, structured currency-mismatch errors, the house rounding default)
  are this library's own, intercepted before any delegation.

  ## Construction

      iex> MobusMoney.Money.new("19.99", :EUR)
      {:ok, Money.new(:EUR, "19.99")}

      iex> MobusMoney.Money.new(19.99, :EUR)
      {:error, :float_amount}

      iex> MobusMoney.Money.new(nil, :EUR)
      {:error, :nil_amount}
  """

  alias MobusMoney.InvalidMoneyError

  @typedoc "A money value: `Money.t()` from ex_money, used directly."
  @type t :: Money.t()

  @typedoc "Why a money value could not be constructed."
  @type error_reason ::
          :float_amount | :nil_amount | :unparseable_amount | :unknown_currency

  @doc """
  Builds a money value from `amount` and `currency_code`.

  Returns `{:ok, money}` or `{:error, reason}` where `reason` is one of:

    * `:float_amount` — a float amount is refused, not silently converted
    * `:nil_amount` — a `nil` amount is refused, NOT treated as zero
    * `:unparseable_amount` — the amount is not an exact decimal value
    * `:unknown_currency` — the code is not in the ISO 4217 registry

  `amount` may be an integer, a `Decimal`, or a decimal string; `nil` and
  floats are matched by this library's own function heads before `ex_money`
  is ever called — this contract is ours, not a translation of ex_money's
  exception text.
  """
  @spec new(integer() | Decimal.t() | String.t() | nil, Money.Currency.code()) ::
          {:ok, t()} | {:error, error_reason()}
  def new(nil, _currency_code), do: {:error, :nil_amount}

  def new(amount, _currency_code) when is_float(amount), do: {:error, :float_amount}

  def new(amount, currency_code) do
    case Money.new(currency_code, amount) do
      %Money{} = money ->
        {:ok, money}

      {:error, {Money.UnknownCurrencyError, _}} ->
        {:error, :unknown_currency}

      {:error, _} ->
        {:error, :unparseable_amount}
    end
  end

  @doc """
  Like `new/2`, but raises `MobusMoney.InvalidMoneyError` (carrying the same
  reason atom `new/2` returns) instead of returning an error tuple.
  """
  @spec new!(integer() | Decimal.t() | String.t() | nil, Money.Currency.code()) ::
          t() | no_return()
  def new!(amount, currency_code) do
    case new(amount, currency_code) do
      {:ok, money} -> money
      {:error, reason} -> raise InvalidMoneyError, reason: reason
    end
  end
end
