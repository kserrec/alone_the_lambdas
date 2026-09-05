# Archived plan before the non-core refactor

Archived 2026-09-05 from `PLAN.md` at
`578f1acc00566c17c18786a393cfa0b496c531ba`. Everything below this notice is
the original plan; only relative Markdown links were adjusted for this
archive location. Its work ordering, continuation,
branch, and release instructions are historical. The active plan is
[PLAN.md](../../PLAN.md); this archive never authorizes new work.

---

# Plan

This plan implements the specification milestones in dependency order. Phases
0 through 12 complete the pure core. Phases 13 through 20 build the explicitly
deferred effects and standalone-language milestone. Completed Phases 0 through
30 use one Phase as one coherent `$next` unit. Milestone 4 is intentionally
larger: each explicitly numbered Step is one coherent `$next` unit, and each
Phase groups related Steps. Every `$next` unit implements all of its listed
work, adds focused tests, runs the full suite, updates relevant documentation,
then commits and pushes `main`.

The three files under [docs/specifications](../specifications/README.md) are
the authority. The purity addendum overrides weaker purity examples, and the
naming addendum overrides earlier naming examples.

Completed phase records preserve the literal public spellings and artifact
names that were true when their evidence was collected. Phase 27 supersedes
those spellings for current work without rewriting history.

# Completed milestones (archived)

Full phase records, evidence, and measurements are preserved verbatim in
[PLAN-ARCHIVE.md](../../PLAN-ARCHIVE.md).

- Milestone 1 — Pure core, Phases 0 through 12 (repository foundation, raw
  calculus, tags and objects, List, binary Nat, structured Error, the
  generalized checker, typed Bool/Nat/Result/Char/String, and purity
  hardening) — complete → archived in PLAN-ARCHIVE.md.
- Milestone 2 — Effects and standalone language, Phases 13 through 20 (host
  contract, sole bridge and stdout, files, TCP, pure HTTP, HTTP server,
  `#lang` surface, runnable applications) — complete 2026-08-27 → archived
  in PLAN-ARCHIVE.md.
- Milestone 3 — Independent distribution, Phases 21 through 30 plus the
  post-Phase 27 maintenance pass and security audit (distribution contract,
  runner, diagnostics, Linux/macOS/Windows builds, Apache license and the
  AttaLambda rename, release candidate, first public release 0.2.0,
  withdrawal of the unsupported desktop assets) — complete 2026-08-29 →
  archived in PLAN-ARCHIVE.md.

## Durable distribution constraints (from Milestone 3, still binding)

The following constraints apply throughout:

- `.attl` is the canonical public source extension. A source file uses the
  exact `#lang attalambda` declaration so the verified reader, expander,
  source locations, and Lisp syntax remain authoritative; users run it
  through `attalambda`, never through a separately installed `racket` command.
- The initial public command surface is exactly `attalambda FILE.attl`,
  `attalambda --help`, and `attalambda --version`. A REPL, compiler command, package manager,
  formatter, debugger, editor integration, installer, and automatic updater
  remain outside this milestone unless a later phase proves one necessary.
- A release artifact bundles the Racket runtime and every language module it
  needs. It must not consult a system Racket installation, user package
  registry, source checkout, build directory, or network service at run time.
- The launcher is trusted module-loading scaffolding, not object-language
  computation and not another language-visible effect primitive. Its exact
  dynamic-loading and diagnostic capabilities must be separately classified;
  no AttaLambda program may import, name, or invoke them.
- The approved unary `host` remains the sole language-visible bridge for
  stdout, file, and TCP effects. Packaging must not add parsing, arithmetic,
  routing, Result control flow, or other ordinary language behavior in the
  launcher.
- Real-host programs retain the launching process's documented filesystem and
  network authority. Distribution adds no implied sandbox, permission prompt,
  backup, or trust guarantee.
- Use Racket's included executable-embedding and distribution facilities
  before considering another dependency. The expected artifact cost is a
  bundled Racket runtime and its transitive support files; every platform
  phase must measure compressed size, installed size, startup time, and the
  included file set.
- Release builds use one pinned Racket CS toolchain. Start with Racket 9.3,
  which the existing CI already pins; the Phase 21 proof must record and
  justify any change instead of silently building artifacts with the local
  Racket 8.10 installation.
- Native artifacts are required initially for Linux x86-64, macOS x86-64,
  macOS arm64, and Windows x86-64. Each artifact is built and tested on its
  own operating-system family because Racket distributions are platform
  specific.
- A public release is blocked until Kyle explicitly approves both the
  repository license and publication of the release. Planning or building a
  release candidate is not permission to publish one.

Supersession note: the four-platform bullet above is the literal Milestone 3
contract. Phase 30 (2026-08-29) withdrew the macOS and Windows public
assets, and Kyle confirmed on 2026-09-02 that releases remain Linux x86-64
only (no Windows machine; no paid Apple signing).

## Deferred findings

Deferred hardening (named reason — redesign, not a spot fix):

- **HTTP re-parse cost within the cap.** Within the 8192-byte bound the whole
  buffer is still re-parsed after every partial read, so a peer dribbling tiny
  chunks pays O(cap^2) interpreter work on its one connection before rejection.
  Memory and termination are now bounded, and this grants no capability beyond
  the deliberately blocking single-connection server's already-documented "one
  client can tie it up" property (a peer that simply stalls already blocks the
  no-timeout `tcp-read`). Fully removing the quadratic cost requires an
  incremental HTTP parser — scanning only the newly-read region for the
  terminator instead of re-scanning the buffer — which is a redesign of the
  read/parse loop with terminator-boundary and trailing-byte correctness risk,
  beyond an afternoon and beyond this minimal server's contract. Revisit if the
  HTTP server graduates from a minimal demonstration to a supported surface.

# Milestone 4 — Exact rational numbers and foundational values

Status: complete (2026-09-01)

Kyle directed (2026-09-01) that the entire Milestone 4 update lands on the
single branch `milestone-4-rationals`. Every Milestone 4 `$next` unit commits
and pushes that branch instead of `main`; `main` receives the milestone only
when it is complete and Kyle merges or approves the merge.

## Controlling rule — absolute object-language purity

Every new object-language value and every computation involving private Nat,
private Int, public Rat, Unit, Byte, Option, or Map must be implemented
entirely with variables, unary `lambda`, and application after macro
expansion. This governs representations, constructors, normalization,
arithmetic, comparison, powers, conversions between object-language types,
type and value checks, error decisions, Option selection, and every Map
operation.

Racket must not calculate or decide an AttaLambda program's result. In
particular, Rat and Int operations may not use Racket arithmetic, Map may not
use a Racket hash table or other host collection, and no new type may use
Racket conditionals, pattern matching, equality, loops, mutation, exceptions,
or data access for object-language computation.

The existing classified seams remain unchanged in purpose:

- macros may mechanically expand source into pure unary lambda terms;
- `runtime/codec.rkt` may deterministically translate validated values across
  the Racket/AttaLambda boundary, but may not perform object-language
  arithmetic or decide object-language results;
- `runtime/host.rkt` may perform only the explicitly approved external effects
  and conversions at its existing narrow boundary; and
- readers, tests, and tooling may observe or verify values but may not enter a
  production computation path.

`all_the_lambdas` is an algorithmic ancestor and source of test cases, not an
authority over AttaLambda's purity rules. Every borrowed idea must be rebuilt
as pure untyped lambda calculus and rejected or changed if it cannot satisfy
this rule. If any planned feature appears to require a broader Racket role,
implementation stops and the conflict is surfaced instead of weakening the
purity promise.

## Settled design

- Rat becomes the only number type users see.
- Binary Nat remains private machinery for magnitudes, counting, characters,
  bytes, ports, and similar whole-number work.
- Int remains private machinery: a sign plus a binary Nat magnitude.
- Rat contains an Int numerator and a positive Nat denominator.
- Int zero has only one representation: positive zero.
- Rat zero has only one representation: positive `0/1`.
- Every Rat is reduced to its simplest equivalent fraction.
- A zero denominator is invalid. It never means zero.
- `DIV` by zero returns `Result Err`.
- `EXP` accepts only whole-number exponents. Every fractional exponent is
  rejected, even when that particular power would happen to have a rational
  answer.
- Negative whole exponents use the reciprocal. Zero raised to a negative
  exponent returns `Result Err`.
- `0^0` remains `1`, following `all_the_lambdas`.
- Exponentiation uses repeated squaring rather than decrementing the exponent
  one by one.
- Wrong argument types produce Error. Expected arithmetic failures produce
  `Result Err`.
- The existing generalized exact-tag checker remains. There is no numeric
  hierarchy, automatic promotion system, generic arithmetic dispatcher, or
  arity-specific checker.
- Unit, Byte, Option, and Map become public types.
- Byte is data, not a second number type. Rat arithmetic rejects Byte.
- A byte sequence is `List Byte`; there is no separate Bytes type.
- Map receives a pure object-language equality function for comparing keys.
  The central type checker gains no special Map mechanism.
- Map lookup returns Option.
- Unit replaces uses of `NIL` that currently mean “the operation succeeded but
  has no useful answer.”
- Pair remains. Tuples remain nested Pairs. A Set can later be represented by
  a Map whose values are Unit.
- No public Nat, public Int, floating point, approximate decimal arithmetic,
  logarithms, trigonometry, irrational constants, Tuple type, Bytes type, or
  Set type is added in this milestone.

## Phase 31 — Make the new language contract authoritative

This Phase changes the specifications before executable work begins. The
three specifications remain the authority over every later Step.

### Step 31.1 — Amend the specifications

Status: complete (2026-09-01)

- [x] Update all three specification documents together so they state the final
  public type set and exact public operation names.
- [x] Specify the private Nat and Int representations and the canonical Rat
  representation.
- [x] Specify rational construction, normalization, arithmetic, comparison,
  floor, division, reciprocal, and exponent behavior.
- [x] Specify accepted exact integer and fraction literals and rejection of
  inexact Racket numbers.
- [x] Specify Unit, Byte, Option, and Map representations and operations.
- [x] Specify every new contract, invariant, and expected-computation error.
- [x] Specify the pure equality-function contract used by Map.
- [x] Preserve the existing host, codec, reader, type-checker, and absolute-purity
  boundaries without expanding their authority.
- [x] Retire the Nat tag without renumbering existing non-Nat tags.
- [x] Change no production module, test behavior, or executable behavior in this
  Step.

Acceptance: all three specifications agree on the new language, their stated
precedence remains unambiguous, and every later Step has an authoritative
contract rather than making a language-design decision during implementation.

Completion evidence: each specification received an explicitly dated,
append-only "Milestone 4 Amendment (2026-09-01)" section that wins over its
own earlier sections; pre-amendment bytes are unchanged above the amendment
markers. The main specification's amendment fixes the eleven-type public set,
private Nat/Int machinery, canonical reduced Rat with sole positive zero and
nonzero denominator, the exact Rat operation set (`SUCC ADD SUB MULT DIV EXP
RECIP NEG ABS FLOOR EQ LT LTE GT GTE IS-ZERO IS-WHOLE IS-NONNEGATIVE-WHOLE`),
exact-literal acceptance and inexact rejection, Unit, Byte with `List Byte`
sequences, Option, persistent Map with its pure key-equality contract, the
post-milestone effect signatures, and the new `NON-WHOLE-EXPONENT`,
`INVALID-COUNT`, and `INVALID-BYTE` kinds. The purity addendum's amendment
retires tag 3 permanently unassigned, assigns 7 RAT, 8 UNIT, 9 BYTE,
10 OPTION, 11 MAP, and extends absolute purity verbatim to every new type
without widening the macro/codec/host/reader seams. The naming addendum's
amendment fixes retained, new, and retired public spellings. The
specifications README records the new provenance hashes with the prior hashes
preserved as history. No production module, test, or executable behavior
changed; the full suite passed unchanged after the edit.

## Phase 32 — Turn binary Nat into a clean private arithmetic foundation

### Step 32.1 — Separate raw Nat arithmetic from the public Nat object

Status: complete (2026-09-01)

- [x] Make `core/binary-nat.rkt` contain only normalized binary-list values and
  raw binary Nat operations.
- [x] Move the current tagged Nat construction and public constants into the
  existing typed Nat layer as temporary compatibility code.
- [x] Preserve every current public result while this separation is made.
- [x] Set the single development version to `0.3.0-dev` and keep every projection
  of that version synchronized.
- [x] Add structural tests proving that private binary Nat arithmetic does not
  depend on tags, objects, typed functions, effects, the codec, or the host.

Acceptance: current programs behave identically, while the raw Nat foundation
can support Int and Rat without carrying a public Nat object into them.

Completion evidence: `core/binary-nat.rkt` now requires exactly the macro
layer, `fix.rkt`, `lists.rkt`, and `logic.rkt`, exports only `raw-` bindings
(including the newly exported `raw-zero-bits` and `raw-one-bits`), and
contains no tag, object, typed-function, effect, codec, or host reference.
`raw-make-nat`, `raw-nat-value`, and `ZERO` through `TEN` moved into
`core/typed-nat.rkt` as explicitly commented temporary compatibility code;
every production importer (chars, list-nat, the five effect modules, the
codec, the two Nat-observing readers, and the expander) now takes the tagged
bindings from the typed layer, and the boundary gate's pinned expander
require form tracks the move. New structural tests in
`tests/binary-nat-test.rkt` read the raw module's source and fail on any
non-raw export, any forbidden require, or any tagged/privileged symbol.
The single version source is `0.3.0-dev` with the `0.2.900` package
projection synchronized across `info.rkt`, the runner's approved-state
regex, the boundary gate and its test, the runner test, and all four native
build/consumer scripts. The full suite passed 5,978 assertions across all
32 test files (the growth over Phase 30's 4,755 is dominated by the new
per-symbol structural scan of the raw module), with the unchanged 16-module
purity proof and the zero-finding boundary inventory, on 2026-09-01; no
public operation, representation, or host authority changed.

### Step 32.2 — Add quotient with remainder, remainder, greatest common divisor, and least common multiple

Status: complete (2026-09-01)

- [x] Extend AttaLambda's current binary long-division traversal so one pure
  calculation produces both quotient and remainder.
- [x] Keep the existing raw division operation as selection of the quotient from
  that result, preserving its current answers.
- [x] Build remainder, greatest common divisor, and least common multiple from
  that pure result.
- [x] Do not replace AttaLambda's current division with the older
  `all_the_lambdas` implementation.
- [x] Test normalization, a smaller dividend, exact division, nonzero remainder,
  zero dividend, large binary values, and the internal zero-divisor guard.

Acceptance: Rat reduction and floor have the private division information they
need, with no host arithmetic and no change to existing Nat division results.

Completion evidence: the existing MSB-first long-division loop now returns a
raw pair of quotient and remainder (`raw-nat-div-rem`); `raw-nat-div` selects
the quotient from that pair with unchanged answers, `raw-nat-rem` selects the
remainder, `raw-nat-gcd` iterates Euclid's algorithm on the remainder with
its zero test guarding the recursive division, and `raw-nat-lcm` divides the
product by the greatest common divisor behind an explicit either-operand-zero
guard, so no zero divisor reaches the division loop (the `lcm 0 0` test fails
without it). `core/binary-nat.rkt` additionally requires only `pair.rkt`,
which the structural require pin now reflects. Focused tests cover the
quotient/remainder pair across all previous division cases, smaller
dividends, exact division, nonzero remainders, zero dividends,
non-normalized operands, nine-digit values, gcd/lcm identities and large
values, and unary arity. The full suite passed 6,296 assertions across all
32 test files with the unchanged 16-module purity proof and zero-finding
boundary inventory on 2026-09-01.

### Step 32.3 — Add the helpers needed for powers

Status: complete (2026-09-01)

- [x] Add pure binary Nat even, odd, halving, and exponentiation-by-squaring
  operations.
- [x] Keep these as private raw operations.
- [x] Test zero and one exponents, odd and even exponents, zero and negative-case
  prerequisites, and values large enough to prove that the implementation is
  not decrementing the exponent once per multiplication.

Acceptance: private Nat supplies every magnitude operation required by Int and
Rat powers while remaining pure unary lambda computation.

Completion evidence: `raw-nat-odd` reads the last bit of the normalized
value, `raw-nat-even` negates it, `raw-nat-half` drops the last bit and
renormalizes, and `raw-nat-exp` recurses on the halved exponent with one
squaring per exponent bit, so `raw-nat-exp 2 4096` produces the exact
4097-bit result in interpreted lazy evaluation — practical only because the
recursion performs twelve squarings rather than 4,095 multiplications. All
four remain private raw exports of `core/binary-nat.rkt` under the pinned
require set. Tests cover parity across boundaries and non-normalized input,
halving including zero and one, zero/one bases and exponents (`0^0 = 1`
groundwork), odd and even exponents, host-exponentiation agreement through
`7^13`, the 2^4096 magnitude proof, and unary arity.

## Phase 33 — Add private Int

### Step 33.1 — Add the representation and enforce one zero

Status: complete (2026-09-01)

- [x] Add a private Int representation consisting of a Bool sign and normalized
  binary Nat magnitude.
- [x] Route every construction through one pure function that turns any attempted
  signed zero into positive zero.
- [x] Add private sign, magnitude, zero, negation, and absolute-value operations.
- [x] Add an Int reader for tests and human inspection only.
- [x] Add no Int type tag, public Int constructor, Int literal, typed Int layer, or
  `#lang attalambda` export.

Acceptance: negative zero cannot be constructed through any supported private
Int operation, and Int remains pure untagged machinery unavailable to users.

Completion evidence: `core/int.rkt` represents an Int as a raw untagged pair
of raw Boolean sign (true means nonnegative) and normalized binary
magnitude; `raw-make-int` normalizes the magnitude and forces every zero —
including non-normalized and empty zero spellings — to positive zero, and
negation and absolute value route through it. `readers/int.rkt` renders a
completed Int as a signed host integer for tests only; the boundary gate's
reader vocabulary gained exactly `int->integer`, `raw-int-sign`,
`raw-int-magnitude`, and `-`. The purity scan now proves 17 core modules
(the purity-test and acceptance-test pins updated), and the boundary
classification counts nine readers. No tag, typed layer, literal, or
language export was added; the expander's pinned imports and exports are
unchanged. The full suite passed 6,663 assertions across all 33 test files.
`tests/int-test.rkt` covers sign/magnitude/reader round trips, all
negative-zero construction attempts, non-normalized magnitudes, constants,
zero testing, negation/absolute-value including zero results, and unary
arity.

### Step 33.2 — Add signed arithmetic and comparison

Status: complete (2026-09-01)

- [x] Adapt the useful `all_the_lambdas` Int algorithms for successor,
  predecessor, addition, subtraction, multiplication, equality, ordering,
  absolute value, and parity.
- [x] Route every result through the canonical Int constructor.
- [x] Test every combination of positive, negative, and zero operands, including
  operations whose mathematical result is zero.
- [x] Do not copy `all_the_lambdas`'s separate negative zero, division-by-zero-as-
  zero, or negative-integer-power-as-zero conventions.
- [x] Add only the private Int operations that Rat actually uses; do not create an
  unused public or typed Int library.

Acceptance: Rat has a complete signed numerator foundation, and every Int
answer is produced solely by pure untyped lambdas in one standard form.

Completion evidence: `core/int.rkt` adds succ, pred, add, sub, mult, equal,
the four orderings, odd, and even as raw curried operations. Same-sign
addition adds magnitudes; mixed-sign addition subtracts the smaller
magnitude from the larger under the larger operand's sign; subtraction adds
the negation; multiplication compares signs; ordering places negatives below
nonnegatives and reverses magnitude comparison between negatives; parity
reads the magnitude. Every arithmetic result routes through the canonical
constructor, and the 13×13 signed operand matrix in `tests/int-test.rkt`
verifies add/sub/mult/all comparisons against host integers, that every
zero-valued result carries the positive sign, successor and predecessor
across zero, sign-independent parity, nine-digit magnitudes, and unary
arity. The full suite passed 8,128 assertions across all 33 test files with the 17-module purity proof and zero-finding boundary inventory. No public or typed Int surface exists.

## Phase 34 — Add private canonical Rat arithmetic

### Step 34.1 — Add Rat construction and reduction

Status: complete (2026-09-01)

- [x] Add a private Rat representation consisting of an Int numerator and a
  positive binary Nat denominator.
- [x] Reject denominator zero as an invariant failure.
- [x] Reduce numerator and denominator by their greatest common divisor.
- [x] Force every zero result to positive `0/1`.
- [x] Add private selectors, constants, and a Rat reader for tests and human
  inspection.
- [x] Route every supported Rat construction through the same canonical
  constructor.

Acceptance: equal rational values have one stored representation, denominator
zero is never a value, and neither positive nor negative noncanonical zero can
escape construction.

Completion evidence: `core/rat.rkt` stores a raw pair of Int numerator and
positive normalized denominator; `raw-make-rat` normalizes the denominator,
divides both parts by their greatest common divisor, and routes the reduced
numerator through the canonical Int constructor, which automatically forces
every zero numerator to positive zero over denominator one. A zero
denominator is documented as an internal invariant failure exactly like a
zero raw-division divisor: it is never a value, and every supported entry
path must guard it before construction. `readers/rat.rkt` renders a
completed Rat as an exact host rational for tests only (reader vocabulary
extended by `rat->number`, the two selectors, and `/`; reader count now 10;
purity pins now 18 core modules). `tests/rat-test.rkt` checks the 13×9
construction grid against Racket's exact rationals with stored-part
verification, every zero spelling including negative and non-normalized
zeros, non-normalized denominators, the two constants, and unary arity. The full suite passed 8,507 assertions across all 34 test files with the 18-module purity proof and zero-finding boundary inventory.

### Step 34.2 — Add ordinary rational operations

Status: complete (2026-09-01)

- [x] Add pure negation, absolute value, addition, subtraction, and
  multiplication.
- [x] Add pure equality and ordering.
- [x] Add zero, whole-number, and nonnegative-whole-number checks.
- [x] Add floor with correct behavior for negative fractions and negative whole
  values.
- [x] Route every Rat result through canonical construction.
- [x] Reuse sound `all_the_lambdas` algorithms and test cases, but retain
  AttaLambda's existing binary arithmetic where it is already clearer or more
  efficient.

Acceptance: ordinary Rat operations are exact, reduced, have only positive
zero, and contain no Racket computation in their implementation path.

Completion evidence: `core/rat.rkt` adds negate, abs, add (cross-multiplied
over the product denominator), sub (add of negation), mult, equal (canonical
part comparison), the four orderings (signed cross-multiplication), is-zero,
is-whole (denominator one), is-nonnegative-whole, and floor (magnitude
division with a predecessor step for negative fractions carrying a nonzero
remainder); every Rat result routes through the canonical constructor. The
16×16 rational operand matrix in `tests/rat-test.rkt` — spanning negative
and positive fractions, wholes, zero, and 123456/7 — matches Racket's exact
rational arithmetic for all eight binary operations through the one-way
reader, with unary operations, floor denominators, canonical positive-zero
results, stored-part reduction checks, and unary arity all verified. The full suite passed 10,709 assertions across all 34 test files with the 18-module purity proof and zero-finding boundary inventory.

### Step 34.3 — Add rational division and powers

Status: complete (2026-09-01)

- [x] Add reciprocal and exact division with explicit zero checks.
- [x] Add whole-exponent rational powers using the private binary
  exponentiation-by-squaring operation.
- [x] Reject every fractional exponent rather than flooring it or attempting
  special perfect-root detection.
- [x] Support negative whole exponents through reciprocal.
- [x] Preserve `0^0 = 1`; reject zero raised to a negative exponent.
- [x] Test division by zero, reciprocal of zero, positive and negative exponents,
  odd and even powers of negative bases, fractional exponents that would and
  would not happen to yield rationals, and large exponents.

Acceptance: division and exponent failure are explicit, no operation silently
changes its mathematical question, and every successful answer is a canonical
Rat produced by pure lambdas.

Completion evidence: `raw-rat-recip` and `raw-rat-div` guard zero and return
raw Result values whose expected failure is the canonical DivideByZero
Error; `raw-rat-exp` rejects every non-whole exponent with the new
NonWholeExponent kind (13, numbered after the host-protocol and HTTP
kinds, added to errors and the error reader without renumbering), powers magnitudes through the private squaring
exponentiation, flips for negative whole exponents, keeps `0^0 = 1`, and
maps zero to a negative exponent to DivideByZero. The 16×16 division grid
and reciprocal sweep match Racket's exact division with kind-3 failures on
zero; power cases cover positive/negative/zero/fractional bases, odd and
even powers of negative bases, negative exponents through reciprocal,
(4/9)^(1/2) and (8/27)^(1/3) rejected despite having rational answers, and
exact large results including 2^200 and (3/2)^64. `tests/rat-test.rkt`
passes 3,184 assertions; the full suite passed 11,313 assertions across all 34 test files with the 18-module purity proof and zero-finding boundary inventory.

## Phase 35 — Replace the public Nat surface with Rat

Rat may exist privately during the early Steps in this Phase, but Nat and Rat
must never both be presented as public number types.

### Step 35.1 — Add the tagged Rat layer

Status: complete (2026-09-01)

- [x] Add the Rat type tag without changing the numeric identities of existing
  non-Nat tags.
- [x] Add strict Rat functions using the existing generalized checker unchanged.
- [x] Provide Rat implementations for `SUCC`, `ADD`, `SUB`, `MULT`, `DIV`, `EXP`,
  `EQ`, `LT`, `LTE`, `GT`, `GTE`, and `IS-ZERO`.
- [x] Add the approved public operations for negation, absolute value, reciprocal,
  floor, whole-number checking, and nonnegative-whole-number checking.
- [x] Make division, reciprocal, and exponentiation return `Result` where their
  expected arithmetic failures require it; keep wrong argument types as
  Error.
- [x] Keep this tagged Rat layer out of the `#lang attalambda` exports until the
  complete public switch.

Acceptance: the exact-tag checker handles Rat exactly as it handles every
other tag, with no numeric hierarchy, promotion logic, dispatcher, or new
checker form.

Completion evidence: `rat-type` is church-seven, leaving tags 0 through 6
untouched, and `readers/type-tag.rkt` renders it as `RAT`.
`core/typed-rat.rkt` builds all eighteen strict operations
(`typed-rat-succ` through `typed-rat-is-nonnegative-whole`) on the
unchanged generalized checker with the canonical function names `EXP`,
`RECIP`, `NEG`, `ABS`, `FLOOR`, `IS-WHOLE`, and `IS-NONNEGATIVE-WHOLE`
added to `core/function-names.rkt`; `DIV`, `EXP`, and `RECIP` keep their
already-typed Result, re-wrapping a successful raw payload as a tagged Rat.
`raw-rat-succ` joined the raw layer. Nothing is exported through the
language facade; the expander's pinned imports and exports are unchanged.
`tests/typed-rat-test.rkt` passes 690 assertions covering tagged results
across a 6×6 rational grid, all unary operations and checks, Ok and Err
Results for division/reciprocal/powers, exact `RAT` error frames on every
argument position, Error bubbling with appended frames, remaining-arity
absorption, and unary arity. Purity pins now prove 19 core modules; the full suite passed 12,004 assertions across all 35 test files with the zero-finding boundary inventory.

### Step 35.2 — Add Rat conversion and literal construction

Status: complete (2026-09-01)

- [x] Extend `runtime/codec.rkt` to translate exact Racket integers and fractions
  into canonical Rat values and translate Rat values back for approved host or
  reader use.
- [x] Add the production-free Rat reader support needed for human-readable tests
  and errors.
- [x] Reject inexact numbers rather than converting an approximate binary
  floating-point value into a surprising fraction.
- [x] Keep every arithmetic operation on an existing Rat inside the pure
  object-language modules. Racket may only decompose or construct the
  corresponding boundary representation deterministically.
- [x] Add boundary tests proving that no other production module imports or
  recreates these conversions.

Acceptance: exact source and boundary numbers can enter and leave AttaLambda
deterministically without granting Racket any role in Rat computation.

Completion evidence: `exact->object-rat` accepts only exact Racket rationals
(raising the standard contract error for `1.5`, `-0.0`, `1e3`, infinities,
NaN, and complex numbers) and builds the stored representation directly from
Racket's canonical reduced positive-denominator form, running no
object-language arithmetic; `object-rat->exact` validates the tag,
sign, magnitude, and denominator, rejecting forged unreduced parts, negative
or non-`0/1` zeros, zero denominators, and non-normalized bits as codec
failures before producing the exact host rational. The boundary gate's
pinned codec provide form and closed codec vocabulary were extended in the
same change, so any second production module recreating or importing these
conversions still fails the sole-importer and vocabulary rules; the
`readers/rat.rkt` observation support from Step 34.1 needed no production
change. Codec tests round-trip integers, fractions, negatives, zero, and a
2^200-magnitude value, and prove every rejection path. The full suite passed 12,061 assertions across all 35 test files with the 19-module purity proof and zero-finding boundary inventory.

### Step 35.3 — Prepare Rat-based List, String, and Char operations

Status: complete (2026-09-01)

- [x] Prepare `LEN` and `STRING-LENGTH` to return whole-valued Rat objects.
- [x] Prepare `TAKE`, `DROP`, and `MAKE-CHAR` to accept Rat and verify that it
  represents an allowed nonnegative whole number.
- [x] Keep their actual counting and indexing work on private binary Nat values.
- [x] Return clear Errors for negative or fractional counts and out-of-range Char
  values.
- [x] Keep the existing public Nat behavior active until the single public switch.

Acceptance: every core consumer of the current public Nat surface has a tested
Rat replacement ready without temporarily exposing two public number types.

Completion evidence: `typed-len-rat`, `typed-take-rat`, and `typed-drop-rat`
in `core/list-nat.rkt`, `typed-make-char-rat` in `core/chars.rkt`, and
`typed-string-length-rat` in `core/strings.rkt` are strict prepared variants
kept off the language surface. Lengths convert the existing raw binary List
counter to a whole Rat through the new `raw-whole-rat` helper; counts and
character codes validate `IS-NONNEGATIVE-WHOLE` in pure lambda computation
and then reuse the unchanged raw binary take/drop/range machinery through
`raw-rat-magnitude-bits`. A negative or fractional count is the new
INVALID-COUNT contract Error (kind 15, added to errors and the error
reader), rendered as `INVALID-COUNT\n  -> TAKE(result)` style
frames; an out-of-range code above 255 remains INVALID-CHAR. Focused tests
cover whole-Rat lengths for Lists and Strings, take/drop across zero,
partial, full, and beyond-length counts, all rejection paths, and unchanged
wrong-type mismatches, while every existing public Nat test still passes. The full suite passed 12,087 assertions across all 35 test files with the 19-module purity proof and zero-finding boundary inventory.

### Step 35.4 — Prepare Rat-based effect and host fields

Status: complete (2026-09-01)

- [x] Prepare ports, handles, backlog sizes, read limits, and other ordinary
  numeric fields to use Rat objects representing nonnegative whole numbers.
- [x] Check whole-number and range requirements in pure object-language code
  before an effect request reaches the host.
- [x] Convert validated Rat values at the existing deterministic codec boundary.
- [x] Keep tiny type tags, error kinds, host-operation codes, and argument
  positions as their separately allowed fixed Church numerals.
- [x] Keep existing public Nat requests active until the single public switch.

Acceptance: every runtime and effect dependency on public Nat has a tested Rat
replacement, while host authority and the codec exception remain no broader
than before.

Completion evidence: `effects/tcp.rkt` gains the six prepared `-rat` request
constructors and six prepared `-rat` wrapper factories. Ports, backlog
sizes, read limits, and opaque handles arrive as Rat objects; pure lambda
computation verifies `IS-NONNEGATIVE-WHOLE` before any request value
exists, so a negative or fractional field is an INVALID-COUNT Error carrying
the operation's function name and — proven by fake-host call counting — the
host is never applied. Valid requests carry tagged Rat numeric fields that
the Step 35.2 codec conversions decode deterministically at the boundary;
operation codes, error kinds, and argument positions remain fixed Church
numerals, and stdout/file wrappers have no numeric fields. The current
public Nat wrappers, the real host dispatcher, and the sole-bridge authority
are unchanged until the single switch (the real host's Rat decode/encode
swap is part of Step 35.5's prepared-path switch). The extended TCP suite
verifies exact decoded request shapes for all six operations, Ok
passthrough, force-once dispatch, INVALID-COUNT bubbling with zero host
calls, and ordinary strict RAT mismatches, passing 266 assertions. The full suite passed 12,161 assertions across all 35 test files with the 19-module purity proof and zero-finding boundary inventory.

### Step 35.5 — Perform the public switch

Status: complete (2026-09-01)

- [x] Change every accepted exact number literal to construct Rat.
- [x] Export the Rat operations through `#lang attalambda`.
- [x] Switch the prepared List, String, Char, effect, codec, and host paths to Rat.
- [x] Remove public Nat constants, typed functions, type tag, reader, language
  exports, and obsolete tests.
- [x] Retain and test only the private raw binary Nat machinery.
- [x] Update all current examples and documentation together without rewriting
  completed historical records.
- [x] Add a repository-wide check that fails if a public or production typed Nat
  surface is reintroduced.

Acceptance: users see exactly one number type, Rat; every existing numeric
consumer has its defined Rat behavior; and private Nat remains pure internal
machinery rather than a second public number system.

Completion evidence: the expander lowers every exact integer and fraction
datum (including negatives) to the canonical stored Rat representation and
rejects inexact and non-real datums with "only exact Rat and String literals
are supported"; the facade exports the eighteen Rat operations and no Nat
name. `core/typed-nat.rkt`, `readers/nat.rkt`, and `tests/typed-nat-test.rkt`
are deleted; tag 3 is retired from `core/tags.rkt` and renders as `TYPE:3`;
`ZERO` through `TEN` are gone (chars, list-nat, and the HTTP modules build
their private magnitudes from raw bits). The prepared paths switched
together: LEN/TAKE/DROP/MAKE-CHAR/STRING-LENGTH are the Rat variants, the
six TCP wrappers are the Rat versions carrying tagged Rat request fields,
`effects/protocol.rkt` validates canonical nonnegative-whole Rat fields
purely, HTTP statuses are whole Rats with a Rat renderer signature, the
codec dropped its Nat conversions, and the host decodes bounded counts with
`object-rat->exact` and returns handles via `exact->object-rat`. During the
switch a latent kind collision was found and fixed: the Step 34.3/35.3 kinds
had reused Church 7 and 8, which already belong to the host protocol, so
NON-WHOLE-EXPONENT and INVALID-COUNT are now kinds 14 and 15, numbered after
the host, HTTP, and HTTP-server kinds (a second miscount — starting them at
13, which the HTTP server already owned — was found by the pre-release
branch review and fixed in commit fb96dea). The boundary gate gained
`reintroduced-nat-surface`, a repository-wide scan that fails if any
production source mentions a retired Nat spelling, and its pinned expander
forms, codec provide, and codec/host/reader/expander vocabularies moved with
the switch. `examples/http-server.attl` now floors its decimal-digit
quotients under exact division. Twenty-two test files were updated
(canonical literal representation, `expected RAT` frames, tag 7
expectations, exact-division semantics, forged-Rat host defenses); the full
suite passed 11,705 assertions across all 34 test files with the 18-module
purity proof and the zero-finding boundary inventory including the new
reintroduction check.

## Phase 36 — Add Unit

### Step 36.1 — Add Unit and use it where “nothing” is the answer

Status: complete (2026-09-01)

- [x] Add one Unit type with exactly one value, `UNIT`.
- [x] Add its reader and public export.
- [x] Change successful stdout, file-write, TCP-write, TCP-close, and related
  server operations from `Ok NIL` to `Ok UNIT`.
- [x] Preserve `NIL` wherever an actual empty List is the answer.
- [x] Implement Unit construction, checking, propagation, and effect use entirely
  with pure object-language lambdas; the host may only return its encoded
  value through the existing codec boundary.
- [x] Add effect, host, reader, error, laziness, purity, and boundary tests.

Acceptance: Unit carries successful no-value results, NIL means only an empty
List, and neither the type nor its effect integration broadens host authority.

Completion evidence: `core/unit.rkt` defines `UNIT` as the single
`unit-type` (church-eight, tag 8) value over one fixed raw payload, exported
through the facade; the codec exposes the same canonical value as
`object-unit`, and the host's four no-value acknowledgements (stdout,
file write, TCP write, TCP close) return `Ok(UNIT)` instead of `Ok(NIL)`
with the host's `NIL` import removed entirely. `readers/unit.rkt` renders
the type name one way. The pinned expander forms, codec provide, and
codec/host/reader vocabularies, the reintroduction-safe boundary gate, the
19-module purity pins, and the ten-reader classification all moved in the
same change. `tests/unit-test.rkt` proves the tag, distinctness from NIL,
false, zero, and every other public type, the reader, the codec value, the
Ok(UNIT) acknowledgement shape, NIL's List meaning, and lazy payload
handling, while the stdout, files, host, TCP-host, TCP, and HTTP-server
suites now assert tag-8 payloads for every successful no-value result. The
full suite passed 11,720 assertions across all 35 test files with the
zero-finding boundary inventory.

## Phase 37 — Add Byte and distinguish binary data from text

### Step 37.1 — Add Byte

Status: complete (2026-09-01)

- [x] Add Byte values from 0 through 255, internally backed by private binary Nat
  magnitudes.
- [x] Add construction from a nonnegative whole Rat, conversion back to Rat,
  equality, and ordering.
- [x] Reject negative, fractional, and over-255 inputs.
- [x] Ensure ordinary Rat arithmetic rejects Byte.
- [x] Add Byte reader, type, invariant, error, purity, and public-language tests.

Acceptance: Byte is a distinct pure data type with exactly 256 valid values,
not a second numeric type or a host byte hidden inside an object.

Completion evidence: `core/byte.rkt` defines Byte as tag 9 (church-nine)
over private normalized magnitudes. `MAKE-BYTE : Rat -> Byte` validates
`IS-NONNEGATIVE-WHOLE` and the 255 bound purely, rejecting every other
value as the new InvalidByte Error (kind 16, rendered `INVALID-BYTE`);
`BYTE-VALUE : Byte -> Rat` returns the whole Rat; `BYTE-EQ` through
`BYTE-GTE` compare magnitudes through the unchanged checker. All seven
operations are facade exports with pinned forms, vocabularies, 20-module
purity pins, and the eleven-reader classification updated together.
`tests/byte-test.rkt` passes 210 assertions covering boundary construction,
round trips, every rejection class, Rat arithmetic rejecting Byte with
`ADD(arg1 expected RAT got BYTE)`, host-agreement of all comparisons, and
unary arity. This step also root-caused and fixed a concurrency defect the
Rat/Unit work exposed: `tests/tcp-host-test.rkt` forced Lazy Racket values
from two threads at once (a worker blocked mid-force in a wrapper read while
the main thread forced wrapper writes), and Racket promises are not
thread-safe, so runs failed intermittently with "force: reentrant promise" —
about half the time after the switch widened the forcing windows, versus a
stable pre-switch baseline reproduced 6/6 in a worktree. The suite now keeps
every lambda force on one thread and drives concurrency through a raw
Racket loopback peer socket (the pattern the HTTP suites already use for
test-side clients); ten consecutive runs pass. The full suite passed 11,860
assertions across all 36 test files with the zero-finding boundary
inventory.

### Step 37.2 — Add pure String and byte-sequence conversion

Status: complete (2026-09-01)

- [x] Represent a byte sequence as `List Byte`; add no Bytes tag or host-backed
  byte collection.
- [x] Add pure conversions between String and `List Byte`.
- [x] Validate every List element rather than assuming that any List is a byte
  sequence.
- [x] Implement traversal, validation, and element conversion entirely with
  object-language lambdas.
- [x] Test empty, ordinary text, every boundary byte, embedded zero, invalid List
  elements, laziness, and Error propagation.

Acceptance: AttaLambda can explicitly cross between text and binary data
without using Racket to walk, validate, or transform an object-language List.

Completion evidence: `STRING-TO-BYTES : String -> List` maps one Byte per
Char with the existing pure `raw-map`, and `BYTES-TO-STRING : List ->
String` walks the List validating each element's Byte tag before any
conversion, rejecting a non-Byte element as
`INVALID-BYTE\n  -> BYTES-TO-STRING(result)`. Both are strict facade
exports built on the unchanged checker with pinned forms updated. Tests
cover ABC text, empty values in both directions, the boundary bytes
0/1/127/128/255 with an embedded zero round-tripping byte-exactly,
non-Byte and Char elements rejected, wrong argument types, incoming Error
bubbling, unary arity, and validation stopping at the first bad element
without examining a divergent later element. The full suite passed 11,875 assertions across all 36 test files with the 20-module purity proof and zero-finding boundary inventory.

### Step 37.3 — Move file contents to `List Byte`

Status: complete (2026-09-01)

- [x] Keep filesystem paths as String.
- [x] Make file reads return `Result Ok(List Byte)`.
- [x] Make file writes accept `List Byte` and return `Result Ok(Unit)`.
- [x] Extend only the deterministic codec conversions and existing host operation
  needed to exchange external bytes.
- [x] Keep all object-language List and Byte validation in pure lambdas before the
  host call.
- [x] Update file examples, fake hosts, real-host tests, failures, purity checks,
  and boundary checks together.

Acceptance: arbitrary file bytes round-trip exactly, text and binary data are
no longer conflated, and the host gains no object-language computation.

Completion evidence: `write-file : String -> List -> Result` validates the
byte List purely (`raw-byte-list-valid?`) before any request value exists,
so a non-Byte element is an INVALID-BYTE Error with no host call; the
protocol schema's second write field is a byte-List rule validating each
element's tag and canonical bit payload; the codec gained only
`object-byte-list->bytes` and `bytes->object-byte-list`; and the host's
read path returns `Ok(List Byte)` while its write dispatch decodes the
byte List deterministically. Rebuilding a List object from a
checker-unwrapped payload now restores the one canonical `NIL` for the
empty case — found when an empty write crashed because the codec's
forged-terminator hardening correctly rejected a structurally-empty but
non-canonical rebuilt terminator. `examples/file-round-trip.attl` converts
explicitly with `STRING-TO-BYTES`/`BYTES-TO-STRING`. Fake-host traces,
real-host round trips (binary, empty, replacement, UTF-8 relative paths,
symlink truncation, denied and synthetic failures), the four-field arity
probe, and the design-document amendment moved together. The full suite passed 11,877 assertions across all 36 test files with the 20-module purity proof and zero-finding boundary inventory.

### Step 37.4 — Move TCP and HTTP boundaries to `List Byte`

Status: complete (2026-09-01)

- [x] Make TCP read and write use `List Byte` and make successful writes return
  `Result Ok(Unit)`.
- [x] Keep pure HTTP parsing and rendering text-oriented by converting explicitly
  at the TCP boundary.
- [x] Preserve binary HTTP bodies without treating arbitrary bytes as text.
- [x] Update the HTTP server, protocol validation, host conversion, fake hosts,
  real loopback tests, examples, purity checks, and boundary checks together.

Acceptance: network payloads are explicit byte lists, HTTP remains pure, and
no Racket string, byte sequence, parser, or branch decides an object-language
HTTP result.

Completion evidence: `tcp-write` takes a `List Byte` validated purely
(canonical-NIL rebuild included) before any request exists, with the
protocol's write schema on the shared byte-List rule; `tcp-read` returns
`Ok(List Byte)` with EOF as the empty List; successful writes were already
`Ok(UNIT)`. The HTTP server converts exactly at the boundary — received
bytes become Chars one-to-one before the pure parser runs, and the rendered
response String becomes bytes one-to-one before `tcp-write` — so parsing,
routing, and rendering remain text-oriented lambda computation and binary
bodies survive byte-exactly. Fake-host scripts, trace decoders, the raw-peer
loopback suite, and the real end-to-end HTTP example all moved together;
the milestone-two acceptance run serves the example over the byte-List
boundary. The full suite passed 11,877 assertions across all 36 test files
with the 20-module purity proof and zero-finding boundary inventory.

## Phase 38 — Add Option

### Step 38.1 — Add Some and None

Status: complete (2026-09-01)

- [x] Add `SOME value` and the singleton `NONE` as the two Option forms.
- [x] Add checks for Some and None and a lazy pure operation that chooses what to
  do in either case.
- [x] Let Some contain any non-Error object-language value without adding an
  `Any` tag or changing the generalized checker.
- [x] Propagate an early Error rather than hiding it inside Some.
- [x] Keep Option distinct from Result: None means expected absence, while
  `Result Err` means a computation failed.
- [x] Add reader, representation, branch-laziness, Error-propagation, purity, and
  public-language tests.

Acceptance: expected absence has a small pure representation and cannot be
confused with failure, false, zero, NIL, or Unit.

Completion evidence: `core/option.rkt` mirrors the Result shape at tag 10
(church-ten). `SOME` accepts any non-Error value and bubbles an Error
argument; `NONE` is the singleton; `IS-SOME`/`IS-NONE` are strict Bool
checks on the unchanged checker; `OPTION-CASE option some-function
none-value` is the lazy polymorphic eliminator, strict on its Option with
`OPTION-CASE(arg1 expected OPTION ...)` frames and no evaluation of the
unselected branch. All five names are facade exports with pinned forms,
vocabularies, 21-module purity pins, and the twelve-reader classification
updated together; `readers/option.rkt` renders SOME/NONE one way. Tests
cover representation tags for Some over Rat/Bool/NIL/nested-Option values,
strict checks, distinctness from Bool/List/Rat/Error/Unit, Error
propagation, both laziness directions, mismatch and bubbling frames, and
unary arity. The full suite passed 11,911 assertions across all 37 test
files with the zero-finding boundary inventory.

## Phase 39 — Add persistent Map

A persistent Map returns a new Map after setting or removing an entry and
never alters the old Map.

### Step 39.1 — Add Map representation and lookup

Status: complete (2026-09-01)

- [x] Construct a Map with a user-supplied pure object-language key-equality
  function.
- [x] Store entries as a private object-language List of Pairs, never as a Racket
  list, association list, hash table, dictionary, struct, or mutable value.
- [x] Add empty, lookup, and reader behavior.
- [x] Make lookup return `SOME value` or `NONE`.
- [x] Check that the supplied equality function returns Bool; otherwise return a
  structured Error.
- [x] Implement every search and branch with pure unary lambdas.

Acceptance: lookup works for user-defined key equality, expected absence uses
Option, and no host collection or host equality participates.

Completion evidence: `core/map.rkt` (tag 11, church-eleven) pairs the fixed
equality function with a raw Pair-entry List. `MAKE-MAP` bubbles Error
arguments; `MAP-EMPTY?` and `MAP-SIZE` (whole Rat via the raw List counter)
use the unchanged checker; `MAP-LOOKUP` validates its Map argument manually
(the `IF`/`OPTION-CASE` polymorphic pattern), bubbles an Error key with a
result frame, and walks entries with the Map's own equality function,
returning `SOME value` or `NONE`. A comparison answering an Error bubbles
with the operation's frame; any other non-Bool answer renders as
`MAP-LOOKUP(arg1 expected BOOL got …)`. All four names are facade exports
with pinned forms, vocabularies, 22-module purity pins, and the
thirteen-reader classification updated together; `readers/map.rkt` renders
the entry count. Tests cover empty and populated lookup under Rat equality,
both malformed-equality answers, wrong and Error Map/key arguments, size
and emptiness, and unary arity. The full suite passed 11,935 assertions
across all 38 test files with the zero-finding boundary inventory.

### Step 39.2 — Add Map updates and queries

Status: complete (2026-09-01)

- [x] Add pure set, remove, contains, empty, and size operations.
- [x] Replace an existing key without creating a duplicate entry.
- [x] Return size as a whole-valued Rat.
- [x] Accept arbitrary non-Error keys and values without adding an `Any` tag or
  changing the generalized checker.
- [x] Prove that an older Map still returns its older answers after a new Map is
  produced from it.
- [x] Test Rat, String, Char, and Byte equality functions, collisions under a
  custom equality function, missing keys, replacement, removal, size, Error
  propagation, partial application, and laziness.

Acceptance: Map is useful, immutable, and entirely lambda-built; Unit values
can represent set membership without adding a Set type.

Completion evidence: `MAP-SET` replaces a matched key in place (no
duplicate entry) or prepends an absent one, `MAP-REMOVE` of an absent key
returns an equivalent Map, and `MAP-CONTAINS?` answers Bool — all built on
the shared find/walk machinery whose mid-walk comparison failure becomes
the whole answer instead of hiding inside a rebuilt List. Error keys and
values bubble with the operation's frame. During this step MAKE-MAP's
former Error-bubbling probe was removed as unsound: applying a tag check
to an arbitrary supplied function is undefined under the closed strict
convention, so the constructor accepts the function as-is and the Bool
contract is enforced at every comparison. Tests build a three-entry Rat
map through replacement and removal while proving every older Map keeps
its older answers, drive String/Char/Byte equality functions, prove
deliberate collisions under an always-true equality collapse to one
entry, and cover contains, Error propagation, wrong-Map mismatches,
mid-walk failure, unary partial application, and update laziness. The
full suite passed 11,970 assertions across all 38 test files with the
22-module purity proof and zero-finding boundary inventory.

## Phase 40 — Milestone acceptance

### Step 40.1 — Prove the complete language together

Status: complete (2026-09-01)

- [x] Add end-to-end standalone examples covering negative fractions, exact
  division, powers, Unit effect results, binary file and TCP data, Option, and
  Map.
- [x] Re-run the complete structural purity proof and boundary inventory so every
  new production file is classified and checked.
- [x] Verify mechanically that every production object-language computation
  expands to variables, unary `lambda`, and application only.
- [x] Verify that no public Nat or Int type, literal, function, reader, tag, or
  export remains.
- [x] Verify that no Racket arithmetic, conditional, collection, mutation, or
  equality operation decides an Int, Rat, Unit, Byte, Option, or Map result.
- [x] Run the complete source suite, supported Linux distribution build, and
  no-Racket Linux consumer test.
- [x] Update current documentation and examples, distinguish observed behavior
  from future possibilities, and record honest performance limits.
- [x] Leave the version at `0.3.0-dev`; release preparation, signing, artifact
  publication, tagging, and public claims require a later separate plan and
  explicit approval.

Acceptance: AttaLambda exposes Rat as its sole number type plus Unit, Byte,
Option, and Map; all underlying definitions and computation remain pure
untyped lambda calculus; Racket remains confined to the same narrow mechanical
and external-world seams; and the complete source and supported-distribution
verification passes.

Completion evidence: `examples/foundations.attl` prints nine deterministic
`ok` lines through the real runner — negative fractions, exact division,
whole powers with negative exponents, floor, a Unit stdout acknowledgement,
byte/text crossing, Option over a Map lookup, and Map persistence — and is
threaded through the boundary inventory, every build script, and every
platform consumer contract; the existing file and HTTP examples cover the
binary file and TCP boundaries. The full suite passed 11,974 assertions
across all 38 test files with the 22-module expanded purity proof (unary
lambda and forbidden-form verification over every production module) and
the zero-finding boundary inventory including the `reintroduced-nat-surface`
scan; retired spellings fail to resolve in the fresh-install language
tests. The supported Linux distribution built from a clean clone of commit
`a1f125b` under the pinned Racket CS 9.3 toolchain in a container:
`attalambda-0.3.0-dev-linux-x86_64.tar.gz`, SHA-256
`0261fcc7e05807f220e5c96ea32feea972c4ca895cd02a32bed947de3ce7c860`,
13,939,568 compressed bytes, 59,742,222 unpacked regular-file bytes, 11
files, 2 runtime files, with only the ELF loader, `libc`, `libdl`, `libm`,
`libpthread`, and `librt` as system-library assumptions. The independent
no-Racket consumer script verified the external checksum, confirmed absent
`racket`/`raco` commands and loopback-only network, ran the complete
end-user guide workflow, and passed relocation, reporting
`consumer_acceptance=passed` with 298 ms first startup and 280 ms after
relocation. These are internal development observations of an unpublished
artifact, not a release; `VERSION` remains `0.3.0-dev`, and release
preparation, tagging, signing, publication, and public claims require a
later separate plan and Kyle's explicit approval. `docs/ACCEPTANCE.md`
carries the Milestone 4 criterion map and honest performance limits
(gcd-reducing interpreted arithmetic, linear Map walks, the documented
HTTP re-parse bound).

# Release 0.3.0 — AttaLambda's second public release

Status: complete (2026-09-02)

Kyle approved the full release train on 2026-09-02: Linux x86-64 is the only
binary target (no Windows machine; no paid Apple signing). Publication
approval for 0.3.0 was given explicitly ("let's commit our work and push and
go for it").

## Step R.1 — Merge the milestone

- [x] Merge `milestone-4-rationals` into `main` with a no-fast-forward merge
  commit and push `main`. Merge commit `283c7be` (2026-09-02).

## Step R.2 — Finalize version 0.3.0

- [x] `VERSION` becomes exactly `0.3.0` + LF; `info.rkt` package version
  becomes `0.3`; the runner's accepted-version pattern gains `0.3.0`; the
  boundary gate's product-version projection table and its test copy gain
  `0.3.0 -> 0.3`; the three build scripts and the macOS test harness accept
  `0.3.0`; `runner-test.rkt` expects `AttaLambda 0.3.0`; fixture restore
  literals in the boundary and runner tests follow the released state.
- [x] Full suite, purity, and boundary gates green on `main`: 38 files,
  12,298 assertions, 29-module purity proof, zero-finding inventory
  (2026-09-02).

## Step R.3 — Build and independently verify the Linux artifact

- [x] Built `attalambda-0.3.0-linux-x86_64.tar.gz` and `SHA256SUMS` under the
  pinned Racket CS 9.3 toolchain in Docker from a clean clone of release
  commit `1b51603`: SHA-256
  `7adc7343720b0a1d6ed86af47059f031f571ab93649a314303c56d6b8a3d7870`,
  13,938,743 compressed bytes, 59,742,960 unpacked bytes, 11 files.
- [x] Consumer acceptance passed in a fresh no-Racket Ubuntu 24.04 container
  using only the transferred archive and manifest: checksum OK, complete
  guide workflow, relocation, loopback-only network, 362 ms first startup
  (`consumer_acceptance=passed`, 2026-09-02).

## Step R.4 — Tag and publish

- [x] Annotated tag `v0.3.0` on release commit `1b51603`, pushed.
- [x] GitHub Release `AttaLambda 0.3.0` published at
  <https://github.com/kserrec/attalambda/releases/tag/v0.3.0> with the Linux
  archive and `SHA256SUMS`, Linux x86-64 named as the sole supported target.
- [x] Both public download URLs re-downloaded fresh; byte counts exact and
  `sha256sum -c SHA256SUMS` printed OK (2026-09-02).

## Step R.5 — Record the publication

- [x] README's download section, `docs/design/standalone-distribution.md`,
  `docs/ACCEPTANCE.md`, `HANDOFF.md`, and this plan record the published
  artifact's exact bytes and SHA-256.
