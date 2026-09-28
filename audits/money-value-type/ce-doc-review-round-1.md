# Grounded Doc Review — Bee 5588 — Round 1
Date: 2026-09-28T07:39:11Z
Ground truth: mix.exs,README.md,openspec/AGENTS.md,.audit-config.yml,.tool-versions
Prior round: n/a (round 1)
Branch HEAD: 8220dccc23726844d402024bf3939ef2ae06c0fd

Note: a superseded round-1 draft (HEAD 4ac2a90, since overwritten by this
dispatch) raised F1.1 (library config.exs FX mechanism, P0) and F1.2
(unargued non-negativity, P1); both were folded at 8220dcc (D4 rewritten,
D5 argued). Per the round-1 contract all findings below are NEW; the
change-set's own inline "(F1.1, doc review)" / "(F1.2, doc review round 1)"
references point at that superseded draft, not at this report's IDs.

## Resolved from prior round
- n/a (round 1)

## Carried from prior round
- n/a (round 1)

## New findings

### P0
- None.

### P1

F1.1
- Severity: P1
- Document: openspec/changes/money-value-type/design.md:294
  > "The one process-wide `Application.put_env` this library
  performs (D4, disabling the FX service) is infrastructure-off"
- Ground truth: openspec/changes/money-value-type/design.md:219-223
  > "(`mod: {MobusMoney.Application, []}`) that calls `put_env` in `start/2` and
  rely on that. Rejected above by the start-order argument"
  (design.md is a declared ground_truth_source per .audit-config.yml:14-19)
- Classification: NEW
- Why-it's-real: An implementer reading D6 literally would reintroduce the
  library-side `Application.put_env`/`Application.start/2` mechanism that the
  corrected D4 (design.md:219-224) explicitly rejected as racing
  `:ex_money`'s already-started supervision tree, because the F1.1 fold
  commit (8220dcc) rewrote D4/tasks/spec but left D6's sentence asserting a
  `put_env` this library no longer performs anywhere.

F1.2
- Severity: P1
- Document: openspec/changes/money-value-type/tasks.md:15-18
  > "`MobusMoney.Currency`: `valid?/1`, `exponent/1`, `all_codes/0`,
  `default_rounding_mode/0` (returns `:half_up`), each delegating to
  `Money.Currency` except `default_rounding_mode/0`."
  (same claim at design.md:133 "a facade over `Money.Currency`: `valid?/1`,")
- Ground truth: ex_money 6.2.1 (hex tarball ~/.hex/packages/hexpm/ex_money-6.2.1.tar),
  lib/money/currency.ex:125-388 — the module's entire public surface is
  `new/2`, `build/2`, `configured?/1`, `known_current_currencies/0`,
  `known_historic_currencies/0`, `known_tender_currencies/0`,
  `configured_currency_specs/0`, `private_currencies/0`,
  `private_currency_codes/0`, `currency_for_code/1`,
  `private_or_custom_code?/1`; `valid?/1`, `exponent/1`, and `all_codes/0`
  do not exist on `Money.Currency`.
- Classification: NEW
- Why-it's-real: An implementer following task 2.1 would write
  `defdelegate valid?(c), to: Money.Currency` (and friends), which compiles
  but raises `UndefinedFunctionError` on first call because none of the three
  named delegation targets exist in the pinned `~> 6.2` (the real surface is
  `currency_for_code/1` returning `{:ok, %Localize.Currency{}}` whose
  `:rounding` field carries the exponent, plus `known_tender_currencies/0`),
  so the task must be rewritten to name the real functions before
  implementation.

F1.3
- Severity: P1
- Document: openspec/changes/money-value-type/design.md:38-39
  > "integer minor-unit conversion
  is exact or an error"
  (same probe claim at proposal.md:34 "integer-minor-unit conversion")
- Ground truth: ex_money 6.2.1 lib/ — `grep -rn "minor" lib/` returns zero
  matches; no `to_minor_units`/`from_minor_units`/`to_major_units` function
  exists anywhere in the package (full def scan of lib/money.ex), so the
  2026-09-26 probe bullet attributes to ex_money 6.2.1 an API it does not
  have.
- Classification: NEW
- Why-it's-real: An implementer following task 3.3 (tasks.md:33
  `to_minor_units/1`, `from_minor_units/2`) would search ex_money for the
  upstream conversion the design says was verified and find nothing, then
  hand-write the exponent arithmetic (JPY ×10⁰ vs BHD ×10³) as fresh
  correctness-bearing code whose error contract (non-integer input, negative
  minor units, refusal shape) is stated in no document.

F1.4
- Severity: P1
- Document: openspec/changes/money-value-type/specs/money/spec.md:93-94
  > "`read_money/2` SHALL return `nil` for a null/null pair and a
  `MobusMoney.Money` otherwise."
  (same contract at design.md:262-263)
- Ground truth: openspec/changes/money-value-type/specs/money/spec.md:7-8
  > "`new/2` SHALL return `{:ok, money}` or `{:error, reason}` with `reason` one of"
  — R1's constructor cannot produce a `MobusMoney.Money` from a nil currency,
  while D5 (design.md:231-263) enforces pairing only at the changeset level:
  `money_fields/1` declares two independent nullable columns with no
  DB-level pairing constraint.
- Classification: NEW
- Why-it's-real: An implementer following task 4.4 would call `new!/2` (or
  `new/2`) on a half-set row — reachable via migration backfill, `psql`, or
  the hand-written fixtures D5 itself invokes two plain columns to enable —
  and either crash (`new!`) or return an error tuple, neither of which the
  SHALL's two-branch contract permits, so no implementation satisfies R5 as
  written for that input.

### P2 / NIT

F1.5
- Severity: P2
- Document: openspec/changes/money-value-type/design.md:113-117
  > "consumers' documented needs (no function ships speculatively): `new/2`,
  ... `compare!/2` (for call sites where a currency mismatch is unreachable
  by construction — none in this library itself; documented for a consumer's
  own envelope-style use)"
- Ground truth: openspec/changes/money-value-type/specs/money/spec.md:5-94
  — the five ADDED requirements cover only `new/2`/`new!/2`, `add/2`,
  `sub/2`, `sum/2`, `compare/2`, `ensure_fx_disabled!/0`, `exponent/1`,
  `default_rounding_mode/0`, `round/2`, `money_fields/1`, `validate_money/2`,
  `read_money/2`; `mult/2`, `compare!/2`, `zero/1`, `negative?/1`, `zero?/1`,
  `format/1`, `to_minor_units/1`, `from_minor_units/2`, `all_codes/0`
  (design.md:113-119, tasks.md 3.2-3.3) appear in no requirement
  (specs/** is the archive-surviving surface per .audit-config.yml:14-19).
- Classification: NEW
- Why-it's-real: An implementer completing tasks 3.2-3.3 would ship a third
  of the public API whose contracts (`compare!/2` raising on mismatch,
  `mult/2`'s Decimal-or-integer domain, `to_minor_units/1`'s refusal shape)
  live only in design.md/tasks.md — both archived away by task 7.2 — because
  the spec delta states none of them; and `compare!/2`'s own parenthetical
  ("none in this library itself; documented for a consumer's own
  envelope-style use") contradicts D1's "no function ships speculatively"
  claim in the same sentence.

Pass 4 (GC-5052) note: all 25 `without_rationale` machine flags re-checked
by hand; each is either problem-statement text (describing consumer
defects), a Testing-section restatement of decided behavior, argued inline
in its context, or covered by a D1-D7 `Alternative rejected:` paragraph —
zero undecided constraints remain (the two the superseded draft raised are
now argued at design.md D4 and D5).

## Summary
P0_NEW: 0
P0_CARRIED: 0
P0_RESOLVED: 0
P1_NEW: 4
P1_CARRIED: 0
P1_RESOLVED: 0
P2_NEW: 1
NIT_NEW: 0

TOTAL_P0_REMAINING: 0
TOTAL_P0_PRIOR_ROUND: 0

CONVERGENCE_STATUS: N/A
  N/A = round 1

VERDICT: PROCEED
