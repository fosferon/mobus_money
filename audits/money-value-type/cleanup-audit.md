# Cleanup Audit — Bee 5588
Date: 2026-09-28T09:53:30Z
Cleanup commits audited: 2
Commit range: 8e73479..cc58cbd

Cleanup summary source: commit messages of the two cleanup commits
(`8e73479` claims F1, LIB-2; `cc58cbd` claims LIB-1, F3, F4). Original
findings read from `audits/money-value-type/pre-merge-auditor.md` and
`pre-merge-librarian.md`. No separate cleanup-summary file exists on disk.

## Check 1: Coverage — PASS
Findings claimed: 5
Findings verified fixed: 5
Findings NOT actually fixed: none

Per-finding verification against the cumulative diff `1ef2adc..cc58cbd`
and the current code:

- **F1 (MEDIUM)** — `from_integer/2` spec lied and leaked ex_money's raw
  error tuple. FIXED: spec widened to
  `{:ok, t()} | {:error, :unknown_currency}` (money.ex:262-263) and the
  body normalizes via a `case` matching upstream's actual shapes —
  `Money.from_integer/3` returns a bare `%Money{}` on success and
  `{:error, {module, String.t()}}` on failure (deps/ex_money/lib/money.ex:2913-2926),
  so `%Money{} -> {:ok, _}` / `{:error, _} -> {:error, :unknown_currency}`
  is faithful; the reason atom now matches `new/2`/`zero/1` exactly as the
  suggested fix proposed. The weaker cousin (`mult/2`'s undeclared
  `{:error, {ArgumentError, _}}` clause) was handled by the suggested
  alternative — documenting the delegation boundary in `@doc`
  (money.ex:172-175). Backed by a new normalization test plus the
  forced shape-change updates to three existing asserts (money_test.exs:179-196, 265-278).
- **F3 (NIT)** — `read_money/2` had no `@spec`. FIXED: schema.ex:146-149,
  covering all three documented shapes (tighter than the auditor's
  suggested catch-all `{:error, term()}`).
- **F4 (NIT)** — `negative?/1` FunctionClauseError on a raw float via
  `put_change/2`. FIXED: `is_float/1` clause at schema.ex:130-133 with a
  comment explaining the put_change-only arrival path; falsifying test at
  schema_test.exs:114-127 asserts a validation error (never a raise).
- **LIB-1 (MINOR)** — missing specs on `money_fields/1`, `validate_money/2`,
  `read_money/2`. FIXED: schema.ex:52, 71, 146-149 respectively.
- **LIB-2 (MINOR)** — `round/1` default-arg arity unspec'd. FIXED:
  `@spec round(t()) :: t()` at money.ex:221, alongside the existing
  arity-2 spec.

Not claimed by cleanup (deferred per the pre-merge auditor's
DEFERRED_COUNT: 4): F2 (spec-delta stray line, MINOR), F5, F6 (INFO).
No claim, no coverage obligation.

## Check 2: Scope — PASS
Unrelated changes: none

Diff touches exactly four files; every hunk maps to a declared finding:

- `lib/mobus_money/money.ex` — from_integer spec+normalization and the
  mult/2 doc note (F1), round/1 spec (LIB-2).
- `lib/mobus_money/schema.ex` — three public specs (LIB-1/F3), float
  guard clause (F4).
- `test/mobus_money/money_test.exs` — new unknown-currency test plus
  mechanical updates to asserts broken by F1's return-shape change.
- `test/mobus_money/schema_test.exs` — the F4 falsification test only.

No refactoring beyond the findings, no feature additions, no
finding-unrelated files touched.

## Check 3: Regression — PASS
Compile: clean (`mix compile --warnings-as-errors` exits 0, no output)
Tests: pass (53 tests, 0 failures)
Prior fixes intact: yes

- Both prior audits (pre-execution e35723e fold and pre-merge at 1ef2adc)
  report BLOCKER_COUNT: 0 — no blocker fixes exist to regress; the
  constraint table's 29 HONOURED verdicts were spot-checked against the
  post-cleanup code (from_integer normalization touches no
  constraint-governed path; the currency-check-first clauses, no-FX
  surface, and optional-Ecto guard are all present verbatim).
- The cleanup diff is additive except the two finding-mandated edits
  (from_integer body, negative?/1 clause); the Stage 4 core
  (929fabd..abe76f7) is untouched.
- Note (pre-existing, not a regression): `mix test`'s compile pass emits
  one Elixir 1.18 typing-violation warning at currency_test.exs:61
  (`!= :half_even` on a spec'd `:half_up` return) — that file predates
  the cleanup commits and is not in the diff; `mix compile
  --warnings-as-errors` on lib/ is clean.

VERDICT: PASS
