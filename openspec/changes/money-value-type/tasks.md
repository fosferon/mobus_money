## 1. Spec and dependency setup

- [ ] 1.1 Add `{:ex_money, "~> 6.2"}` and `{:ecto, "~> 3.10", optional: true}`
      to `mix.exs` `deps/0`; `mix deps.get`.
- [ ] 1.2 `config/config.exs`: `config :ex_money, auto_start_exchange_rate_service: false`
      (D4).
- [ ] 1.3 `openspec/specs/money/spec.md` delta authored (this change-set's
      spec deltas, folded on archive).

## 2. Currency registry (D2, D3)

- [ ] 2.1 `MobusMoney.Currency`: `valid?/1`, `exponent/1`, `all_codes/0`,
      `default_rounding_mode/0` (returns `:half_up`), each delegating to
      `Money.Currency` except `default_rounding_mode/0`.
- [ ] 2.2 Falsifying test: `default_rounding_mode/0` returning `ex_money`'s
      native `:half_even` is shown red first (temporarily hardcode
      `:half_even`, watch the assertion fail, revert) — proves the test
      actually checks the override, not merely that a mode is returned.

## 3. Value type (D1)

- [ ] 3.1 `MobusMoney.Money.new/2` / `new!/2`: wraps `Money.new/2`, normalizes
      every raise path to `{:error, reason}` with reasons `:float_amount`,
      `:nil_amount`, `:unparseable_amount`, `:unknown_currency`.
- [ ] 3.2 `zero/1`, `add/2`, `sub/2`, `sum/2`, `mult/2`, `compare/2`,
      `compare!/2`, `negative?/1`, `zero?/1` — mismatch path returns
      `{:error, {:currency_mismatch, code_a, code_b}}`.
- [ ] 3.3 `round/2` (mode defaults to `MobusMoney.Currency.default_rounding_mode/0`),
      `format/1`, `to_minor_units/1`, `from_minor_units/2`.
- [ ] 3.4 Falsifying tests per Testing section: float/nil refusal, exact
      0.056+0.044 arithmetic, mixed-currency error carrying both codes,
      JPY-vs-EUR rounding at both modes, minor-unit round-trip.

## 4. Storage-pair schema helper (D5) — optional-Ecto guarded

- [ ] 4.1 `MobusMoney.Schema`: `Code.ensure_loaded?/1` guard so the module
      does not require Ecto to compile when absent.
- [ ] 4.2 `money_fields/1` macro: declares `<name>_amount` (`numeric(28,8)`)
      and `<name>_currency` (`varchar(3)`).
- [ ] 4.3 `validate_money/2`: pairing (both null or both non-null), registry
      membership via `MobusMoney.Currency.valid?/1`, non-negativity.
- [ ] 4.4 `read_money/2`: pair → `MobusMoney.Money` or `nil` for null/null.
- [ ] 4.5 Falsifying tests: half-set pair rejected, unknown currency
      rejected, negative amount rejected, null/null reads as `nil`; a guard
      test that the module does not raise at compile time when Ecto is
      stubbed absent.

## 5. FX-disabled guard (D4)

- [ ] 5.1 Config-loaded test asserting
      `Application.get_env(:ex_money, :auto_start_exchange_rate_service) == false`,
      falsified by temporarily removing 1.2's config line and observing red,
      then restoring it.

## 6. Verification

- [ ] 6.1 `mix compile --warnings-as-errors` clean, with and without the
      optional Ecto dependency present (two compile runs).
- [ ] 6.2 Full suite green.
- [ ] 6.3 `openspec-audit` (Stage 0b) ghost_count 0.
- [ ] 6.4 `README.md` updated: scaffold-only language removed, public API
      summarized, "Status: scaffold only" replaced with the published
      version once hex-published (task 6.5).
- [ ] 6.5 Operator action, out of band, after merge + archive: `mix
      hex.publish` (not automated by this change-set — D7).

## 7. Close-out (operator-gated)

- [ ] 7.1 Merge (explicit per-launch operator go, per ritual).
- [ ] 7.2 Archive (`openspec archive money-value-type`, same session as
      merge).
- [ ] 7.3 Comment + close Bee GC-5588 with merge SHA, archive path, and a
      link to GC-5708 (forward-scoped FX) and the three consumers' own
      follow-up Bees (filed at adoption time, not here).
