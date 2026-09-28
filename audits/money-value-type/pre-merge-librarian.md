# Pre-Merge Librarian Review — Bee 5588
Date: 2026-09-28 09:43:06 UTC
Diff scope: master..1ef2adccfde7da056805f8f876a3342ffeb31600

## Findings by severity
### BLOCKER

### MAJOR

### MINOR / NIT
- ID: LIB-1
  Severity: MINOR
  File: lib/mobus_money/schema.ex:52,70,140
  Description + suggested fix: `money_fields/1`, `validate_money/2`, and `read_money/2` are all public, documented entry points, but none has a `@spec`; add specs for each so the schema API is machine-checkable and matches the review rule.
  Quote: `defmacro money_fields(name) when is_atom(name) do` / `def validate_money(%Ecto.Changeset{} = changeset, name) when is_atom(name) do` / `def read_money(%{__struct__: _} = struct, name) when is_atom(name) do`
- ID: LIB-2
  Severity: MINOR
  File: lib/mobus_money/money.ex:212
  Description + suggested fix: `round/1` is a public arity created by the default argument, but only `round/2` is spec'd; add a matching arity-1 spec or make the callable arity explicit.
  Quote: `def round(%Money{} = money, mode \\ MobusMoney.Currency.default_rounding_mode()) do`

## Summary
BLOCKER: 0
MAJOR: 0
MINOR: 2
NIT: 0
VERDICT: PASS
BLOCKER_COUNT: 0
