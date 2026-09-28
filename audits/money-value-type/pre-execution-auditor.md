# Pre-Execution Audit — Bee 5588
Date: 2026-09-28T08:30:10Z
Branch HEAD: b9f7a2403738220501fcea360df25b8d8db541a7

Inputs read: proposal.md, design.md, tasks.md, specs/money/spec.md,
stage0b-roadmap-reality.md (+ stage0b-summary.json), ce-doc-review-round-1.md
(latest round), constraints.json, and the prior pre-execution round's report
(this file's predecessor, HEAD e35723e — its PE-1–PE-9 were folded at
e35723e/0515cf9/b9f7a24; this audit walks the POST-fold text). Upstream
ground truth re-verified fresh for this round: ex_money 6.2.1 and
localize 1.3.0 hex tarballs (re-extracted to /tmp/pe5588), the three
consumers' live trees, and this repo's scaffold state.

## Check 1: Execution walkthrough

Task graph is sound (1.1 → 2.x/3.x/4.x, 1.4 config feeds 5.1's tests, 6.x
verifies all; no task consumes an output a prior task fails to produce).
Every task now names its module/function and its real upstream binding:
3.1's translation layer matches ex_money's real shapes (`Money.new/2`
unknown-currency → `{:error, {Money.UnknownCurrencyError, _}}`,
money.ex:210-229); 3.2's currency-check-first add/sub/compare matches the
verified upstream mismatch shape (`{:error, {ArgumentError, "Cannot add
monies with different currencies. Received :EUR and :USD."}}`,
money.ex:1097-1103 — the structured-tuple interception is necessary and
correctly specified); 3.3's keyword-list `round/2` (`:rounding_mode` key,
money.ex:2348), `to_integer_exp/2` options→`Money.round/2` flow
(money.ex:2836), `{:USD, 20000, -2, ...}` example (money.ex:2820-2822),
`to_string/1` `{:ok, string}` (:831), `from_integer/2` (IQD 3-digit example,
money.ex:2905-2925); 2.1's registry facade names only functions that exist
(currency.ex:344 `currency_for_code/1`, :267 `known_tender_currencies/0`;
`valid?`/`exponent`/`all_codes` confirmed absent upstream — the facade, not
delegation, is correctly specified); `compare!/2` consistently NOT shipped
across proposal/design/tasks/spec; sum/2's reduce_while handles the empty
list and mid-list mismatch (spec.md's own scenarios). Three findings:

PE-1
- Severity: MINOR
- Document: openspec/changes/money-value-type/design.md:166
  > "Enum.reduce_while(money_list, {:ok, zero(currency)}, fn m, {:ok, acc} ->"
  (same seed at tasks.md:63; design.md:137 / tasks.md:51 pin `zero/1` as a
  direct delegation: "`zero/1(currency_code)` → `Money.zero/1`")
- Code reference: ex_money-6.2.1 lib/money.ex:3011-3015 — `Money.zero/2`
  validates first (`with {:ok, currency_code} <- validate_currency(...)`)
  and returns `{:error, {Money.UnknownCurrencyError, _}}` (not a raise, not
  a bare money) for an unknown code. Composed into the pinned seed
  `{:ok, zero(currency)}`: an empty list with an unknown stated currency
  returns `{:ok, {:error, {Money.UnknownCurrencyError, _}}}` (garbage shape,
  violating spec.md's `{:ok, zero_money}` SHALL for that input class); a
  non-empty list binds `acc` to that error tuple, and this library's own
  `add/2` pattern-match on `.currency` then raises `FunctionClauseError` —
  a crash path on exactly the input class (`unknown currency`) that
  `new/2` refuses with a reason atom, breaking the library's own no-raise
  posture in `sum/2`.
- Why-it-blocks: (MINOR) unreachable via any spec scenario (all use valid
  stated currencies) and a one-line fix (validate the seed before folding),
  but as pinned the pseudocode ships a crash on bad input the rest of the
  API treats as an `{:error, :unknown_currency}` tuple.

PE-2
- Severity: MINOR
- Document: openspec/changes/money-value-type/tasks.md:86-88 (task 3.4)
  > "3.4 Falsifying tests per Testing section: float/nil refusal, exact
  > 0.056+0.044 arithmetic, mixed-currency error carrying both codes (via"
  (enumeration continues through round-trips; no `mult/2` float-multiplier
  case) and tasks.md:111-112 (task 4.5)
  > "4.5 Falsifying tests: half-set pair rejected, unknown currency
  > rejected, negative amount rejected, null/null reads as `{:ok, nil}`."
- Code reference: specs/money/spec.md:165-167 (R6 scenario: "`mult/2` is
  called with a float multiplier → returns `{:error, :float_amount}`") and
  specs/money/spec.md:138-141 (R5 scenario: half-set pair reaching
  `read_money/2` directly "errors, never crashes") + design.md:565 ("constructed
  directly on a struct, bypassing `validate_money/2`"). Upstream makes the
  mult case load-bearing: `Money.mult/2` ACCEPTS floats
  (ex_money-6.2.1 lib/money.ex:1243-1245, `Decimal.from_float/1`), so the
  refusal exists only in this library's guard and nothing upstream or in
  the enumerated tests would catch a plain delegation silently violating
  R6; the read_money case is the exact regression the PE-3-prior fold was
  about. Both spec scenarios are unambiguous, but the task enumerations
  (the implementer's checklist) omit both tests, and design's Testing
  section omits the mult one.
- Why-it-blocks: (MINOR) discoverable from spec.md's own scenarios, but the
  execution document's test list — which tasks 3.4/4.5 present as
  exhaustive ("Falsifying tests: ...") — misses the only tests that pin two
  SHALL-level behaviors with no upstream enforcement.

## Check 2: New prerequisite claims

No new ghosts. Every code-surface claim added after Stage 0b (4ac2a90) —
via the 8220dcc, e35723e, 0515cf9, and b9f7a24 folds — was re-verified
against freshly extracted sources this round:

- ex_money money.ex: `new/2` currency-first head at :199 (plus amount-first
  at :215 — delegation as specified works); add/sub/compare mismatch =
  `{:error, {ArgumentError, prose}}` (:1081/:1097-1103, :1171, :1391);
  `mult/2` at :1239 (int/float/Decimal heads); `round/2` keyword opts with
  `:rounding_mode` key and `@default_rounding_mode :half_even` at :86/:2348;
  `to_integer_exp/2` at :2820-2845 (doc example `{:USD, 20000, -2, ...}`,
  options flow into `Money.round/2`); `from_integer/2` at :2912 area (IQD
  "20.012" 3-digit example); `zero/1` at :3005; `zero?/1` at :3045;
  `negative?/1` at :3160; `to_string/1` `{:ok, string}` @spec at :831;
  `sum/2`'s second argument is rates defaulting
  `latest_rates_or_empty_map()` and it converts via `to_currency/3`
  (:1855-1876) — the never-delegate-to-`Money.sum/2` rule is grounded.
- currency.ex: `currency_for_code/1` at :344 returning
  `{:ok, %Localize.Currency{}}`; `known_tender_currencies/0` at :267;
  `valid?/1`/`exponent/1`/`all_codes/0` confirmed absent from the entire
  package (grep over lib/ returns nothing).
- localize-1.3.0 lib/localize/currency.ex:25-54: struct carries both
  `digits: non_neg_integer()` and `iso_digits: non_neg_integer() | nil` —
  D2's `iso_digits || digits` fallback is implementable and mirrors
  ex_money's own nil-fallback usage.
- FX defaults (task 1.4's characterization): application.ex —
  `Money.get_env(:auto_start_exchange_rate_service, true, :boolean)`
  (default true); exchange_rates.ex:151 `@default_retrieval_interval :never`
  feeding `default_config/0` (:215-219), and retriever.ex init only
  schedules fetches `if is_integer(config.retrieve_every)` (:327) — so with
  no config the service starts but never polls: "startup noise rather than
  network calls" is accurate (the moduledoc's 300_000 block is stale
  upstream prose, not the governing path).
- ex_money mix.exs:120-127: `{:json_polyfill, ...}` behind
  `Code.ensure_loaded?(:json)` — design's PE-6-prior correction (OTP-26
  polyfill path exists) is accurate.
- Seaker prior art re-confirmed live: ~/Sites/www/config/config.exs:36-43
  (`config :ex_money, open_exchange_rates_app_id: ...`,
  `exchange_rates_retrieve_every: 7_200_000, ...`).

## Check 3: Spec-code gap

All cited APIs match current code. Repo self-citations: lib/ empty
(.gitkeep only); mix.exs deps/0 is ex_doc-only with the scaffold comment;
`package/0` files list excludes config/ and no config/ dir exists (task 1.4
creates it); README still carries "Status: scaffold only" (task 6.4
replaces it); .tool-versions erlang 28.4.2 / elixir 1.19.5-otp-28; mix.lock
carries only the ex_doc chain (no money/decimal/ecto entry);
openspec/specs/ correctly absent pre-archive. Consumer citations
re-checked live and all current: MOBuS money.ex is 388 lines with
`@default_currency "EUR"` (:49) and `round(nil, _precision), do:
Decimal.new(0)` (:185), .tool-versions erlang 26.2.1 (GC-5587 premise
accurate as stated); sil-diary4 session_manager.ex carries 10 references to
the two cent fields with no money/decimal dep in its mix.exs; Atrapos
spend_aggregator.ex:56 `spend_usd = total_cents / 100.0`. The only
spec-vs-upstream gap found is PE-1's seed composition above — a pseudocode
hole, not a citation error (every named function/arity/return-shape
citation resolves).

## Check 4: Undecided constraints

Every post-fold SHALL/SHALL NOT and non-goal traces to an argued rationale:
R1 → 2026-09-06 ruling (proposal) + D1 (two `Alternative rejected:`); R2 →
same ruling + D1's check-first correction block + D4; R3 → D4 (three
rejected alternatives; Mix-never-loads-dependency-config and start-order
arguments); R4 → D2 (rejected curated list) + D3 (rejected `:half_even`,
explicit-override rationale); R5 → D5 (four rejected alternatives, the
argued non-negativity block, the argued half-set-reachability block, and
the PE-5-prior same-name-atom corrections); R6 → inline no-speculative-
functions argument (PE-9/F1.5, PE-6/PE-7) + D1's "no function ships
speculatively" principle. Non-goals all argued: FX → GC-5708 (D4 +
Counterparts §2/§3); other storage shapes → D5 alternatives + Counterparts
§2; `mobus_billing`/`mobus_ledger` → Counterparts §2; signed persisted
balance → D5's argued forward-declaration. The round-3 PE-6 gap
(unargued `compare!/2` SHALL) is resolved — the function is removed and the
removal itself carries the argument. One process-level carry:

PE-3
- Severity: NIT
- Document: audits/money-value-type/constraints.json:2
  > "extracted_at": "2026-09-28T07:16:03.169214+00:00"
- Code reference: audits/money-value-type/constraints.json — index built at
  4ac2a90; several entries quote pre-fold text dead at HEAD (e.g. its
  spec.md:39 entry "The system SHALL configure `ex_money`'s
  `auto_start_exchange_rate_service`" — the requirement is now the
  boot-assert form) and it predates the sixth requirement entirely.
- Why-it-blocks: (NIT) the GC-5052 pass above was run against the current
  post-fold spec text directly, so nothing was missed, but any downstream
  gate consuming constraints.json mechanically will audit a document that
  no longer exists; re-extract before such use. Carried from round 3
  (PE-8), still unfixed.

## Summary
BLOCKER: 0
MAJOR: 0
MINOR: 2
NIT: 1

VERDICT: PROCEED
BLOCKER_COUNT: 0
