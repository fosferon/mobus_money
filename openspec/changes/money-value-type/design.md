## Context

This is `mobus_money`'s first change-set; the repo is a scaffold with no
modules (`lib/.gitkeep` only) and no prior spec. Everything below is
ground-truth-checked against the three named consumers' own code, not against
the epic's (GC-5586) narrative summary of them.

## Ground-truth check (non-forward — every citation below must resolve on the branch as authored)

- Atrapos, verified via the worktree at
  `~/Sites/atrapos/.worktrees/4953-house-money`:
  `~/Sites/atrapos/.worktrees/4953-house-money/lib/atrapos/agents/agent.ex` and
  `~/Sites/atrapos/.worktrees/4953-house-money/lib/atrapos/tenants/tenant.ex`
  carry a per-entity API budget as an integer cent column defaulting to zero;
  `~/Sites/atrapos/.worktrees/4953-house-money/lib/atrapos/billing/usage_record.ex`
  carries an integer cost in cents;
  `~/Sites/atrapos/.worktrees/4953-house-money/lib/atrapos/workers/spend_aggregator.ex`
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
  compile. **Correction (PE-6, MINOR, pre-execution audit):** the probe's
  OTP-27+ claim is contradicted by `ex_money` 6.2.1's own package
  definition (its deps list, around line 125), which
  adds `{:json_polyfill, "~> 0.2 or ~> 1.0"}` behind a
  `Code.ensure_loaded?(:json)` guard specifically to carry an OTP-26 path.
  Not blocking for this repo (already OTP 28) — but the Consumers section's
  claim that GC-5587 (MOBuS's OTP bump) gates its adoption of this library
  needs its own re-verification against the polyfill path before that
  premise is relied on elsewhere; not re-verified here (out of this change's
  scope — this library ships regardless of what MOBuS's actual floor turns
  out to be).
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
  integers in `~/Sites/integrated.living/sil-diary4/lib/diary4/session_manager.ex`,
  config, and a DB row. Already
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

**Corrected during doc review/pre-execution audit (PE-1, PE-2, PE-5, BLOCKER
— the round-1 text of this decision named upstream functions that do not
exist, verified against the actual `ex_money` 6.2.1 source at
`~/.hex/packages/hexpm/ex_money-6.2.1.tar`, not against the 2026-09-26 probe
notes, which were themselves wrong on these points.)**

`MobusMoney.Money` wraps `Money.t()` directly rather than re-deriving a struct
holding a Decimal and a currency code. `ex_money` already has every property
the 2026-09-06 ruling asks for (currency travels with the amount, no float,
`nil` is refused not zeroed, mixed-currency ops error). Re-deriving a struct
here would duplicate `ex_money`'s own correctness work for no gain the ruling
asks for.

Public surface, each function's REAL upstream binding verified by direct
source read (`ex_money-6.2.1/lib/money.ex`,
`ex_money-6.2.1/lib/money/currency.ex`), each used by at least one of the
three named consumers' documented needs:

- `new/2(amount, currency_code)` / `new!/2` — this library's own function
  heads pattern-match `nil` and `is_float(amount)` FIRST and return
  `{:error, :nil_amount}` / `{:error, :float_amount}` directly, without
  calling `ex_money` at all for those two cases (sidesteps depending on
  `ex_money`'s exact exception text for a contract this library owns).
  Every other input delegates to `Money.new(currency_code, amount)`
  (`lib/money.ex:199`), translating `{:error, {Money.UnknownCurrencyError,
  _}}` to `{:error, :unknown_currency}` and any other `{:error, _}` ex_money
  returns to `{:error, :unparseable_amount}`. `new!/2` raises
  `MobusMoney.InvalidMoneyError` on any of the four reasons (PL-1: the spec
  requires `new!/2` to raise, not to return a tuple — task 3.1's original
  wording said "normalizes every raise path to `{:error, reason}`" without
  distinguishing `new/2` from `new!/2`; fixed in tasks.md).
- `zero/1(currency_code)` → `Money.zero/1` (`lib/money.ex:3005`, real).
  `Money.zero/2` validates the currency code first (`lib/money.ex:3011-3015`)
  and returns `{:error, {Money.UnknownCurrencyError, _}}` for an unknown one
  — this library's own `zero/1` therefore has the same two-shape contract as
  `new/2`: `{:ok, money} | {:error, :unknown_currency}`, not a bare `Money`
  value (round-4 pre-execution PE-1 depends on this being stated explicitly;
  see `sum/2`'s corrected seed handling below).
- `add/2`, `sub/2`, `compare/2` — **corrected (PE-1, round-3 pre-execution,
  BLOCKER):** `Money.add/2`/`Money.sub/2`/`Money.compare/2` do NOT return a
  structured mismatch tuple on differing currencies — verified by direct
  read, they return `{:error, {ArgumentError, "Cannot add monies with
  different currencies. Received :EUR and :USD."}}`: an exception module
  plus a prose string with the codes embedded as text, not the
  `{:currency_mismatch, code_a, code_b}` shape this library's own spec
  requires. Rather than parse that string, this library's own `add/2`
  pattern-matches BOTH operands' `.currency` fields FIRST: same currency →
  delegate to `Money.add/2` (now guaranteed same-currency, so ex_money's
  function only ever receives inputs it cannot mismatch-error on);
  different currencies → `{:error, {:currency_mismatch, currency_a,
  currency_b}}` directly, returned by this library's own code, never
  touching `Money.add/2` for that branch at all. `sub/2` and `compare/2`
  follow the identical pattern. This mirrors `new/2`'s own precedent
  (D1 above): intercept the cases this library owns a contract for BEFORE
  delegating, rather than translate an upstream exception's prose.
- `sum/2(money_list, currency)` — **corrected (PE-2, round-3
  pre-execution, MAJOR; seed handling further corrected, PE-1, round-4
  pre-execution, MINOR):** the round-2 pseudocode
  (`Enum.reduce(money_list, fn m, acc -> ... end)`, no seed) crashes on an
  empty list (`Enum.EmptyError`, no seed value) and, for a 3+-element list
  with a mismatch not in the final pair, feeds `{:error, _}` back into
  `add/2` as if it were a `%Money{}`, raising `FunctionClauseError`. The
  originally-intended second argument (proposal/design round 1: "over a
  list, one stated currency") was dropped from the round-2 rewrite and is
  restored here as `sum/2`'s real second parameter — the currency the sum
  must be denominated in, also the seed. The round-3 fix's seed,
  `{:ok, zero(currency)}`, assumed `zero/1` always succeeds; since `zero/1`
  can itself return `{:error, :unknown_currency}` (see above), that assumed
  wrapping would produce `{:ok, {:error, _}}` for a bad `currency` argument,
  and the next `add/2` call would then crash on the same non-`%Money{}`
  accumulator PE-2 already fixed for the general case. Corrected to validate
  the seed before folding:
  ```
  case zero(currency) do
    {:error, _} = err -> err
    {:ok, seed} ->
      Enum.reduce_while(money_list, {:ok, seed}, fn m, {:ok, acc} ->
        case add(acc, m) do
          {:ok, _} = ok -> {:cont, ok}
          {:error, _} = err -> {:halt, err}
        end
      end)
  end
  ```
  An unknown `currency` argument now returns `{:error, :unknown_currency}`
  immediately, matching every other function's treatment of that input
  class, instead of reaching the fold at all. An empty list (valid currency)
  returns `{:ok, seed}` (no crash, no undefined behavior); a mismatch
  anywhere in the list halts immediately with this library's own `add/2`'s
  structured error (never reaches a second `add/2` call with a non-`%Money{}`
  accumulator). Never calls `Money.sum/2` (still true, and still
  load-bearing: `Money.sum/2`'s second argument is exchange RATES,
  defaulting to `latest_rates_or_empty_map()`, and it converts each
  element via `to_currency/3` — an FX-converting function this library must
  never expose).
- `mult/2(money, number)` → `Money.mult/2` (`lib/money.ex:1239`, real,
  accepts integer/float/Decimal — this library's own `mult/2` refuses a
  float multiplier the same way `new/2` refuses a float amount, for the same
  no-float posture).
- `compare/2` — see `add/2` above (same currency-check-first pattern).
  **`compare!/2` is NOT shipped** (removed during round-3 pre-execution,
  PE-6, MAJOR: it had no consumer citation anywhere in this change-set, and
  was the only bang-arithmetic variant proposed — an unargued asymmetry that
  D1's own stated principle, "no function ships speculatively," already
  forbids. `add!/2`/`sub!/2` were never proposed either; consistency argues
  for shipping none of the bang comparison/arithmetic variants until a real
  consumer need names one).
- `round/2(money, mode)` → `Money.round(money, rounding_mode: mode)`
  (`lib/money.ex:2332` — **real signature is a keyword list, not a bare
  positional mode**, `:rounding_mode` key, verified from the function's own
  `@doc`/examples). `mode` defaults to
  `MobusMoney.Currency.default_rounding_mode/0` (D3).
- `negative?/1`, `zero?/1` → `Money.negative?/1` / `Money.zero?/1`
  (`lib/money.ex:3160,3045`, real).
- `format/1(money)` → `Money.to_string/1` (`lib/money.ex:831` — this
  library's own name; `ex_money` has no function literally named `format`).
  Returns `{:ok, string}` (ex_money's real return shape — verified; NOT a
  bare string).
- `to_integer_exp/1(money)` → `Money.to_integer_exp(money, rounding_mode:
  MobusMoney.Currency.default_rounding_mode())` — **corrected (PE-3, round-3
  pre-execution, MINOR):** `Money.to_integer_exp/2` rounds internally via
  `Money.round/2`, whose own default is `:half_even`
  (`lib/money.ex:86`); the round-2 text's "fixed options" never said the
  house `:half_up` default must be threaded through explicitly — fixed here,
  otherwise this one function would silently keep ex_money's native default,
  the exact silent-default problem D3 exists to prevent. Returns
  `{currency_code, integer, exponent, remainder_money}`
  (`lib/money.ex:2825`) — **the exponent is the NEGATIVE of the digit
  count** (e.g. `-2` for a 2-digit currency like USD; ex_money's own example:
  `Money.to_integer_exp(Money.new(:USD, "200.00"))` → `{:USD, 20000, -2,
  ...}`), passed through unmodified so this library's own sign convention
  matches ex_money's documented one exactly, not an inverted house
  convention. `from_integer/2(integer, currency_code)` → `Money.from_integer/2`
  (`lib/money.ex:2912`), delegated directly (no internal rounding to pin).

Alternative rejected: port a fresh struct from scratch (the superseded
Atrapos `house-money-representation` D1). Correct at the time it was written,
when depending on `ex_money` was rejected; superseded by the 2026-09-26
ruling that chose the opposite: build over `ex_money`, not around it.

Alternative rejected: expose `ex_money`'s `Money.t()` directly with no
wrapper. Leaves every consumer to hand-roll the float/nil-refusal-to-tuple
normalization and the house rounding default independently — exactly the
"fix it three times" outcome GC-5586 exists to prevent.

### D2. The currency registry is `ex_money`'s full ISO 4217 set, uncurated

**Corrected during pre-execution audit (PE-1, BLOCKER — `Money.Currency` has
no `valid?/1`, `exponent/1`, or `all_codes/0`; verified real surface below.)**

`MobusMoney.Currency` is a facade over `Money.Currency.currency_for_code/1`
(`ex_money-6.2.1/lib/money/currency.ex:344`, the only lookup function that
exists): `valid?(code)` is
`match?({:ok, _}, Money.Currency.currency_for_code(code))`; `exponent(code)`
pattern-matches `{:ok, currency}` and reads `currency.iso_digits` (falling
back to `currency.digits` when `iso_digits` is `nil` — the
`%Localize.Currency{}` struct, `~/.hex/packages/hexpm/localize-1.3.0.tar`
`lib/localize/currency.ex:32-54`, carries both; `iso_digits` is the ISO 4217
figure this library wants, `digits` is CLDR's, and they diverge for a few
currencies such as IQD per `ex_money`'s own `from_integer/2` docs);
`all_codes/0` is `Money.Currency.known_tender_currencies/0`
(`lib/money/currency.ex:267`, the real enumeration function — there is no
function named `all_codes` anywhere in `ex_money`). Plus
`default_rounding_mode/0` (D3, this library's own, no upstream equivalent).
No consumer needs a restricted currency list today (Atrapos's superseded
design curated five; that curation existed only because a from-scratch
struct made every extra currency a line of hand-maintained data — `ex_money`
already carries correct data for the full set, so curating loses correctness
for no implementation cost saved).

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

### D4. No FX, enforced by a loud boot-time check — not by a library config.exs, which Mix never loads

**Corrected during doc review (F1.1, P0):** the original text of this
decision claimed a checked-in `config/config.exs` in this library would
disable `ex_money`'s exchange-rate service "for every consumer". That is
architecturally impossible: Mix does not load a *dependency's*
`config/config.exs` at all — only the top-level application being compiled
(or an umbrella root) has its `config/config.exs` read, which is exactly why
`ex_money`'s own documentation, and this ecosystem's own prior-art consumer
(`~/Sites/www` / Seaker, `config/config.exs:36-43`, verified by direct read:
`config :ex_money, open_exchange_rates_app_id: ..., exchange_rates_retrieve_every: ...`)
each configure `:ex_money` in the **consuming application's own** config, not
in a library. A config file shipped in this library's own tree (even if
`mix.exs`'s `package/0` `files` list included `config/`, which it does not)
would never reach a consumer's compiled release.

`ex_money`'s exchange-rate service is (per the 2026-09-26 probe) started from
`:ex_money`'s own `application/0` callback when the app boots, unless config
says otherwise — and because `:ex_money` is a dependency of `:mobus_money`,
OTP's start order brings `:ex_money` up *before* `:mobus_money`, so even a
`MobusMoney.Application.start/2` callback in this library cannot preempt it:
by the time this library's own code could run, `:ex_money`'s supervision
tree has already read whatever config existed at boot. There is no code this
library can ship that unilaterally guarantees the service never starts in a
consumer that forgot to configure it — "by construction" was the wrong claim.

What this library does instead, honestly: (1) **documents** the required
line prominently — a `@moduledoc` warning on the top-level `MobusMoney`
module and a README section, both stating verbatim the config a consumer
MUST carry (`config :ex_money, auto_start_exchange_rate_service: false`);
(2) ships `MobusMoney.ensure_fx_disabled!/0`, a runtime assertion a consumer
calls from its OWN `Application.start/2` (documented as a required adoption
step, and stated as such in each consumer's own follow-up change-set's
tasks), which raises immediately, naming the missing config, if
`Application.get_env(:ex_money, :auto_start_exchange_rate_service)` is not
`false` — turning a forgotten config line into a loud boot-time crash instead
of a silent, unaudited capability. This is weaker than "impossible by
construction" and the spec/proposal language is corrected to say so
precisely (a consumer's own boot check, not a library-side guarantee). This
library's own arithmetic (`add/2`, `sub/2`, `sum/2`, `compare/2`) rejects a
currency mismatch with an error tuple carrying both codes regardless of
whether the exchange-rate service is running; no public function accepts an
exchange rate, so even an un-configured consumer's FX service, if running,
is never reachable through this library's own API.

Alternative rejected: a library-side `config/config.exs`, as originally
written. Corrected above — Mix never loads it.

Alternative rejected: leave the exchange-rate service at its default and
rely solely on this library never calling `Money.to_currency/2`. Unused
capability that starts a network-polling process on every consumer's boot
is still a defect the 2026-09-06 ruling's spirit ("an unaudited FX
conversion is indistinguishable from an undisclosed markup") argues against;
`ensure_fx_disabled!/0` converts that risk into a boot-time failure a
consumer cannot silently ship past.

Alternative rejected: have `mobus_money` itself declare an OTP application
(`mod: {MobusMoney.Application, []}`) that calls `put_env` in `start/2` and
rely on that. Rejected above by the start-order argument — it would appear
to work in a dev/test run where `:ex_money`'s service start is lazy enough
to race favorably, and fail unpredictably in a real release depending on
supervision-tree timing, which is worse than an honest, always-loud
`ensure_fx_disabled!/0` check.

### D5. Persisted money is two columns and one schema helper (Ecto is optional)

`MobusMoney.Schema.money_fields/1(name)` declares `<name>_amount`
(`numeric(28,8)`) and `<name>_currency` (`varchar(3)`) together on an Ecto
schema, where `name` is the atom prefix a caller chooses (e.g. `:budget` →
`budget_amount`/`budget_currency`). **Corrected (PE-5, round-3
pre-execution, MINOR): the two functions that operate on a declared pair
were never pinned to take the SAME `name` atom as their second argument —
`MobusMoney.Schema.validate_money(changeset, name)` and
`MobusMoney.Schema.read_money(struct, name)`** (called from a changeset)
enforce: both null or both non-null, currency valid per `MobusMoney.Currency.valid?/1`,
amount not negative.

**Non-negativity, argued (F1.2, doc review round 1 — this was previously
asserted without rationale):** `money_fields/1` targets the quantities named
in this library's own surveyed consumers' current holdings — a budget cap, a
usage cost, a spend total (Atrapos's three columns; sil-diary4's two) — every
one of which is a magnitude, never a signed balance, in the code read for the
Consumers section above. The value type itself is NOT restricted this way
(`negative?/1` exists precisely because in-memory arithmetic can produce a
negative intermediate, e.g. comparing a spend against a cap); the constraint
is scoped to `money_fields/1`'s persisted pair specifically, not to
`MobusMoney.Money` generally. A future consumer needing a signed persisted
balance (a credit, a refund, a running account balance) does not fit
`money_fields/1`'s contract and is out of scope here — declared forward, not
silently possible by calling `validate_money/2` differently: **GC-5588's own
follow-up** (no separate Bee filed; this library has no consumer with a
signed-balance need today, and inventing the shape without one would be the
same unmotivated-hardening mistake this project's falsification discipline
(GC-5053) exists to prevent for code, applied here to schema design).

Alternative rejected: no non-negativity constraint (accept any amount
`money_fields/1` is given). Every surveyed consumer's holding is a magnitude;
accepting a negative silently would let a signed-arithmetic bug (this
library's own `sub/2` can produce a negative result) reach a persisted
budget/cost column undetected, where it would misrepresent a magnitude as a
debt with no consumer expecting that meaning.

**Corrected during pre-execution audit (PE-3, MAJOR — a half-set pair is
reachable outside `validate_money/2`'s reach: raw `psql`, a migration
backfill, or a hand-written test fixture, none of which run a changeset.
`read_money/2`'s original two-branch contract had no case for it, so an
implementer's only options were an undefined crash via `new!/2` or a silent,
wrong `{:error, :unknown_currency}` from `new/2` — neither matches the
SHALL.)** `MobusMoney.Schema.read_money/2` returns `{:ok, nil}` for a
null/null pair, `{:ok, money}` for a valid pair, and `{:error,
{:half_set_pair, missing_field}}` — where `missing_field` is `:amount` or
`:currency`, whichever of the pair is `nil` — not raising, for a pair where
exactly one column is set (PL-1, round-3 pre-execution librarian: the
round-3 text asserted the error "names which column is missing" while every
other site in the change-set pinned the contract as the bare atom
`:half_set_pair`, which carries no such diagnostic — fixed to actually carry
it, consistently, everywhere). A
consumer that has run `validate_money/2` on every write path never observes
the third case in practice; the function's contract still names it, because
this library does not control every path that can reach its own columns
(raw SQL, a migration, a fixture) and a named error is strictly better than
an unreachable-in-theory crash.

Ecto is declared
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
per-call behavior. **Corrected during pre-execution audit (PE-4/PL-3, MAJOR
— this sentence originally claimed a library-side `Application.put_env` that
D4's own fold already removed; this library performs no `put_env` anywhere.
D4's `ensure_fx_disabled!/0` READS a consumer's own config, it never writes
any config.** A library with several unrelated consumer applications
potentially running in the same BEAM release (unlikely today, but this
library must not assume otherwise) must not let one consumer's config
silently change another's rounding.

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
  per code; the currency registry's exponent reader (D1's public surface)
  reads it, never hardcodes it — the defect the superseded Atrapos design's
  hardcoded five-entry table would have reintroduced for any currency outside
  its list.
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
  half-even override; `to_integer_exp/1`/`from_integer/2` round-trip exact
  for a JPY and a EUR amount; `format/1` output for at least one 0-decimal
  and one 2-decimal currency; `sum/2` reduces over this module's own `add/2`
  and errors on a mixed-currency list the same way `add/2` does (never
  delegates to `Money.sum/2`, PE-5).
- Currency registry: `valid?/1` true for the full ISO 4217 set `ex_money`
  carries, false for a non-code string; `exponent/1` matches `ex_money`'s own
  data for a sample spanning 0, 2, and 3-decimal currencies;
  `default_rounding_mode/0` returns `:half_up` (falsifies D3 by asserting the
  non-`ex_money`-native value, not merely that a value is returned).
- Schema helper (conditionally compiled, tested only when Ecto is present in
  the test env's deps): `money_fields/1` defines both columns;
  `validate_money(changeset, name)` rejects a half-set pair, an unknown
  currency, and a negative amount; `read_money(struct, name)` returns
  `{:ok, nil}` for null/null, `{:ok, money}` for a valid pair, and
  `{:error, {:half_set_pair, missing_field}}` for a pair with exactly one
  column set, asserting `missing_field` matches which column was left nil
  (constructed directly on a struct, bypassing `validate_money/2`, to prove
  the reader itself refuses rather than crashing). **Corrected (PE-4,
  round-3 pre-execution, MINOR): the "Ecto absent" guard cannot be tested by
  stubbing `Code.ensure_loaded?/1` — it is a compile-time-evaluated stdlib
  function, already resolved by the time any ExUnit test runs, and cannot be
  mocked.** The real coverage for "does not require Ecto to compile when
  absent" is task 6.1's two separate `mix compile` runs (with and without
  the optional dependency present) — this Testing section and tasks.md 4.5
  now say so instead of naming an unimplementable unit test.
- FX-disabled guard: `ensure_fx_disabled!/0` raises when the test env's
  config for `:ex_money` is unset or `true`, and returns `:ok` when it is
  explicitly `false` — both branches exercised, falsifying the raise path
  first (not merely asserting the non-raising path, which alone would pass
  even if the function silently no-op'd).
- No test in this change-set exercises an actual consumer (Atrapos, MOBuS,
  sil-diary4) — this library has no adoption-site tests until each consumer's
  own follow-up change-set lands.
