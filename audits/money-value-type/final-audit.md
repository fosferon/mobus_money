# Final Pre-Merge Audit — Bee 5588
Date: 2026-09-28T10:16:54Z
Branch: gc/5588-mobus-money-v0.1
Diff scope: master(8182fa9)..HEAD(b38fc499c8f76d1effa64e9c3580f1a562412293)
Files changed: 18 (+2425/−22)

## Verification results

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| V1 | Compile clean | PASS | `mix compile --warnings-as-errors` exit 0, zero warnings, no output (dev env). Note: `mix test`'s test-env compile emits one Elixir typing-violation warning at test/mobus_money/currency_test.exs:61 (`!= :half_even` against the spec'd `:half_up` return) — from Stage 4 commit d549fca, pre-dates cleanup, tests still pass; V1's defined command is clean |
| V2 | Tests green | PASS | 53 tests, 0 failures, exit 0 (currency 6 + money 32 + schema 12 + top-level 3) |
| V3 | Spec compliance | PASS | All 6 REQ groups in specs/money/spec.md implemented with correct arity + return shapes: R1 new/2 four reasons + new!/2 raises (money.ex:52-84); R2 add/sub/compare check-first structured mismatch + sum/2 seed-validated fold, no empty-list raise (money.ex:106-165); R3 ensure_fx_disabled!/0 raises naming the config (mobus_money.ex:53-67); R4 exponent/1 + default_rounding_mode/0 :half_up + round/2 defaulted (currency.ex:42,69; money.ex:215); R5 money_fields/1 + validate_money/2 + read_money/2 three-shape half-set contract, Ecto optional (schema.ex:53,72,150; mix.exs:37); R6 mult float refusal + zero/negative?/zero?/format/to_integer_exp/from_integer/all_codes, no compare!/add!/sub! anywhere (money.ex:176-272, currency.ex:54; grep clean). Every spec scenario has a matching test |
| V4 | Prior findings | PASS | Zero BLOCKER/MAJOR ever filed: pre-execution rounds (PE-1..PE-9) BLOCKER 0, all folded pre-implementation and verified implemented (sum seed validation, mult float test, half-set bypass test all present); ce-doc-review round-1 P1s folded pre-execution (D4 rewritten, real upstream surface, from_integer pair, R6 added, compare! removed); pre-merge audit BLOCKER 0/MAJOR 0, its MEDIUM F1 fixed at 8e73479 (from_integer normalization money.ex:261-267), MINOR F2 fixed at b38fc49 (stray spec line gone — spec.md:63 now ends "without evaluating any list element"), NITs F3/F4 fixed at cc58cbd (schema.ex specs :53,:72,:146-149 area, float clause :133 + falsifying test schema_test.exs:114-127); librarian LIB-1/LIB-2 fixed (specs present). cleanup-audit 3/3 checks PASS; its deferred F2 subsequently fixed; F5/F6 are INFO with no code obligation |
| V5 | No regressions | PASS | Stage 6 filed 0 BLOCKERs (nothing to revert); substantive re-check at HEAD after Stage 7 cleanup + two doc-fold commits: currency-check-first add/sub/compare intact (money.ex:106-131), sum/2 seed validation + reduce_while intact (money.ex:150-165), mult float guard intact (money.ex:176), half-set reader intact (schema.ex:150-170), ensure_fx_disabled!/0 intact (mobus_money.ex:53-67), optional-Ecto guard intact (schema.ex:30), from_integer cleanup normalization intact and tested (money.ex:261-267, money_test.exs:186-189); both post-cleanup commits are doc-only (b38fc49 spec text, bf917bc @doc/@spec/@impl on InvalidMoneyError.message/1 — present, invalid_money_error.ex:14-18) |
| V6 | Roadmap consistency | PASS | Stage 0b (computed at 4ac2a90): 3 confirmed surfaces (doc/scaffold files), ghost_count 0, 18 forward declarations — all realized by this diff. Every ticked task surface resolves to real code: 1.1 mix.exs:33,37; 1.2 mobus_money.ex:16-40; 1.3 spec delta on disk (openspec validate strict PASS — validate-strict.stage8.json); 1.4 config/config.exs:9; 2.1 currency.ex:21,42,54,69; 2.2 currency_test.exs:55-68; 3.1-3.4 money.ex + money_test.exs falsifying battery (mid-list mismatch, seed validation, mult float all present); 4.1-4.5 schema.ex + schema_test.exs (bypass half-set test present); 5.1 mobus_money.ex:53 + mobus_money_test.exs both branches; 6.1 both compile runs recorded in commit 4f7bdc6 (ectoless run verified Schema loads but exports none of the three functions); 6.2 green; 6.4 README API table matches shipped surface exactly. No ghosts. Tasks 6.3/6.5/7.x unticked claim no code surface (6.3's own summary shows ghost_count 0; 6.5/7.x are operator actions) |
| V7 | PLAN.md handoff | N/A | No PLAN.md tick claimed anywhere in proposal.md/design.md (grep clean); no PLAN.md file exists in this repo |
| V8 | Stated constraints | PASS | All 29 constraints.json entries judged HONOURED or N/A at HEAD — none VIOLATED (full table below). Judged at each implementing function and every call site in the diff; no `_ =` error-discarding caller, no `Application.put_env`, no exchange-rate parameter, no `to_currency`/`Money.sum` call anywhere in lib/ (grep clean) |

## Stated constraints (V8)

Judged from the cumulative diff master..b38fc49, at each implementing
function and every call site consuming its result. No call site in lib/ or
test/ discards a `{:error, _}` on a constraint-governed path. Entries #22
and #27 quote pre-fold spec text superseded by this same diff's own doc-fold
commits (8220dcc/e35723e/0515cf9/b9f7a24) — judged by substance against the
corrected requirement the diff carries (pre-merge auditor F5 documented the
index staleness as INFO; nothing was missed by it).

| # | file:line | kind | verdict | evidence |
|---|-----------|------|---------|----------|
| 1 | proposal.md:8 | prohibition | HONOURED | The defect described (currency only in a column name, `/100.0`) is what the diff removes: typed value type (money.ex:52-73) + typed two-column pair (schema.ex:53-58) |
| 2 | proposal.md:22 | prohibition | HONOURED | Amount and currency travel together in every public value: `Money.t()` wrapper + `<name>_currency` column in the pair (schema.ex:53-58, read_money builds one value from both, schema.ex:150-170) |
| 3 | design.md:37 | prohibition | HONOURED | Never converting: mismatch refused by this library's own check before delegation (money.ex:108-109,117-118,130-131); same-currency arithmetic delegates to Decimal-based `Money.add/sub/compare` only |
| 4 | design.md:176 | prohibition | HONOURED | No `to_currency` call in lib (grep clean — sole matches are doc comments explaining why not, money.ex:143-144); `ensure_fx_disabled!/0` shipped as the loud mechanism (mobus_money.ex:53-67) |
| 5 | design.md:179 | prohibition | HONOURED | No public function accepts an exchange rate (grep clean); boot check turns silent capability into a crash naming the config |
| 6 | design.md:180 | prohibition | HONOURED | FX unreachable through this API: no rate parameter anywhere; this repo's own test runs keep the service off (config/config.exs:9) |
| 7 | design.md:224 | prohibition | HONOURED | No `Application.get_env` for per-call behavior in lib (grep clean); sole env read is `ensure_fx_disabled!/0` (mobus_money.ex:54) — the D4-sanctioned boot assertion, reads only, never writes; no `put_env` anywhere |
| 8 | design.md:251 | prohibition | HONOURED | `exponent/1` reads `currency_for_code` → `iso_digits \|\| digits`, no hardcoded exponent table (currency.ex:42-49) |
| 9 | design.md:262 | prohibition | HONOURED | Only the two-column shape ships: `money_fields/1` declares exactly two plain fields (schema.ex:53-58) |
| 10 | design.md:274 | prohibition | HONOURED | No composite-type or jsonb code in the diff; moduledoc documents the plain-column migration shape (schema.ex:24-31) |
| 11 | design.md:279 | prohibition | HONOURED | No FX/conversion code; GC-5708 forward-tracked in proposal, README |
| 12 | design.md:286 | prohibition | HONOURED | No `mobus_billing`/`mobus_ledger` module in the diff |
| 13 | design.md:297 | prohibition | HONOURED | Conversion withheld by construction: mismatch errors regardless of service state (money.ex:106-131), no rate parameter |
| 14 | design.md:327 | prohibition | HONOURED | `new(nil, _)` → `{:error, :nil_amount}` matched first (money.ex:52); nil ≠ real zero asserted (money_test.exs:34-40); Decimal arithmetic exact (0.056+0.044 test) |
| 15 | design.md:330 | prohibition | HONOURED | Mismatch tuple carries both codes as atoms from this library's own check-first clause (money.ex:108-109), never a converted value; atom-ness asserted (money_test.exs:236-244) |
| 16 | spec.md:5 | requirement | HONOURED | `MobusMoney.Money` wraps `Money.t()` (money.ex:27); R1's `new/2` four-reason contract implemented (money.ex:52-73) |
| 17 | spec.md:7 | requirement | HONOURED | All four reasons reachable and tested (`:float_amount`, `:nil_amount`, `:unparseable_amount` via "abc", `:unknown_currency`; money_test.exs:29-52) |
| 18 | spec.md:9 | prohibition | HONOURED | Float and nil matched before delegation, nil never zeroed (money.ex:52-54) |
| 19 | spec.md:10 | requirement | HONOURED | `new!/2` raises `InvalidMoneyError` on exactly the four conditions (money.ex:75-84); all four raise-tested (money_test.exs:61-84) |
| 20 | spec.md:25 | requirement | HONOURED | `add/sub/compare` structured mismatch from own check-first code (money.ex:106-131); `sum/2` folds over own `add/2` with validated seed, empty list returns `{:ok, zero}` (money.ex:150-165, tests money_test.exs:246-272) |
| 21 | spec.md:28 | prohibition | HONOURED | No function in the module accepts an exchange rate (grep clean across lib/) |
| 22 | spec.md:39 | requirement | HONOURED | Extracted text is the superseded pre-F1.1 "configure" wording; corrected D4 mechanism implemented and tested: `ensure_fx_disabled!/0` raising/passing both branches (mobus_money.ex:53-67, mobus_money_test.exs), this repo's own config sets the flag (config/config.exs:9), no library-config-for-consumers claim anywhere |
| 23 | spec.md:51 | requirement | HONOURED | `exponent/1`: JPY 0, EUR/USD/GBP 2, BHD/IQD 3 from the registry, nil for unknown (currency.ex:42-49, tested) |
| 24 | spec.md:56 | requirement | HONOURED | `round/2` mode argument defaults to `default_rounding_mode/0` = `:half_up`; explicit `:half_even` override tested (money.ex:215-217, money_test.exs:154-170) |
| 25 | spec.md:72 | requirement | HONOURED | `money_fields/1` declares the decimal + string pair, caller-chosen atom prefix (schema.ex:53-58, tested) |
| 26 | spec.md:74 | requirement | HONOURED | `validate_money/2` rejects half-set (both directions), unknown currency, negative amount; null/null and zero accepted (schema.ex:72-127, all tested incl. the F4 float-via-put_change path) |
| 27 | spec.md:77 | requirement | HONOURED | Extracted text is the superseded bare-`nil` wording; corrected three-shape contract implemented: `{:ok, nil}` / `{:ok, money}` / `{:error, {:half_set_pair, :amount\|:currency}}`, never raises, bypass-tested on directly-constructed structs (schema.ex:150-170, schema_test.exs:135-154) |
| 28 | spec.md:78 | requirement | HONOURED | `{:ecto, "~> 3.10", optional: true}` (mix.exs:37); value type and registry have no Ecto reference |
| 29 | spec.md:79 | prohibition | HONOURED | `Code.ensure_loaded?(Ecto)` guard wraps the whole function surface (schema.ex:30); task 6.1's ectoless compile run recorded clean with the three functions absent from the ectoless build (commit 4f7bdc6) |

## Findings (if any FAIL)

None. All of V1–V8 PASS (V7 N/A). No failed checks to detail.

Observations (non-gating, for the record):
- The test-env typing-violation warning at currency_test.exs:61 (V1 note)
  is cosmetic — the assertion is deliberate falsification of the
  `:half_up` override — but rephrasing it (e.g. `refute mode == :half_even`
  on a variable) would silence a future `--warnings-as-errors` test
  compile if one is ever gated.
- Task 6.3 (`openspec-audit` ghost_count 0) remains unticked in tasks.md
  even though stage0b-summary.json records ghost_count 0; it claims no code
  surface, so V6 is unaffected — tick it (or not) at the operator's
  discretion during close-out.

VERDICT: PASS
