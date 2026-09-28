## 1. Spec and dependency setup

- [ ] 1.1 Add `{:ex_money, "~> 6.2"}` and `{:ecto, "~> 3.10", optional: true}`
      to `mix.exs` `deps/0`; `mix deps.get`.
- [ ] 1.2 `@moduledoc` on `MobusMoney` states the required consumer config
      line verbatim (`config :ex_money, auto_start_exchange_rate_service:
      false`) and that `ensure_fx_disabled!/0` (task 5.1) must be called from
      the consumer's own `Application.start/2` (D4 — corrected during doc
      review: a library's own `config/config.exs` is never loaded by Mix for
      a consuming application, so no config file ships here).
- [ ] 1.3 `openspec/specs/money/spec.md` delta authored (this change-set's
      spec deltas, folded on archive).
- [ ] 1.4 `config/config.exs` (THIS repo's own, distinct from D4's
      no-config-for-consumers rule — Mix DOES load config/config.exs for the
      top-level application being compiled, which during `mix test` is this
      library itself): `config :ex_money, auto_start_exchange_rate_service:
      false`, so this library's own test suite does not boot
      `Money.ExchangeRates.Supervisor` (PE-7 — with no config at all,
      `ex_money`'s default is `true` and this library's own tests would
      start it; the retriever does not poll without
      `exchange_rates_retrieve_every` set, so the impact was startup noise
      rather than network calls, but contradicts this library's own FX-off
      posture in its own test runs).

## 2. Currency registry (D2, D3)

- [ ] 2.1 `MobusMoney.Currency` (PE-1 — real upstream surface, not the
      invented one): `valid?/1` via `match?({:ok, _},
      Money.Currency.currency_for_code/1)`; `exponent/1` via
      `currency_for_code/1`'s `{:ok, currency}` then `currency.iso_digits ||
      currency.digits`; `all_codes/0` via
      `Money.Currency.known_tender_currencies/0`; `default_rounding_mode/0`
      (returns `:half_up`, this library's own, no delegation).
- [ ] 2.2 Falsifying test: `default_rounding_mode/0` returning `ex_money`'s
      native `:half_even` is shown red first (temporarily hardcode
      `:half_even`, watch the assertion fail, revert) — proves the test
      actually checks the override, not merely that a mode is returned.

## 3. Value type (D1)

- [ ] 3.1 `MobusMoney.Money.new/2(amount, currency_code)`: matches `nil` and
      `is_float(amount)` directly (returns `{:error, :nil_amount}` /
      `{:error, :float_amount}` WITHOUT calling `ex_money` — this library
      owns this contract, not a translation of `ex_money`'s exception text);
      everything else delegates to `Money.new(currency_code, amount)`,
      translating `{:error, {Money.UnknownCurrencyError, _}}` to
      `{:error, :unknown_currency}` and any other ex_money error to
      `{:error, :unparseable_amount}`. `new!/2` (PL-1 — the spec requires
      this to RAISE, not return a tuple): raises `MobusMoney.InvalidMoneyError`
      with the reason from `new/2`.
- [ ] 3.2 `zero/1` → `Money.zero/1`; `add/2`/`sub/2` → `Money.add/2`/
      `Money.sub/2` (real mismatch-error-tuple contract, delegated directly);
      `sum/2` → **self-reducing fold over this module's OWN `add/2`, never
      `Money.sum/2`** (PE-5, BLOCKER: `Money.sum/2`'s 2nd arg is FX rates and
      it converts — delegating it would silently violate the
      never-converts requirement); `mult/2` → `Money.mult/2`, refusing a
      float multiplier the same way `new/2` refuses a float amount;
      `compare/2`/`compare!/2` → `Money.compare/2`/`Money.compare!/2`;
      `negative?/1`/`zero?/1` → `Money.negative?/1`/`Money.zero?/1`.
- [ ] 3.3 `round/2(money, mode)` → `Money.round(money, rounding_mode: mode)`
      (real signature is a KEYWORD LIST, not a bare positional mode — PE-1
      area finding), mode defaults to
      `MobusMoney.Currency.default_rounding_mode/0`; `format/1` →
      `Money.to_string/1`; `to_integer_exp/1` → `Money.to_integer_exp/2`
      (fixed options), `from_integer/2` → `Money.from_integer/2` — this
      library's own names for ex_money's real minor-unit pair, NOT
      `to_minor_units/1`/`from_minor_units/2` (PE-2, BLOCKER: that API does
      not exist in `ex_money`).
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
- [ ] 4.4 `read_money/2`: `{:ok, nil}` for null/null, `{:ok, money}` for a
      valid pair, `{:error, :half_set_pair}` for exactly one column set
      (PE-3 — reachable outside `validate_money/2`, e.g. raw SQL; must not
      crash).
- [ ] 4.5 Falsifying tests: half-set pair rejected, unknown currency
      rejected, negative amount rejected, null/null reads as `nil`; a guard
      test that the module does not raise at compile time when Ecto is
      stubbed absent.

## 5. FX-disabled guard (D4 — corrected mechanism, doc review F1.1)

- [ ] 5.1 `MobusMoney.ensure_fx_disabled!/0`: raises, naming the missing
      setting, unless `Application.get_env(:ex_money,
      :auto_start_exchange_rate_service) == false` in the CALLING
      application's config (not this library's — there is none). Falsifying
      test: call it with the config unset/true in the test env and observe
      the raise; call it with the config explicitly set to `false` and
      observe it returns `:ok`.

## 6. Verification

- [ ] 6.1 `mix compile --warnings-as-errors` clean, with and without the
      optional Ecto dependency present (two compile runs).
- [ ] 6.2 Full suite green.
- [ ] 6.3 `openspec-audit` (Stage 0b) ghost_count 0.
- [ ] 6.4 `README.md` updated: scaffold-only language removed, public API
      summarized, "Status: scaffold only" replaced with the published
      version once hex-published (task 6.5). **States the required consumer
      config line verbatim** (`config :ex_money,
      auto_start_exchange_rate_service: false`) **and the
      `ensure_fx_disabled!/0` adoption step** (PL-2 — design.md D4 requires
      this note; the task must say so explicitly or it can be silently
      dropped).
- [ ] 6.5 Operator action, out of band, after merge + archive: `mix
      hex.publish` (not automated by this change-set — D7).

## 7. Close-out (operator-gated)

- [ ] 7.1 Merge (explicit per-launch operator go, per ritual).
- [ ] 7.2 Archive (`openspec archive money-value-type`, same session as
      merge).
- [ ] 7.3 Comment + close Bee GC-5588 with merge SHA, archive path, and a
      link to GC-5708 (forward-scoped FX) and the three consumers' own
      follow-up Bees (filed at adoption time, not here).
