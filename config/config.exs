# This is mobus_money's OWN configuration — distinct from the rule in
# design.md D4 that this library ships no config for its consumers: Mix DOES
# load config/config.exs for the top-level application being compiled, which
# during `mix test` is this library itself. Setting the flag here keeps this
# library's own test runs from starting Money.ExchangeRates.Supervisor,
# matching the FX-off posture the library requires of its consumers.
import Config

config :ex_money, auto_start_exchange_rate_service: false
