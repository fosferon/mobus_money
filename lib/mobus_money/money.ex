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

  @typedoc """
  A rounding mode passed through to `Money.round/2`. ex_money defines no
  public type for it — modes are Cldr's; the house default is `:half_up`
  (`MobusMoney.Currency.default_rounding_mode/0`).
  """
  @type rounding_mode :: atom()

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
  @spec new(integer() | Decimal.t() | String.t() | nil, Money.currency_reference()) ::
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
  @spec new!(integer() | Decimal.t() | String.t() | nil, Money.currency_reference()) ::
          t() | no_return()
  def new!(amount, currency_code) do
    case new(amount, currency_code) do
      {:ok, money} -> money
      {:error, reason} -> raise InvalidMoneyError, reason: reason
    end
  end

  @doc """
  Returns the zero amount of `currency_code`.

  `Money.zero/1` returns a bare money value on success but an error tuple
  for an unknown code; this function normalizes both into the same
  two-shape contract as `new/2`: `{:ok, money}` | `{:error, :unknown_currency}`.
  """
  @spec zero(Money.currency_reference()) :: {:ok, t()} | {:error, :unknown_currency}
  def zero(currency_code) do
    case Money.zero(currency_code) do
      %Money{} = money -> {:ok, money}
      {:error, _} -> {:error, :unknown_currency}
    end
  end

  @doc """
  Adds two money values of the SAME currency: `{:ok, sum}`.

  Different currencies return `{:error, {:currency_mismatch, code_a,
  code_b}}` — produced by this library's own check of both operands'
  currencies BEFORE any delegation, never by translating ex_money's
  `{:error, {ArgumentError, prose}}`. No conversion is ever performed.
  """
  @spec add(t(), t()) :: {:ok, t()} | {:error, {:currency_mismatch, atom(), atom()}}
  def add(%Money{currency: c} = a, %Money{currency: c} = b), do: Money.add(a, b)

  def add(%Money{currency: ca}, %Money{currency: cb}),
    do: {:error, {:currency_mismatch, ca, cb}}

  @doc """
  Subtracts `b` from `a`; same currency-check-first contract as `add/2`.
  """
  @spec sub(t(), t()) :: {:ok, t()} | {:error, {:currency_mismatch, atom(), atom()}}
  def sub(%Money{currency: c} = a, %Money{currency: c} = b), do: Money.sub(a, b)

  def sub(%Money{currency: ca}, %Money{currency: cb}),
    do: {:error, {:currency_mismatch, ca, cb}}

  @doc """
  Compares two money values of the SAME currency: `:lt`, `:eq`, or `:gt`.

  Different currencies return `{:error, {:currency_mismatch, code_a,
  code_b}}`, same contract as `add/2` — never a converted comparison.
  """
  @spec compare(t(), t()) ::
          :lt | :eq | :gt | {:error, {:currency_mismatch, atom(), atom()}}
  def compare(%Money{currency: c} = a, %Money{currency: c} = b), do: Money.compare(a, b)

  def compare(%Money{currency: ca}, %Money{currency: cb}),
    do: {:error, {:currency_mismatch, ca, cb}}

  @doc """
  Folds `money_list` into one total denominated in `currency`, without
  converting any element.

  Any element whose currency differs from `currency` halts the fold
  immediately with this library's own `{:error, {:currency_mismatch,
  code_a, code_b}}`. An unknown `currency` returns `{:error,
  :unknown_currency}` before the list is touched (the seed is validated
  first). An empty list returns the zero of `currency`, never a crash.

  Never delegates to `Money.sum/2` — its second argument is exchange rates
  and it converts via `to_currency/3`, which this library must never do.
  """
  @spec sum([t()], Money.currency_reference()) ::
          {:ok, t()}
          | {:error, :unknown_currency}
          | {:error, {:currency_mismatch, atom(), atom()}}
  def sum(money_list, currency) do
    case zero(currency) do
      {:error, _} = err ->
        err

      {:ok, seed} ->
        Enum.reduce_while(money_list, {:ok, seed}, fn m, {:ok, acc} ->
          case add(acc, m) do
            {:ok, _} = ok -> {:cont, ok}
            {:error, _} = err -> {:halt, err}
          end
        end)
    end
  end

  @doc """
  Multiplies a money value by `number` (integer or `Decimal`).

  A float multiplier returns `{:error, :float_amount}` — the same no-float
  posture as `new/2`. Note the guard is entirely this library's own:
  `Money.mult/2` itself accepts floats (`Decimal.from_float/1`), so nothing
  upstream enforces it. A non-numeric multiplier is outside this
  function's spec'd domain and surfaces ex_money's own
  `{:error, {ArgumentError, _}}` from the delegation.
  """
  @spec mult(t(), integer() | Decimal.t()) :: {:ok, t()} | {:error, :float_amount}
  def mult(%Money{} = _money, number) when is_float(number), do: {:error, :float_amount}

  def mult(%Money{} = money, number), do: Money.mult(money, number)

  @doc """
  Returns `true` when the money value is strictly negative.

  Negatives exist in-memory (e.g. `sub/2` overdraw); the storage-pair
  convention (`MobusMoney.Schema`) is what rejects persisting them.
  """
  @spec negative?(t()) :: boolean()
  def negative?(%Money{} = money), do: Money.negative?(money)

  @doc """
  Returns `true` when the money value is exactly zero.
  """
  @spec zero?(t()) :: boolean()
  def zero?(%Money{} = money), do: Money.zero?(money)

  @doc """
  Rounds the amount to the currency's minor-unit exponent.

  `mode` defaults to `MobusMoney.Currency.default_rounding_mode/0` (`:half_up`,
  this library's house default — design D3), an explicit override of
  ex_money's own native `:half_even`, which remains reachable via
  `round(money, :half_even)`. Passes through to
  `Money.round(money, rounding_mode: mode)` — ex_money's real signature is
  a keyword list, not a bare positional mode.

  ## Examples

      iex> m = Money.new(:JPY, "100.5")
      iex> MobusMoney.Money.round(m)
      Money.new(:JPY, "101")
      iex> MobusMoney.Money.round(m, :half_even)
      Money.new(:JPY, "100")
  """
  @spec round(t()) :: t()
  @spec round(t(), rounding_mode()) :: t()
  def round(%Money{} = money, mode \\ MobusMoney.Currency.default_rounding_mode()) do
    Money.round(money, rounding_mode: mode)
  end

  @doc """
  Formats the money value for display: `{:ok, string}`.

  ex_money's real `Money.to_string/1` return shape, passed through.
  """
  @spec format(t()) :: {:ok, String.t()}
  def format(%Money{} = money), do: Money.to_string(money)

  @doc """
  Converts to minor units: `{currency_code, integer, exponent, remainder}`.

  `exponent` is the NEGATIVE of the currency's digit count (`-2` for USD),
  ex_money's own convention, passed through unmodified. Rounding to reach
  the minor unit applies this library's house mode (`:half_up`) explicitly
  — never ex_money's native `:half_even`, which would silently override
  the house default (design D1, PE-3 fold).

  ## Examples

      iex> MobusMoney.Money.to_integer_exp(Money.new(:USD, "200.00"))
      {:USD, 20000, -2, Money.new(:USD, "0.00")}
  """
  @spec to_integer_exp(t()) ::
          {Money.currency_reference(), integer(), integer(), t()}
  def to_integer_exp(%Money{} = money) do
    Money.to_integer_exp(money, rounding_mode: MobusMoney.Currency.default_rounding_mode())
  end

  @doc """
  Builds a money value from an integer minor-unit amount (ex_money's own
  minor-unit pair with `to_integer_exp/1`), delegated directly — ex_money
  reads the correct per-currency exponent from its registry (IQD is
  3-digit: `Money.from_integer(20012, :IQD)` is `20.012` IQD).

  The one exception to the bare delegation is the error path: an unknown
  `currency_code` is normalized to `{:error, :unknown_currency}` (the same
  reason atom `new/2`/`zero/1` return) so ex_money's raw
  `{:error, {Money.UnknownCurrencyError, _}}` tuple never escapes this
  library's boundary.
  """
  @spec from_integer(integer(), Money.currency_reference()) ::
          {:ok, t()} | {:error, :unknown_currency}
  def from_integer(amount, currency_code) do
    case Money.from_integer(amount, currency_code) do
      %Money{} = money -> {:ok, money}
      {:error, _} -> {:error, :unknown_currency}
    end
  end
end
