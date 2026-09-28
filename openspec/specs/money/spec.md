# money Specification

## Purpose
TBD - created by archiving change money-value-type. Update Purpose after archive.
## Requirements
### Requirement: Money is a currency-carrying value type, never a bare number

The system SHALL expose `MobusMoney.Money` as a value type wrapping
`Money.t()` (ex_money) whose amount and currency travel together. `new/2`
SHALL return `{:ok, money}` or `{:error, reason}` with `reason` one of
`:float_amount`, `:nil_amount`, `:unparseable_amount`, `:unknown_currency`; a
float amount and a `nil` amount SHALL both be refused, and `nil` SHALL NOT be
treated as zero. `new!/2` SHALL raise on the same conditions `new/2` refuses.

#### Scenario: A float amount is refused, not silently converted

- **WHEN** `MobusMoney.Money.new/2` is called with a float amount
- **THEN** it returns `{:error, :float_amount}`

#### Scenario: A nil amount is refused, not treated as zero

- **WHEN** `MobusMoney.Money.new/2` is called with a `nil` amount
- **THEN** it returns `{:error, :nil_amount}`, distinct from a zero-amount
  money value

### Requirement: Arithmetic never converts across currencies

The system SHALL provide `add/2`, `sub/2`, `compare/2` over
`MobusMoney.Money` values that return `{:error, {:currency_mismatch, code_a,
code_b}}` (currency codes as atoms, matching `Money.t()`'s own `:currency`
field type — NOT strings) when the operands' currencies differ, carrying
both currency codes; this SHALL be produced by this library's own code
checking the operands' currencies before delegating to `ex_money`, not by
translating an `ex_money` exception (the real upstream functions return
`{:error, {ArgumentError, "..."}}` on mismatch, an unstructured exception
with the codes embedded in prose, not the tuple this requirement names).
`sum/2` SHALL fold a list into one total in a stated currency without
converting any element, returning the same `{:error,
{:currency_mismatch, code_a, code_b}}` shape for any list element whose
currency differs from the stated one, and SHALL NOT raise for an empty
list. No function in `MobusMoney.Money` SHALL accept an exchange rate or
perform a currency conversion.

#### Scenario: Adding two different currencies errors instead of converting

- **WHEN** `add/2` is called with a `:EUR` money value and a `:USD` money
  value
- **THEN** it returns `{:error, {:currency_mismatch, :EUR, :USD}}` and no
  conversion occurs

#### Scenario: Summing an empty list returns zero in the stated currency, not a crash

- **WHEN** `sum/2` is called with an empty list and `:EUR`
- **THEN** it returns `{:ok, zero_money}` where `zero_money` is zero `:EUR`

#### Scenario: A mismatch anywhere in a 3+-element list halts immediately

- **WHEN** `sum/2` is called with a three-element list whose SECOND element
  is a different currency from the stated one
- **THEN** it returns `{:error, {:currency_mismatch, code_a, code_b}}`

#### Scenario: An unknown stated currency errors before touching the list

- **WHEN** `sum/2` is called with any list (including an empty one) and a
  `currency` argument that is not a known currency code
- **THEN** it returns `{:error, :unknown_currency}` without evaluating any
  list element

### Requirement: A consumer's disabled FX service is asserted at boot, loudly

The system SHALL expose `MobusMoney.ensure_fx_disabled!/0`, which SHALL
raise immediately, naming the missing setting, unless
`Application.get_env(:ex_money, :auto_start_exchange_rate_service)` is
`false` in the calling application's own configuration — a dependency's own
`config/config.exs` is never loaded by Mix for the consuming application, so
this library SHALL NOT claim to disable `ex_money`'s exchange-rate service by
shipping its own config file. This library's own arithmetic (`add/2`,
`sub/2`, `sum/2`, `compare/2`) SHALL reject a currency-mismatched operation
with an error tuple regardless of whether the exchange-rate service is
running, and no public function in this library SHALL accept an exchange
rate.

#### Scenario: A consumer that forgot the config crashes loudly at boot

- **WHEN** `MobusMoney.ensure_fx_disabled!/0` is called and the calling
  application's configuration has not set
  `auto_start_exchange_rate_service: false` for `:ex_money`
- **THEN** it raises, naming the missing configuration key

#### Scenario: A correctly configured consumer's check passes silently

- **WHEN** `MobusMoney.ensure_fx_disabled!/0` is called and the calling
  application's configuration has set `auto_start_exchange_rate_service:
  false` for `:ex_money`
- **THEN** it returns without raising

### Requirement: Rounding follows the currency's minor-unit exponent, with an explicit house default

The system SHALL expose `MobusMoney.Currency.exponent/1` returning the
correct minor-unit exponent for a given ISO 4217 currency code (0 for JPY, 2
for EUR/USD/GBP, and so on per `ex_money`'s registry), and
`MobusMoney.Currency.default_rounding_mode/0` returning `:half_up` — an
explicit override of `ex_money`'s own native default of `:half_even`.
`MobusMoney.Money.round/2` SHALL accept an explicit rounding mode, defaulting
to `MobusMoney.Currency.default_rounding_mode/0` when omitted.

#### Scenario: JPY rounds to zero decimal places

- **WHEN** `MobusMoney.Money.round/2` is called on a JPY money value with the
  default mode
- **THEN** the result has zero decimal places

#### Scenario: The house default is half-up, not ex_money's native half-even

- **WHEN** `MobusMoney.Currency.default_rounding_mode/0` is called
- **THEN** it returns `:half_up`

### Requirement: An optional two-column storage-pair convention, guarded when Ecto is absent

The system SHALL provide `MobusMoney.Schema.money_fields/1`, declaring an
`<name>_amount` (`numeric(28,8)`) and `<name>_currency` (`varchar(3)`) field
pair on an Ecto schema, where `name` is the atom prefix the caller chooses;
`validate_money/2` (whose second argument SHALL be the same `name` atom)
SHALL reject a changeset where exactly one of the pair is set, where the
currency is not a valid code per `MobusMoney.Currency.valid?/1`, or where
the amount is negative. `read_money/2` (whose second argument SHALL also be
that `name` atom) SHALL return `{:ok, nil}` for a null/null pair, `{:ok,
money}` for a valid pair, and `{:error, {:half_set_pair, missing_field}}` —
`missing_field` naming which of `:amount`/`:currency` is `nil`, never raise
— for a pair reachable outside `validate_money/2` (raw SQL, a migration, a
fixture) where exactly one column is set. `Ecto` SHALL be an optional
dependency; the `MobusMoney.Schema` module SHALL NOT require Ecto to be
present for the rest of this library to compile.

#### Scenario: A half-set pair is rejected at the changeset boundary

- **WHEN** a changeset sets `<name>_amount` but leaves `<name>_currency` nil
- **THEN** `validate_money(changeset, name)` adds an error and the
  changeset is invalid

#### Scenario: A null/null pair reads as nil, not as zero

- **WHEN** `read_money(struct, name)` is called on a schema struct whose
  pair is both nil
- **THEN** it returns `{:ok, nil}`

#### Scenario: A half-set pair reaching the reader directly errors, never crashes

- **WHEN** `read_money(struct, name)` is called on a schema struct
  constructed with exactly one of the pair set, bypassing `validate_money/2`
- **THEN** it returns `{:error, {:half_set_pair, missing_field}}`, naming
  the nil column, rather than raising

### Requirement: The remaining arithmetic and utility surface stays no-float, no-FX

The system SHALL provide `mult/2` (refusing a float multiplier the same way
`new/2` refuses a float amount), `zero/1`, `negative?/1`, `zero?/1`,
`format/1` (returning `{:ok, string}`), `to_integer_exp/1` (returning
`{currency_code, integer, exponent, remainder_money}`, with `exponent` as
the negative of the currency's digit count and rounded using this library's
own house rounding mode, never `ex_money`'s native default), `from_integer/2`,
and `MobusMoney.Currency.all_codes/0` on `MobusMoney.Money` /
`MobusMoney.Currency`. No function in this set SHALL accept an exchange rate
or a float where an amount or multiplier is expected. **This library SHALL
NOT provide `compare!/2`, `add!/2`, or `sub!/2`** — no consumer named in
this library's Consumers section needs a raising variant of any comparison
or arithmetic function, and none SHALL be added speculatively. (PE-9/F1.5,
doc review, and PE-6/PE-7, round-3 pre-execution — these functions were
named in design.md's public surface and tasks.md but covered by no
requirement here or, for `compare!/2`, covered by an unargued one; this
requirement closes the gap and removes the unargued function rather than
leaving either outcome to archive.)

#### Scenario: A float multiplier is refused

- **WHEN** `mult/2` is called with a float multiplier
- **THEN** it returns `{:error, :float_amount}`, the same reason `new/2`
  uses for a float amount

#### Scenario: The minor-unit conversion rounds with the house mode, not ex_money's native one

- **WHEN** `to_integer_exp/1` is called on a money value that needs rounding
  to reach its currency's minor unit
- **THEN** the rounding applied is `MobusMoney.Currency.default_rounding_mode/0`
  (`:half_up`), not `ex_money`'s native `:half_even`

