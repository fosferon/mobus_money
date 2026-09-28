defmodule MobusMoney.Currency do
  @moduledoc """
  A thin registry facade over `Money.Currency` (ex_money's full ISO 4217
  set — deliberately uncurated, design D2), plus this library's own
  **house rounding default**.

  No curated subset ships here: ex_money already carries correct per-currency
  data (minor-unit exponents included — JPY has none, BHD/IQD have three) for
  the entire registry, so curation would trade correctness for nothing. A
  consumer that wants to restrict which currencies its own UI offers does so
  at its own boundary.
  """

  @doc """
  Returns `true` if `code` is a known ISO 4217 currency code.

  Accepts an atom or a binary (`:EUR`, `"EUR"`, `"eur"`), matching
  `Money.Currency.currency_for_code/1`'s own acceptance.
  """
  @spec valid?(Money.Currency.code()) :: boolean()
  def valid?(code) do
    match?({:ok, _}, Money.Currency.currency_for_code(code))
  end

  @doc """
  Returns the minor-unit exponent for `code` per ISO 4217.

  Prefers the ISO figure (`iso_digits`) over CLDR's (`digits`); they diverge
  for a few currencies (e.g. IQD: ISO 3, CLDR 0). Returns `nil` for an
  unknown code.

  ## Examples

      iex> MobusMoney.Currency.exponent(:JPY)
      0
      iex> MobusMoney.Currency.exponent(:EUR)
      2
      iex> MobusMoney.Currency.exponent(:IQD)
      3
  """
  @spec exponent(Money.Currency.code()) :: non_neg_integer() | nil
  def exponent(code) do
    case Money.Currency.currency_for_code(code) do
      {:ok, currency} -> currency.iso_digits || currency.digits
      _ -> nil
    end
  end

  @doc """
  Returns all known tender currency codes (atoms), ex_money's full ISO 4217
  set.
  """
  @spec all_codes() :: [Money.Currency.code(), ...]
  def all_codes do
    Money.Currency.known_tender_currencies()
  end

  @doc """
  Returns this library's house rounding mode: `:half_up`.

  This deliberately overrides ex_money's own native default of `:half_even`
  (design D3): half-even is chosen upstream for statistical neutrality over
  repeated rounding, not for how it reads on a single customer-facing
  invoice line, and every surveyed consumer already rounds half-up. The
  override is stated, never silent — `ex_money`'s `:half_even` remains
  reachable via an explicit argument to `MobusMoney.Money.round/2`.
  """
  @spec default_rounding_mode() :: :half_up
  def default_rounding_mode do
    :half_up
  end
end
