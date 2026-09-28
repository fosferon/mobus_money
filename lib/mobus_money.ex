defmodule MobusMoney do
  @moduledoc """
  Currency-aware money for the fosferon ecosystem.

  A thin, opinionated layer over [`ex_money`](https://hexdocs.pm/ex_money):
  a value type whose amount and currency always travel together
  (`MobusMoney.Money`), the full ISO 4217 registry with this library's own
  rounding default (`MobusMoney.Currency`), and an optional two-column
  storage-pair helper for Ecto schemas (`MobusMoney.Schema`).

  ## Required consumer configuration

  This library deliberately exposes **no currency-conversion (FX) capability**
  (operator ruling 2026-09-06: "an unaudited FX conversion is
  indistinguishable from an undisclosed markup"). `ex_money` however ships an
  exchange-rate service that auto-starts unless its configuration says
  otherwise, and a library cannot configure a dependency on behalf of its
  consumers — Mix never loads a dependency's own `config/config.exs` for the
  consuming application. Every consumer MUST therefore carry this line in its
  own configuration:

      config :ex_money, auto_start_exchange_rate_service: false

  and MUST call `MobusMoney.ensure_fx_disabled!/0` from its own
  `Application.start/2`, so a forgotten config line becomes a loud boot-time
  crash instead of a silently started, unaudited FX capability:

      def start(_type, _args) do
        MobusMoney.ensure_fx_disabled!()
        # ... the consumer's own supervision tree
      end

  Even in a mis-configured consumer, no public function of this library
  accepts an exchange rate or performs a conversion: `MobusMoney.Money.add/2`,
  `sub/2`, `sum/2`, and `compare/2` reject a currency mismatch with an error
  tuple carrying both currency codes.
  """

  @doc """
  Asserts the consumer has disabled `ex_money`'s exchange-rate service.

  Returns `:ok` when `Application.get_env(:ex_money,
  :auto_start_exchange_rate_service)` is `false` in the calling application's
  own configuration; raises otherwise, naming the missing setting.

  Call this from your application's own `Application.start/2` (see the
  moduledoc). It never writes configuration — it only reads yours. A
  library cannot do this for you: Mix never loads a dependency's own
  `config/config.exs` for the consuming application, and `:ex_money` boots
  before this library in the start order (design D4).
  """
  @spec ensure_fx_disabled!() :: :ok
  def ensure_fx_disabled! do
    if Application.get_env(:ex_money, :auto_start_exchange_rate_service) == false do
      :ok
    else
      raise ArgumentError,
            "MobusMoney requires ex_money's exchange-rate service to be " <>
              "disabled. Add the following to your application's own " <>
              "configuration: config :ex_money, auto_start_exchange_rate_service: false " <>
              "— and call MobusMoney.ensure_fx_disabled!/0 from your own " <>
              "Application.start/2. An unaudited FX conversion is " <>
              "indistinguishable from an undisclosed markup (ruling 2026-09-06)."
    end
  end
end
