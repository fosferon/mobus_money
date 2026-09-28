defmodule MobusMoney.InvalidMoneyError do
  @moduledoc """
  Raised by `MobusMoney.Money.new!/2` for exactly the conditions `new/2`
  refuses, carrying the same reason atom (`:float_amount`, `:nil_amount`,
  `:unparseable_amount`, `:unknown_currency`).
  """

  defexception [:reason]

  @type t :: %__MODULE__{reason: MobusMoney.Money.error_reason()}

  @impl true
  def message(%__MODULE__{reason: reason}) do
    detail =
      case reason do
        :float_amount ->
          "floats are refused (rounding and precision); construct from an integer, a Decimal, or a decimal string"

        :nil_amount ->
          "nil is refused, not treated as zero — a missing amount and a real zero are different facts"

        :unparseable_amount ->
          "the amount could not be parsed as an exact decimal"

        :unknown_currency ->
          "the currency code is not in the ISO 4217 registry"

        other ->
          inspect(other)
      end

    "invalid money (reason: #{inspect(reason)}) — #{detail}"
  end
end
