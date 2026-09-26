# mobus_money

Currency-aware money for the fosferon ecosystem (Atrapos, MOBuS, sil-diary4).

**Status: scaffold only. Nothing here is implemented or published.** The library
is being specified change-first under `openspec/changes/`; the modules and the
hex package do not exist until that change-set has been independently verified
and merged.

The rulings that created it (2026-09-26, tracked as Bee GC-5586 in the atrapos
project):

- Amount and currency travel together; a bare integer with the currency baked
  into its name is the defect this library removes.
- One opinionated layer over `ex_money` 6.x, shared by every consumer, so the
  ecosystem has one representation and one rounding rule.
- Consumers: Atrapos first; MOBuS (which must move off OTP 26 first, GC-5587);
  sil-diary4.

Sibling libraries planned in the same family: `mobus_billing` (payment gateways
and webhook handling) and `mobus_ledger` (issued documents). Neither exists yet.

## License

MIT. See `LICENSE`.
