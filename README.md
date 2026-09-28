# mobus_money

Currency-aware money for the fosferon ecosystem (Atrapos, MOBuS, sil-diary4):
a value type whose amount and currency always travel together, an explicit
house rounding rule, and a two-column amount+currency storage convention —
one opinionated layer over [`ex_money`](https://hexdocs.pm/ex_money) 6.x,
shared by every consumer instead of fixed three times independently.

**Status: v0.1.0 implemented (change-set `money-value-type`, Bee GC-5588).**
Hex publish (`mix hex.publish`, 0.1.0) is an operator action after merge —
until it lands, no consumer may take a path dependency on this repository.

The rulings that created it (2026-09-06 and 2026-09-26, tracked as Bee
GC-5586):

- Amount and currency travel together; a bare integer with the currency
  baked into its name is the defect this library removes.
- "An unaudited FX conversion is indistinguishable from an undisclosed
  markup" — no FX capability ships here, ever silently.
- One opinionated layer over `ex_money` 6.x, built once, so the ecosystem
  has one representation and one rounding rule.
- Consumers: Atrapos first; MOBuS (which must move off OTP 26 first,
  GC-5587); sil-diary4.

## Required consumer configuration (read this first)

This library exposes **no currency-conversion capability**. `ex_money`
however auto-starts an exchange-rate service unless configured otherwise —
and a library cannot configure a dependency for its consumers (Mix never
loads a dependency's own `config/config.exs` for the consuming application).
Every consumer MUST:

1. carry this line in its **own** configuration:

   ```elixir
   config :ex_money, auto_start_exchange_rate_service: false
   ```

2. call the boot-time assertion from its **own** `Application.start/2`, so a
   forgotten config line is a loud crash instead of a silent, unaudited FX
   capability:

   ```elixir
   def start(_type, _args) do
     MobusMoney.ensure_fx_disabled!()
     # ... the consumer's own supervision tree
   end
   ```

Even in a mis-configured consumer, no public function of this library
accepts an exchange rate or performs a conversion.

## Public API

### `MobusMoney.Money` — the value type

Amount and currency travel together (a thin wrapper over `Money.t()`);
`nil` is refused, never treated as zero; floats are refused, never silently
converted; mixed-currency arithmetic errors instead of converting.

| Function | Contract |
|---|---|
| `new/2` | `{:ok, money}` or `{:error, reason}` with reason `:float_amount`, `:nil_amount`, `:unparseable_amount`, or `:unknown_currency` |
| `new!/2` | raises `MobusMoney.InvalidMoneyError` on exactly the conditions `new/2` refuses |
| `zero/1` | `{:ok, zero money}` or `{:error, :unknown_currency}` |
| `add/2`, `sub/2` | `{:ok, money}` or `{:error, {:currency_mismatch, code_a, code_b}}` — this library's own structured error, produced before any delegation, never a converted value |
| `sum/2` | folds a list into one total in a stated currency; empty list is the zero of that currency; mismatch anywhere halts immediately; never converts |
| `mult/2` | integer/`Decimal` multiplier; a float multiplier is refused with `:float_amount` |
| `compare/2` | `:lt` / `:eq` / `:gt`, or the same currency-mismatch error |
| `negative?/1`, `zero?/1` | classification |
| `round/2` | rounds to the currency's minor-unit exponent; mode defaults to the house `:half_up`, explicit modes pass through |
| `format/1` | `{:ok, string}` |
| `to_integer_exp/1` | `{currency, minor_units, exponent, remainder}` with the house rounding mode; `from_integer/2` is its inverse |

No `add!/2`, `sub!/2`, or `compare!/2` ships — no surveyed consumer needs a
raising variant, and none is added speculatively.

### `MobusMoney.Currency` — the registry

The full ISO 4217 set from `ex_money`, deliberately uncurated:

- `valid?/1` — known code (atom or binary), per the ISO 4217 registry
- `exponent/1` — minor-unit exponent (JPY 0, EUR 2, BHD/IQD 3 — the ISO
  figure, not CLDR's)
- `all_codes/0` — every known tender code
- `default_rounding_mode/0` — `:half_up`: this library's house default, an
  explicit, stated override of `ex_money`'s native `:half_even` (still
  reachable via `MobusMoney.Money.round(money, :half_even)`)

### `MobusMoney.Schema` — optional Ecto storage pair

Two plain columns, not a composite type or `jsonb`:

```elixir
defmodule Budget do
  use Ecto.Schema
  import MobusMoney.Schema, only: [money_fields: 1]

  schema "budgets" do
    money_fields :budget
    # budget_amount   :decimal  — numeric(28,8) in the migration
    # budget_currency :string   — varchar(3) in the migration
  end
end
```

- `validate_money(changeset, :budget)` — pairing (both set or both nil),
  registry membership, non-negativity (persisted holdings are magnitudes)
- `read_money(struct, :budget)` — `{:ok, nil}` for null/null, `{:ok, money}`
  for a valid pair, `{:error, {:half_set_pair, :amount | :currency}}` naming
  the nil column for a half-set pair, never a raise (raw SQL and fixtures
  bypass changesets)

Ecto is an optional dependency: with it absent, `MobusMoney.Schema` compiles
to a stub and the value type works unchanged.

## Out of scope, declared forward

- Multi-currency conversion / FX rates (GC-5708) — the ruling forbids
  silent conversion; a future two-leg feature is its own change.
- Signed persisted balances (a credit, a refund, a running account balance)
  — `money_fields/1`'s non-negativity is scoped to magnitudes by design.
- `mobus_billing` (payment gateways, webhook dedupe) and `mobus_ledger`
  (issued-document numbering) — planned sibling libraries, not built here.

## Installation (once published)

```elixir
def deps do
  [
    {:mobus_money, "~> 0.1"}
  ]
end
```

No path dependencies on this repository (GC-5584 precedent).

## License

MIT. See `LICENSE`.
