# Pre-Merge Audit — Bee 5588
Date: 2026-09-28T09:37:36Z
Branch: gc/5588-mobus-money-v0.1
Diff scope: master..1ef2adccfde7da056805f8f876a3342ffeb31600
Files changed: 18
Lines added/removed: +2372/-22

Scope notes: master was a scaffold (`lib/.gitkeep` only, still tracked); every
lib/test/config file in this diff is new, and the README/mix.exs/.audit-config.yml
edits replace scaffold-status text exactly as tasks.md 1.1/6.4 direct. Stage 0b
(`audits/money-value-type/stage0b-roadmap-reality.md`) was computed at 4ac2a90 —
a docs-only commit inside this same diff range, taken before implementation; its
3 confirmed surfaces are doc/scaffold files and its 18 forward declarations are
the surfaces this diff now realizes. No pre-existing code exists to break or
shadow (Check 5 clean by construction, verified: no function modified, only
added).

## BLOCKER findings
None.

## MAJOR findings
None.

## MEDIUM / MINOR / NIT / INFO

### MEDIUM

**F1 — `@spec` on `from_integer/2` misstates the contract; un-normalized upstream error escapes the library boundary.**
File: lib/mobus_money/money.ex:248-251
`MobusMoney.Money.from_integer/2` is declared `from_integer(integer(), Money.Currency.code()) :: t()` and delegates directly to `Money.from_integer/3`. Upstream (`deps/ex_money/lib/money.ex:2914-2919`) runs `validate_currency/1` inside a `with`, so for an unknown code it returns `{:error, {Money.UnknownCurrencyError, _}}` — an input matching the declared parameter types (`from_integer(5, :NOPE)`) produces a return that is neither `t()` nor this library's reason-atom error shape. It is the only constructor in the module without a normalized error path; design D1 pins "delegated directly (no internal rounding to pin)", so the delegation itself is per-design — the defect is the `@spec` lying about the return type at a boundary every other function normalizes. (Same class, weaker: `mult/2`'s `@spec` omits upstream's `{:error, {ArgumentError, _}}` clause for non-numeric multipliers, money.ex:193-196.) Spec R6 imposes no error path for `from_integer/2`, so this is not a REQ violation.
Suggested fix: widen the `@spec` and either normalize the unknown-currency case to `{:error, :unknown_currency}` (matching `new/2`/`zero/1`) or document the delegation boundary explicitly.

### MINOR

**F2 — Dangling edit fragment in the spec delta.**
File: openspec/changes/money-value-type/specs/money/spec.md:63-65
The "unknown stated currency" scenario's THEN clause already ends with "without evaluating any list element"; a stray line "without evaluating the third element" follows it — a leftover from folding the round-3/4 scenario edits. This delta folds into `openspec/specs/money/spec.md` at archive, so the garbled text propagates into the canonical spec.
Suggested fix: delete the stray line before `openspec archive`.

### NIT

**F3 — `read_money/2` is the only public function without an `@spec`.**
File: lib/mobus_money/schema.ex:140
Every other public function in the diff carries a `@spec`; `read_money/2` documents its three-shape return in `@doc` only.
Suggested fix: add `@spec read_money(map(), atom()) :: {:ok, Money.t() | nil} | {:error, term()}`.

**F4 — Private `negative?/1` crashes on a raw float amount placed via `put_change`.**
File: lib/mobus_money/schema.ex:131-132
`validate_money/2`'s private `negative?/1` covers `%Decimal{}` and integer; a float put directly on the changeset (bypassing `cast`, which would coerce to Decimal) raises `FunctionClauseError` instead of adding a validation error. Out of Ecto's own `:decimal` contract, hence NIT.
Suggested fix: add an `is_float/1` clause or let it crash deliberately with a comment.

### INFO

**F5 — constraints.json line numbers are stale relative to HEAD.**
File: audits/money-value-type/constraints.json
The extraction ran at 4ac2a90; the round-3/4 doc-fold commits afterwards shifted spec.md text (e.g. entry #21 at "spec.md:21" quotes the superseded pre-F1.1 wording "SHALL configure ex_money's…"; entry #26 quotes the superseded bare-`nil` `read_money/2` contract). All 29 entries were mapped by substance in this audit; the current spec implements the corrected wording of both.
Suggested fix: re-extract constraints.json after future doc folds, or record the extraction SHA in the table.

**F6 — `MobusMoney.Money` has no struct of its own; values are raw `Money.t()`.**
File: lib/mobus_money/money.ex:19-21
Per design D1 (intentional, documented in `@moduledoc` and tests): the module is a facade and returns ex_money structs directly. Observation for future consumers — no action.

## Stated constraints (Check 6)

Judged at each function AND every call site in the diff that consumes its
result. No call site in the diff discards a `{:error, _}` on a
constraint-governed path (no `_ =` binds, no dropped tuples in lib/ or test/ —
the GC-3753 caller-orphan pattern has no analogue here).

| # | file:line | kind | verdict | evidence / finding |
|---|-----------|------|---------|--------------------|
| 1 | proposal.md:8 | prohibition | HONOURED | Defect described ("currency … never by a type") is what the diff fixes: typed value type (money.ex:56-73) + typed two-column pair (schema.ex:59-65) |
| 2 | proposal.md:22 | prohibition | HONOURED | Amount and currency travel together in every public value: `Money.t()` wrapper, persisted pair carries `<name>_currency` (money.ex:19-21, schema.ex:140-158) |
| 3 | design.md:37 | prohibition | HONOURED | No conversion anywhere: mismatch is refused before delegation (money.ex:108-119); arithmetic delegates to Decimal-based `Money.add/sub` for same-currency operands only |
| 4 | design.md:176 | prohibition | HONOURED | Rejected-alternative substance honoured doubly: no `to_currency` call in lib (grep clean) AND `ensure_fx_disabled!/0` shipped (mobus_money.ex:47-60) |
| 5 | design.md:179 | prohibition | HONOURED | Capability made unreachable through this API: no public function accepts a rate (grep clean); boot check turns silent start into a crash |
| 6 | design.md:180 | prohibition | HONOURED | Same evidence as row 4/5: no FX surface; config/config.exs:9 keeps the service off in this library's own runs |
| 7 | design.md:224 | prohibition | HONOURED | No `Application.get_env` for per-call behavior in lib (grep clean); sole env read is `ensure_fx_disabled!/0` (D4-sanctioned boot assertion, reads only, never writes — D6's own correction) |
| 8 | design.md:251 | prohibition | HONOURED | `exponent/1` reads `currency_for_code` → `iso_digits \|\| digits`; no hardcoded exponent table (currency.ex:47-54) |
| 9 | design.md:262 | prohibition | HONOURED | Only the two-column shape ships: `money_fields/1` declares exactly two plain fields (schema.ex:59-65) |
| 10 | design.md:274 | prohibition | HONOURED | No composite-type or jsonb code in the diff; moduledoc documents the plain-column migration shape |
| 11 | design.md:279 | prohibition | HONOURED | No FX/conversion code; GC-5708 forward-tracked in proposal and README |
| 12 | design.md:286 | prohibition | HONOURED | No `mobus_billing`/`mobus_ledger` module in the diff |
| 13 | design.md:297 | prohibition | HONOURED | Withheld by construction: no function accepts a rate; mismatch errors regardless of service state (money.ex:108-119) |
| 14 | design.md:327 | prohibition | HONOURED | `new(nil, _)` → `{:error, :nil_amount}` matched first (money.ex:56); test asserts nil ≠ real zero (money_test.exs:34-40); Decimal arithmetic exact |
| 15 | design.md:330 | prohibition | HONOURED | Mismatch tuple carries both codes as atoms from this library's own check-first clause (money.ex:111-112, 117-119); never a converted value |
| 16 | spec.md:5 | requirement | HONOURED | `MobusMoney.Money` wraps `Money.t()` (R1); `new/2` four-reason contract implemented money.ex:56-73 |
| 17 | spec.md:7 | requirement | HONOURED | All four reasons reachable and tested (`:float_amount`, `:nil_amount`, `:unparseable_amount` via "abc", `:unknown_currency`) |
| 18 | spec.md:9 | prohibition | HONOURED | Float and nil matched before delegation; nil never zeroed (money.ex:56-58) |
| 19 | spec.md:10 | requirement | HONOURED | `new!/2` raises `InvalidMoneyError` on exactly the four conditions (money.ex:82-88), all four raise-tested |
| 20 | spec.md:25 | requirement | HONOURED | `add/sub/compare` match both `.currency` fields first, structured tuple from own code, delegation only for same-currency (money.ex:105-119); `sum/2` folds over own `add/2` with validated seed (money.ex:150-165) |
| 21 | spec.md:28 | prohibition | HONOURED | No function accepts an exchange rate (grep clean across lib/) |
| 22 | spec.md:21 | requirement | HONOURED | Extracted text is the superseded pre-F1.1 wording; corrected D4 mechanism implemented: `ensure_fx_disabled!/0` (mobus_money.ex:47-60), this repo's own test config sets the flag (config/config.exs:9), no consumer-config claim anywhere |
| 23 | spec.md:51 | requirement | HONOURED | `exponent/1` returns JPY 0 / EUR-USD-GBP 2 / BHD-IQD 3 from the registry, nil for unknown (currency.ex:47-54, tested) |
| 24 | spec.md:56 | requirement | HONOURED | `round/2` mode argument defaults to `default_rounding_mode/0` = `:half_up`; explicit `:half_even` override tested (money.ex:218-221) |
| 25 | spec.md:72 | requirement | HONOURED | `money_fields/1` declares the `numeric(28,8)`/`varchar(3)` pair (schema.ex:59-65) |
| 26 | spec.md:74 | requirement | HONOURED | `validate_money/2` rejects half-set (both directions), unknown currency, negative amount; null/null and zero accepted (schema.ex:82-128, all tested) |
| 27 | spec.md:77 | requirement | HONOURED | Extracted text is the superseded bare-`nil` wording; corrected contract implemented: `{:ok, nil}` / `{:ok, money}` / `{:error, {:half_set_pair, :amount\|:currency}}`, never raises (schema.ex:140-158, bypass-tested) |
| 28 | spec.md:78 | requirement | HONOURED | `Ecto` declared `optional: true` (mix.exs:36); value type/registry have no Ecto reference |
| 29 | spec.md:79 | prohibition | HONOURED | `Code.ensure_loaded?(Ecto)` guard wraps every function in `MobusMoney.Schema` (schema.ex:46); task 6.1's two compile runs recorded clean (commit 4f7bdc6) |

## Summary
BLOCKER: 0
MAJOR: 0
MEDIUM: 1
MINOR: 1
NIT: 2
INFO: 2

All six REQ groups in specs/money/spec.md are implemented with matching
arity, parameter names, and error paths, each backed by tests including the
load-bearing falsification cases (mult float guard, middle-of-list mismatch,
seed validation before the fold, half-set reader bypass). No dead code, no
orphan config, no security vectors (no secrets, no SQL, no routes, no eval,
no PII). Check 5: master was a codeless scaffold — nothing pre-existing to
break; Stage 0b's confirmed surfaces are this diff's own doc commits. Check 6:
all 29 stated constraints HONOURED at implementation and at every call site
in the diff.

VERDICT: PASS
BLOCKER_COUNT: 0
DEFERRED_COUNT: 4
