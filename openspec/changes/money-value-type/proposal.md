## Why

Three fosferon projects handle money today and none of them do it safely:

- **Atrapos** stores per-agent and per-tenant budgets and usage cost as bare
  integer cent columns (`api_budget_cents`, `cost_cents`), with the currency
  living only in the column name and USD assumed everywhere by convention,
  never by a type. A platform budget envelope divides a cent sum by `100.0`.
- **MOBuS** (`~/Sites/mobus/mobus_umbrella/apps/mobus_core/lib/mobus_core/money.ex`,
  388 lines, verified by direct read) is closer but still loose: `round/2`
  turns a float into a Decimal silently and turns `nil` into `Decimal.new(0)`
  — a missing amount and a real zero become indistinguishable — and the
  currency is a hardcoded EUR default with no registry-backed validation of
  what else is legal.
- **sil-diary4** has no money handling at all: `free_vrg_budget_cents` and
  `vrg_cost_spent_cents` (verified by direct grep of
  `~/Sites/integrated.living/sil-diary4/lib/diary4/session_manager.ex`) are
  bare integers, same defect as Atrapos, independently arrived at.

Operator ruling 2026-09-06 (Atrapos): "an unaudited FX conversion is
indistinguishable from an undisclosed markup" — money must be currency-neutral
and carry its own currency, never a bare number whose unit lives in a variable
or column name. Operator ruling 2026-09-26 (Bee GC-5586): this is common
infrastructure across sibling platforms, so it is built once as an extractable,
opinionated fosferon library — `mobus_money` — rather than fixed three times
independently, and it is built OVER `ex_money` 6.x rather than ported from
scratch: `ex_money` already refuses floats and `nil`, already carries currency
with the amount, already supports the full ISO 4217 registry with correct
per-currency minor-unit exponents (JPY has none), and already errors rather
than converts on mixed-currency arithmetic — every property the ruling asks
for is upstream, verified against `ex_money` 6.2.1 under OTP 28 (2026-09-26
scratch probe: Decimal-based, refuses floats and nil, mixed-currency ops
return an error tuple carrying both currencies, exact arithmetic, explicit
rounding modes, integer-minor-unit conversion, localized formatting). What is
missing upstream is the ecosystem's own opinionated layer: one house rounding
default, a validated two-column storage-pair convention for a project whose
consumers are Ecto-backed and multi-schema (Atrapos: one usage table per
tenant schema), and FX left off by construction rather than merely unused.

This is the seed library of the family named in GC-5586: `mobus_billing`
(payment gateways, webhook dedupe) and `mobus_ledger` (issued-document
numbering) are siblings, not built here, and neither exists yet.

## What Changes

- Add `MobusMoney.Money`, a value type wrapping `Money.t()` (ex_money): a
  constructor that refuses floats, `nil`, and unknown currency codes with a
  reason atom rather than raising; arithmetic (`add/2`, `sub/2`, `sum/2`,
  `mult/2`, `compare/2`, `negative?/1`, `zero?/1`) that errors on a currency
  mismatch instead of converting; explicit-mode rounding; minor-unit
  conversion; and formatting.
- Add `MobusMoney.Currency`, a thin registry facade over `Money.Currency`
  (ex_money's full ISO 4217 set — no curated subset) plus the one thing ex_money
  does not carry: this library's own **default rounding mode**, deliberately
  overriding ex_money's native default.
- Add `MobusMoney.Schema`, an optional (Ecto is an optional dependency)
  two-column storage-pair helper: `money_fields/1` declares an
  `<name>_amount` numeric(28,8) field and an `<name>_currency` varchar(3)
  field together, a changeset validation enforcing pairing + registry
  membership + non-negativity, and a reader building one `MobusMoney.Money`
  (or `nil` for an unset pair) from the two columns.
- Configure `ex_money` with `auto_start_exchange_rate_service: false` at the
  library boundary — no network FX lookups are reachable through this
  library, by construction, not merely by non-use.
- Publish `mobus_money` 0.1.0 to hex once merged and independently verified
  (no consumer may take a path dependency on this repo — GC-5584's two-week
  unpublished-path-dependency defect is the precedent this avoids).

## Impact

- **New**: `lib/mobus_money/money.ex`, `lib/mobus_money/currency.ex`,
  `lib/mobus_money/schema.ex`, their test files, `mix.exs` gains `{:ex_money,
  "~> 6.2"}` and `{:ecto, "~> 3.10", optional: true}`.
- **Consumers (not built here, each is its own Bee once this publishes)**:
  Atrapos adopts this to replace its bare-cent columns (re-scoped from the
  superseded in-tree GC-4953 change-set); MOBuS adopts this to replace
  `MobusCore.Money`, after it moves off OTP 26 (GC-5587, ex_money needs
  OTP 27+); sil-diary4 adopts this to type `free_vrg_budget_cents` /
  `vrg_cost_spent_cents`.
- **No consumer is touched by this change.** This change-set lives entirely
  in `mobus_money`; it has no lib/ footprint in Atrapos, MOBuS, or sil-diary4.
- **Out of scope, declared forward**: multi-currency conversion / FX rates
  (the ruling forbids silent conversion; a future two-leg / FX-rate feature is
  its own change, tracked below); `mobus_billing` and `mobus_ledger` siblings.
