## ADDED Requirements

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

The system SHALL provide `add/2`, `sub/2`, `sum/2`, `compare/2` over
`MobusMoney.Money` values that return `{:error, {:currency_mismatch, code_a,
code_b}}` when the operands' currencies differ, carrying both currency
codes. No function in `MobusMoney.Money` SHALL accept an exchange rate or
perform a currency conversion.

#### Scenario: Adding two different currencies errors instead of converting

- **WHEN** `add/2` is called with a EUR money value and a USD money value
- **THEN** it returns `{:error, {:currency_mismatch, "EUR", "USD"}}` and no
  conversion occurs

### Requirement: The FX exchange-rate service is disabled by construction

The system SHALL configure `ex_money`'s `auto_start_exchange_rate_service` to
`false` at the library boundary, so no network FX lookup is reachable through
this library regardless of whether a consumer calls a conversion function.

#### Scenario: The exchange-rate service never starts

- **WHEN** the `mobus_money` application's configuration loads
- **THEN** `Application.get_env(:ex_money, :auto_start_exchange_rate_service)`
  is `false`

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
pair on an Ecto schema; `validate_money/2` SHALL reject a changeset where
exactly one of the pair is set, where the currency is not a valid code per
`MobusMoney.Currency.valid?/1`, or where the amount is negative.
`read_money/2` SHALL return `nil` for a null/null pair and a
`MobusMoney.Money` otherwise. `Ecto` SHALL be an optional dependency; the
`MobusMoney.Schema` module SHALL NOT require Ecto to be present for the rest
of this library to compile.

#### Scenario: A half-set pair is rejected

- **WHEN** a changeset sets `<name>_amount` but leaves `<name>_currency` nil
- **THEN** `validate_money/2` adds an error and the changeset is invalid

#### Scenario: A null/null pair reads as nil, not as zero

- **WHEN** `read_money/2` is called on a schema struct whose pair is both nil
- **THEN** it returns `nil`
