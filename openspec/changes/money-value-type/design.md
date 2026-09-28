## Context

This is `mobus_money`'s first change-set; the repo is a scaffold with no
modules (`lib/.gitkeep` only) and no prior spec. Everything below is
ground-truth-checked against the three named consumers' own code, not against
the epic's (GC-5586) narrative summary of them.

## Ground-truth check (non-forward — every citation below must resolve on the branch as authored)

- `~/Sites/atrapos` (this scaffold's sibling checkout registry does not
  reach it directly; verified via the atrapos worktree at
  `.worktrees/4953-house-money`): `lib/atrapos/agents/agent.ex` and
  `lib/atrapos/tenants/tenant.ex` carry a per-entity API budget as an
  integer cent column defaulting to zero; `lib/atrapos/billing/usage_record.ex`
  carries an integer cost in cents; `lib/atrapos/workers/spend_aggregator.ex`
  divides a cent sum by `100.0`. (Full citation list: the superseded
  `openspec/changes/house-money-representation/design.md` in that repo,
  Ground-truth section — reused here only as a pointer, not copied, since
  its own D1–D4 are superseded by this library existing.)
- `~/Sites/mobus/mobus_umbrella/apps/mobus_core/lib/mobus_core/money.ex`
  (388 lines, verified by direct read 2026-09-27): `@default_currency "EUR"`,
  `@currencies` a hardcoded list of `{name, code, symbol}` tuples (no minor-unit
  exponent), `round(n, precision) when is_float(n)` converts a float silently,
  `round(nil, _precision), do: Decimal.new(0)` turns a missing amount into a
  real zero. `~/Sites/mobus/mobus_umbrella/.tool-versions`: `erlang 26.2.1`.
- `~/Sites/integrated.living/sil-diary4/lib/diary4/session_manager.ex`
  (verified by direct grep 2026-09-27): `free_vrg_budget_cents` and
  `vrg_cost_spent_cents` are bare integers threaded through config, struct
  fields, and a DB row, with no money type anywhere in the module or in
  `mix.exs` (no money/decimal dependency declared). `.tool-versions`:
  `erlang 28.4.2` — already ahead of MOBuS, no OTP blocker for this consumer.
- `ex_money` 6.2.1 under OTP 28 (2026-09-26 scratch probe, this operator):
  `Money.new/2` is Decimal-based and refuses a float amount and `nil`;
  mixed-currency `add`/`compare` return an error tuple carrying both codes,
  never converting; arithmetic is exact (no float intermediate); rounding
  takes an explicit mode, default `:half_even`; integer minor-unit conversion
  is exact or an error; formatting is locale-aware; currency codes are atoms
  and the registry accepts the full ISO 4217 set including `XXX`; the
  dependency needs OTP 27+ (fails on `:json` under OTP 26); it auto-starts an
  exchange-rate service unless `auto_start_exchange_rate_service: false`; the
  `ex_cldr`-based localize dependency adds roughly 7MB and ~19s to a first
  compile.
- This repo's own `.tool-versions`: `erlang 28.4.2`, `elixir
  1.19.5-otp-28` — satisfies `ex_money`'s OTP 27+ floor with no bump needed
  here.
- `mix.lock` in this repo declares no money/decimal dependency yet (scaffold
  state); `mix.exs`'s `deps/0` carries only `ex_doc`, by design (the scaffold's
  own comment: runtime deps are added by the change-set that needs them).

## Consumers

Per this repo's `AGENTS.md`: a consumer whose requirements were not read in
its own code is listed as unread, with a Bee. All three below were read
directly (citations above); none is unread.

- **Atrapos** (`~/Sites/atrapos`). Holds today: three integer-cent columns
  (agent budget, tenant budget, usage cost), two duplicated cost estimators
  with an identical pricing table, a float platform-budget cap and cache, a
  `/100.0` in the spend aggregator, literal `"$"` in five operator surfaces,
  Stripe's default currency hardcoded to `"usd"`. Migration this change asks
  of it: none directly — Atrapos's own adoption is a separate, re-scoped
  change-set (the superseded `house-money-representation` under GC-4953),
  authored after this library publishes, replacing its bare columns with
  `MobusMoney.Schema.money_fields/1` pairs and its estimators/aggregator/
  operator-surface reads with `MobusMoney.Money` values. Not built here.
- **MOBuS** (`~/Sites/mobus/mobus_umbrella`, app `mobus_core`). Holds today:
  `MobusCore.Money`, 388 lines, a bare-Decimal-plus-separate-currency-string
  API (not a value type), a hardcoded 5-currency list with no minor-unit
  exponent, float-accepting `round/2`, nil-to-zero `round/2`. Blocked from
  adopting this library until it moves off `erlang 26.2.1` (`ex_money` needs
  OTP 27+) — tracked as **GC-5587**, not part of this change. Migration this
  change asks of it, once unblocked: replace `MobusCore.Money` with
  `MobusMoney.Money`/`MobusMoney.Currency`; MOBuS's own callers of
  `MobusCore.Money.round/2` and `.format/2` need their own follow-up Bee at
  adoption time (not filed here — no OTP floor to build against yet).
- **sil-diary4** (`~/Sites/integrated.living/sil-diary4`). Holds today: no
  money type; `free_vrg_budget_cents` and `vrg_cost_spent_cents` as bare
  integers in `lib/diary4/session_manager.ex`, config, and a DB row. Already
  on `erlang 28.4.2` — no OTP blocker. Migration this change asks of it: adopt
  `MobusMoney.Schema.money_fields/1` for the two budget/cost pairs in its own
  follow-up change-set. Not built here.

**No consumer's lib/ is touched by this change.** This library ships with
zero adoption sites; each consumer's migration is its own OpenSpec change-set,
authored in that consumer's own repository, after `mobus_money` 0.1.0 is
published (a path dependency on this repo is refused at adoption time — see
D7).

## Decisions

### D1. The value type is a thin wrapper over `ex_money`'s `Money.t()`, not a fresh struct

`MobusMoney.Money` wraps `Money.t()` directly rather than re-deriving a struct
holding a Decimal and a currency code. `ex_money` already has every property
the 2026-09-06 ruling asks for (currency travels with the amount, no float,
`nil` is refused not zeroed, mixed-currency ops error). Re-deriving a struct
here would duplicate `ex_money`'s own correctness work for no gain the ruling
asks for. What this layer adds: an error-tuple API where `ex_money` raises
(`Money.new/2` returns `{:ok, money}` or `{:error, reason}` already for most
inputs, but `Money.new!/2`-style call sites and a few edge functions in
`ex_money` raise `ArgumentError`/`Money.InvalidAmountError` — this layer
normalizes every entry point to a tuple, converting a caught exception's
message into one of this library's own reason atoms:
`:float_amount`, `:nil_amount`, `:unparseable_amount`, `:unknown_currency`,
`:currency_mismatch` (carrying both codes)), plus the two things `ex_money`
does not opinionate on: a house default rounding mode (D3) and the optional
storage-pair convention (D5).

Public surface, each function used by at least one of the three named
consumers' documented needs (no function ships speculatively): `new/2`,
`new!/2`, `zero/1`, `add/2`, `sub/2`, `sum/2` (over a list, one stated
currency), `mult/2` (by a Decimal or integer), `compare/2`, `compare!/2` (for
call sites where a currency mismatch is unreachable by construction — none in
this library itself; documented for a consumer's own envelope-style use),
`round/2` (explicit mode, default from `MobusMoney.Currency.default_rounding_mode/0`),
`negative?/1`, `zero?/1`, `format/1`, `to_minor_units/1`, `from_minor_units/2`.

Alternative rejected: port a fresh struct from scratch (the superseded
Atrapos `house-money-representation` D1). Correct at the time it was written,
when depending on `ex_money` was rejected; superseded by the 2026-09-26
ruling that chose the opposite: build over `ex_money`, not around it.

Alternative rejected: expose `ex_money`'s `Money.t()` directly with no
wrapper. Leaves every consumer to hand-roll the float/nil-refusal-to-tuple
normalization and the house rounding default independently — exactly the
"fix it three times" outcome GC-5586 exists to prevent.

### D2. The currency registry is `ex_money`'s full ISO 4217 set, uncurated

`MobusMoney.Currency` is a facade over `Money.Currency`: `valid?/1`,
`exponent/1`, `all_codes/0`, `default_rounding_mode/0` (D3). No consumer
needs a restricted currency list today (Atrapos's superseded design curated
five; that curation existed only because a from-scratch struct made every
extra currency a line of hand-maintained data — `ex_money` already carries
correct data for the full set, so curating loses correctness for no
implementation cost saved).

Alternative rejected: keep Atrapos's five-currency curated list as this
library's default. A consumer that needs to restrict which currencies its
own UI offers does so at its own boundary (a `select_options/0`-style helper
scoped to that consumer's config, not this library's registry) — restricting
here would make this library wrong for any consumer whose business expands
past five currencies, silently.

### D3. House rounding default is half-up; `ex_money`'s native default is not overridden silently

`MobusMoney.Currency.default_rounding_mode/0` returns `:half_up`.
`MobusMoney.Money.round/2`'s second argument defaults to it. `ex_money`'s own
native default is `:half_even` (banker's rounding) — chosen upstream for
statistical neutrality over repeated rounding, not for how it reads on a
single customer-facing invoice line. Every consumer surveyed (Atrapos's
superseded design, MOBuS's `MobusCore.Money`) independently chose half-up
before this library existed; this decision keeps their existing customer-
facing rounding behavior and states the override explicitly rather than
letting `ex_money`'s default silently become the ecosystem's default.

Alternative rejected: keep `ex_money`'s `:half_even` default. Correct and
defensible in the abstract, but it is a silent behavior change for both
surveyed consumers relative to what they already do today, with no consumer
asking for it.

### D4. No FX by construction, not by convention

`Application.put_env(:ex_money, :auto_start_exchange_rate_service, false)` is
set by this library at compile time (`config/config.exs`, checked into the
library so a consumer does not have to remember it) — `ex_money`'s exchange
rate service, if left to its default, starts a GenServer that polls an
external FX API on application start. This library's own `add/2`, `sub/2`,
`sum/2`, `compare/2` reject a currency mismatch with an error tuple carrying
both codes; none converts. No public function accepts an exchange rate.

Alternative rejected: leave the exchange-rate service at its default and
simply never call `Money.to_currency/2`. Unused capability that starts a
network-polling process on every consumer's boot is still a defect the
2026-09-06 ruling's spirit ("an unaudited FX conversion is indistinguishable
from an undisclosed markup") argues against — if it is never audited because
it is never used, it should not be reachable at all.

### D5. Persisted money is two columns and one schema helper (Ecto is optional)

`MobusMoney.Schema.money_fields/1` declares `<name>_amount` (`numeric(28,8)`)
and `<name>_currency` (`varchar(3)`) together on an Ecto schema;
`MobusMoney.Schema.validate_money/2` (called from a changeset) enforces:
both null or both non-null, currency valid per `MobusMoney.Currency.valid?/1`,
amount not negative. `MobusMoney.Schema.read_money/2` returns one
`MobusMoney.Money` from the pair, or `nil` for null/null. Ecto is declared
`optional: true` in `mix.exs`: a consumer that only needs the value type and
arithmetic (no persistence) does not need Ecto pulled in transitively, and
`MobusMoney.Schema` is not compiled unless Ecto is present (guarded via
`Code.ensure_loaded?/1` at the module boundary, following the pattern
optional-Ecto-integration hex packages use).

Scale eight, not two: per-token LLM provider prices are sub-cent at the small-
model end (a price of 15¢ per million tokens is 1.5e-7 dollars per token,
seven decimal places) — this is Atrapos's own already-verified requirement
(superseded design D3), reused here because it is a property of the money
TYPE's storage precision, not of Atrapos's schema specifically, and any future
consumer metering sub-cent unit costs needs the same floor.

Alternative rejected: `ex_money`'s own `Money.Ecto.Composite.Type` (a single
Postgres composite-type column). Rejected for the same reason the superseded
Atrapos design rejected a hand-rolled composite type: it needs the Postgres
composite type registered and visible through search paths in every schema a
consumer's database fans out into (Atrapos alone runs one schema per tenant),
and it makes every `psql` inspection and hand-written test fixture harder, for
a benefit (one column instead of two) this library's two-column helper gives
without any Postgres-side registration step.

Alternative rejected: a single `jsonb` column. Cannot be summed, compared, or
constrained (pairing, non-negativity) in SQL without casting; loses a
consumer's ability to index or `GROUP BY` currency in a spend query.

### D6. Configuration is explicit arguments, never `Application.get_env` for per-call behavior

`MobusMoney.Money.round/2` takes its mode as an explicit argument (defaulting
to D3's constant); no function reads a consumer's application environment for
per-call behavior. The one process-wide `Application.put_env` this library
performs (D4, disabling the FX service) is infrastructure-off, not a
business-behavior switch. A library with several unrelated consumer
applications potentially running in the same BEAM release (unlikely today,
but this library must not assume otherwise) must not let one consumer's
config silently change another's rounding.

Alternative rejected: a `Application.get_env(:mobus_money, :rounding_mode)`
override point. Convenient for a single-app consumer, wrong for a library;
D3's constant is exported as a function specifically so a consumer that wants
a different default composes it at its own call sites (`round(m, :half_even)`)
rather than mutating shared global state.

### D7. A published library, not a path dependency

`mobus_money` is published to hex (0.1.0) after this change merges and is
independently verified; no consumer takes a path dependency on this
repository. This is the precedent GC-5584 established the hard way: an
unpublished path dependency on an ecosystem library broke the Atrapos deploy
for two weeks. `mix.exs`'s `package/0` (already scaffolded) is the publish
target; this change-set does not itself run `mix hex.publish` (an operator
action, out of band, after merge — recorded as a task, not automated).

## Counterparts and symmetric cases

### 1. What other cases of this problem exist?

- **Other minor-unit exponents.** JPY (0 decimals) versus EUR/USD/GBP (2)
  versus a currency with 3 (e.g. BHD, in the full ISO set this library now
  carries). Addressed: `ex_money`'s own registry carries the correct exponent
  per code; `MobusMoney.Currency.exponent/1` reads it, never hardcodes it —
  the defect the superseded Atrapos design's hardcoded five-entry table would
  have reintroduced for any currency outside its list.
- **Other rounding modes.** Half-up (D3's default), half-even (`ex_money`'s
  native default, still reachable via an explicit argument), and the other
  modes `Decimal.round/3` supports (`:down`, `:up`, `:ceiling`, `:floor`).
  Addressed: `round/2`'s mode argument passes through to `ex_money`/`Decimal`
  unmodified; this library does not restrict which modes are callable.
- **Other storage shapes.** Two plain columns (D5, chosen), a single
  composite-type column (`ex_money`'s own, rejected in D5), a single `jsonb`
  column (rejected in D5). Addressed: only the two-column shape ships in
  v0.1; a consumer needing a different shape is out of scope below.
- **Other consumers.** Atrapos, MOBuS, sil-diary4 — all three read and listed
  above. `mobus_billing` and `mobus_ledger` are sibling LIBRARIES in the same
  family (GC-5586), not consumers of this one; if either comes to depend on
  `mobus_money` that is their own change-set to author.
- **Multi-currency conversion / FX.** The one case this library deliberately
  does not address (D4) — see below.

### 2. Are they addressed by this slice, or out of scope?

- Minor-unit exponents, rounding modes, the two-column storage shape,
  disabling FX-by-default: in scope, D1–D5 above.
- A different storage shape than two columns: out of scope. No named
  consumer needs one; `MobusMoney.Money` itself does not assume a storage
  shape (D5's helper is optional), so a future consumer needing a different
  shape builds its own reader/writer against the value type without touching
  this library.
- Multi-currency conversion / FX rates: explicitly out of scope, tracked as
  forward scope — **GC-5708** (filed alongside this change-set: "mobus_money:
  multi-currency conversion / FX-rate support, v-next" — no consumer has a
  billable two-leg amount today on any project's master/main branch; Atrapos's
  own two-leg tracking, GC-5575, is blocked by GC-4953 and will be this
  library's first real FX consumer once it exists).
- `mobus_billing` (payment gateways, webhook dedupe) and `mobus_ledger`
  (issued-document numbering): out of scope, not built here, no Bee needed
  yet (GC-5586 names them as planned siblings; neither has a consumer
  survey of its own yet, unlike this library which had one before it was
  scaffolded).

### 3. Why is the asymmetry safe to ship?

A single-currency consumer (every one of the three surveyed, today) is fully
served by v0.1: construction, arithmetic, rounding, formatting, and the
storage-pair convention all work with no FX capability needed. The one
withheld capability (conversion) is the one capability the operator's ruling
says must never happen silently — withholding it is not a gap relative to
what consumers need today, it is the ruling's own requirement, upheld by
construction rather than by discipline. When a real two-leg FX need arrives
(GC-5575), it is additive to this value type (a new module, not a change to
`add/2`'s error-on-mismatch behavior), so nothing shipped here needs to be
un-shipped.

## Risks / Trade-offs

- **`ex_money`'s `ex_cldr`-based localize dependency adds ~7MB and ~19s to a
  first compile** (2026-09-26 probe). Accepted: this is a one-time cost per
  consumer's dependency tree, not a runtime cost, and `ex_money`'s formatting
  is the ecosystem's only correctly-localized money formatting today (none of
  the three consumers' own code formats money correctly for a non-USD/EUR
  locale).
- **`ex_money` needs OTP 27+.** MOBuS cannot adopt this library until GC-5587
  lands. Accepted and already tracked outside this change (README, GC-5587);
  this library itself has no OTP constraint problem (this repo pins OTP 28).
- **Wrapping rather than re-exporting `Money.t()` means a translation layer
  between this library's error tuples and `ex_money`'s exceptions/tuples.** A
  future `ex_money` major version could change which functions raise versus
  return tuples, requiring this layer's translation to be re-verified.
  Accepted: the alternative (expose `ex_money` raw) pushes that same
  volatility onto every consumer instead of absorbing it once, which is this
  library's entire reason to exist.

## Testing

- Value type: construction errors by reason (float, nil, unparseable string,
  unknown currency code, lowercase code accepted per `ex_money`'s own
  behavior — verified, not assumed); nil is never zero; exact arithmetic
  (0.056 + 0.044 == exactly 0.100, matching the superseded design's own proof
  case); mixed-currency add/sub/sum/compare return the mismatch error
  carrying both codes and never a converted value; rounding by minor-unit
  exponent for JPY vs EUR at both the half-up default and an explicit
  half-even override; `to_minor_units`/`from_minor_units` exact or refused;
  `format/1` output for at least one 0-decimal and one 2-decimal currency.
- Currency registry: `valid?/1` true for the full ISO 4217 set `ex_money`
  carries, false for a non-code string; `exponent/1` matches `ex_money`'s own
  data for a sample spanning 0, 2, and 3-decimal currencies;
  `default_rounding_mode/0` returns `:half_up` (falsifies D3 by asserting the
  non-`ex_money`-native value, not merely that a value is returned).
- Schema helper (conditionally compiled, tested only when Ecto is present in
  the test env's deps): `money_fields/1` defines both columns;
  `validate_money/2` rejects a half-set pair, an unknown currency, and a
  negative amount; `read_money/2` returns `nil` for null/null and a
  `MobusMoney.Money` otherwise; a guard test asserts `MobusMoney.Schema` does
  not raise at compile time when Ecto is absent (simulated via
  `Code.ensure_loaded?/1` stub, not by actually removing the test-env
  dependency).
- FX-disabled guard: a test asserts
  `Application.get_env(:ex_money, :auto_start_exchange_rate_service) == false`
  after this library's config loads, falsified by temporarily removing the
  config line and observing the test fail before restoring it.
- No test in this change-set exercises an actual consumer (Atrapos, MOBuS,
  sil-diary4) — this library has no adoption-site tests until each consumer's
  own follow-up change-set lands.
