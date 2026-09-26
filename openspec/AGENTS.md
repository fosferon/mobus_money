# OpenSpec project conventions — mobus_money

This file augments the global `openspec-development` skill
(`~/Sites/agents/skills/openspec-development/SKILL.md`) with the discipline this
library needs. Every change-set here is driven through the `openspec-development`
gc_workflow; a single context that both implements and reports on the work is
never accepted as certification.

## A shared library has consumers; the design names them

`mobus_money` exists because more than one project needs the same thing. Every
design.md MUST include a section titled **"Consumers"** that names each project
that will depend on the change (Atrapos, MOBuS, sil-diary4 as of 2026-09-26) and
states, per consumer, what it holds today and what migration the change asks of
it. A consumer whose requirements the author has not read in that consumer's own
code is not listed as a consumer; it is listed as unread, with a Bee.

## design.md MUST include a "Counterparts and symmetric cases" section

Every design.md MUST include a section titled **"Counterparts and symmetric
cases"** that answers:

1. **What other cases of this problem exist?** For each abstraction the design
   touches, name its siblings (other currencies and minor-unit exponents, other
   rounding modes, other storage shapes, other consumers).
2. **Are they addressed by this slice, or out of scope?** Fold each in, or
   declare it out of scope with a named, scoped follow-up Bee. Never vague
   "future maybe" language.
3. **Why is the asymmetry safe to ship?** If a capability ships for some
   counterparts and not others, state why the partial shipment is coherent.

## Declared forward scope, never softened requirements

A `SHALL` that is consciously deferred stays in the spec, is recorded under
design.md "Accepted findings" with a rationale and a Bee, and sits under a
forward section header so the deterministic ghost audit classifies it as
forward. Decision headings are written `### D1. Title` (with the period): a
`### D1 — Title` heading is not classified as forward when it names
fully-qualified function references. Non-forward sections (Ground-truth,
Accepted findings, Counterparts) name vanishing identifiers in plain words, not
in code spans.

## A published library never depends on an unpublished one

A change that adds a dependency on another fosferon library states where that
library is published (hex or a git tag). A path dependency on an unpublished
sibling is refused: it is the defect that broke the atrapos deploy for two
weeks (Bee GC-5584).

## Linked

- Global openspec-development skill: `~/Sites/agents/skills/openspec-development/SKILL.md`
- Epic GC-5586 (atrapos project): standalone commercial plane, extractable libraries
