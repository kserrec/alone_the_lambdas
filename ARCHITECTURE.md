# Architecture

This document records both the target architecture and the verified current
state. Phase 1 implements the lazy host shell, mechanical syntax, lambda pairs,
and raw Boolean logic. Phase 2 adds the seven Church tags, the generic
lambda-encoded typed-object shape, external observation, and a structural
purity gate that rejects host computation and host data. Phase 3 adds explicit
Michaelson-style Lists, strict bootstrap primitives, and raw recursive List
algorithms. Phase 4 adds normalized binary Nat values, direct raw binary
arithmetic and comparison, and the Nat-dependent List operations. Phase 5
replaces provisional failures with structured Error roots and propagation
frames. Phase 6 adds the single generalized curried runtime checker, its
signature-driven Error absorbers and return policies, and migrates every
eligible bootstrap List operation onto it. Phase 7 adds tagged Bool values,
strict checker-backed Boolean operations, and the canonical lazy typed
conditional.

## Computational boundary

The object language is pure untyped lambda calculus:

1. variables;
2. exactly unary `lambda`;
3. application.

Every computationally meaningful production term must contain only those forms
after mechanical macro expansion. There is no host-computation escape hatch.
Multi-argument functions are nested unary lambdas, and partial application is
ordinary application.

Racket supplies only the enclosing module system, lazy evaluation, syntactic
sugar, readers, tests, and development tooling. It must not decide
object-language results or provide object-language representations.

## Layers

| Layer | Responsibility |
| --- | --- |
| Host shell | Racket modules, `#lang lazy`, exports, test and reader plumbing |
| Mechanical syntax | `def`, lambda-based `let`, and other expansion-only sugar |
| Raw calculus | Pairs, raw Boolean selectors, tags, and untyped algorithms |
| Typed objects | Uniform tag/payload representation and strict validation |
| Public data | List, Nat, Error, Result, Char, and String |
| Public language | Canonical exports such as `lambda`, `def`, `let`, `if`, and `cons` |
| Human boundary | Readers and test diagnostics; never object-language computation |

Dependencies point downward only. Typed operations may use raw operations; raw
operations must not depend on typed wrappers. Readers may inspect values but
production code must never depend on readers.

## Implemented foundation

The implemented dependency path is deliberately short. The lazy module shell
sits under the mechanical macro layer. Pair and logic depend on that
foundation; tags depend on raw logic; typed objects depend on pairs and tags.
Fixed-point recursion ties canonical `NIL` and its canonical empty-List Error
inside `core/errors.rkt`; Lists then depend on that lower representation knot.
Readers are test-only, and no production module depends on them. Binary Nat
depends on the raw List representation; `core/list-nat.rkt` sits above both
modules so Nat-dependent List operations do not create a dependency cycle.
The checker reads its List signatures through the lower object and pair
representation instead of importing `core/lists.rkt`; this lets the ordinary
typed List operations depend on the checker without a cycle. Typed logic sits
above raw logic, objects, Lists, and the checker; this keeps its List-encoded
signatures and strict wrappers out of the raw Boolean layer.

`def` mechanically builds any requested arity as nested unary lambdas.
`lambda-let` expands one binding into one unary-lambda application; the future
standalone language will export that binding as canonical `let`. `raw-if` is an
ordinary curried selector function, not a host conditional. The reader forces
and formats raw Booleans only from outside production computation. The strict
conditional remains internally named `typed-if`; `core/typed-logic.rkt` also
exports that binding under canonical `if` without changing internal raw names.

`core/tags.rkt` defines Church zero through six for Error, Bool, List, Nat,
Result, Char, and String. The same tiny Church values may serve in separate
metadata namespaces such as Error kinds and argument positions. Its private
predecessor and subtraction terms exist only to implement `raw-tag-equal`;
they are not a public arithmetic system. `core/objects.rkt` represents a typed
object as a lambda pair of tag and payload. `raw-object-type`,
`raw-object-value`, and `raw-is-type` operate only on canonical project
objects, not arbitrary untyped lambda terms.

## Representation contracts

### Tiny discriminants

The seven runtime type tags use Church numerals:

| Tag | Type |
| ---: | --- |
| 0 | Error |
| 1 | Bool |
| 2 | List |
| 3 | Nat |
| 4 | Result |
| 5 | Char |
| 6 | String |

Tags are closed discriminants, not public arithmetic values. Structured Error
kinds and argument positions also reuse tiny Church values as explicitly
permitted metadata. Ordinary numeric computation always uses binary Nat.

### Objects

A runtime-typed object carries a tag and payload using lambda-encoded
structure. The representation must remain entirely inside the calculus.

### Booleans and conditional

`TRUE` and `FALSE` are Bool-tagged objects containing `raw-true` and
`raw-false`. `typed-not`, `typed-and`, `typed-or`, and `typed-xor` use the
generalized checker with List signatures, unwrap their Bool inputs, run the
existing raw operations, and wrap the raw result as Bool. The module also
exports the specified `NOT`, `AND`, `OR`, and `XOR` names.

`typed-if` validates only its tagged Bool condition because both branches are
intentionally polymorphic. A valid condition unwraps to the raw selector and
chooses without forcing the other branch. A wrong condition or incoming Error
returns two unary ignoring continuations before exposing the failure, so the
conditional retains its full curried application shape. The generalized
monomorphic checker remains unchanged, as the specification allows.

### Lists

Lists use an explicit Michaelson-style representation. A nonempty List is a
List-tagged object whose payload pairs a head with another List object. `NIL`
is itself List-tagged; its payload contains the canonical empty-List Error in
both positions, so it is neither false nor numeric zero. That Error's empty
frame List is the same `NIL`; `raw-fix` ties this finite lazy graph without a
host reference or module cycle. `typed-cons` is the only strict constructor
and accepts only a List tail. NIL recognition checks the tail's Error tag in
O(1), so an Error head does not make a nonempty List look empty.

`typed-head`, `typed-tail`, and `typed-is-nil` use the generalized checker with
a one-element List signature. Wrong concrete types create structured
TypeMismatch roots, while incoming Errors gain the current argument frame.
`typed-cons` remains a direct strict constructor because its head is
intentionally polymorphic and therefore has no expected runtime tag for a
signature entry. Its polymorphic head preserves an incoming Error without
inventing an expected type; its List tail has ordinary framed propagation.
`typed-is-nil` now wraps its O(1) raw predicate result as a tagged Bool. The raw
layer currently provides a right fold, append, reverse, map, and filter; the
fold callback receives the head followed by the folded tail.

`core/list-nat.rkt` adds raw length, take, and drop after binary Nat is
available. Length returns canonical raw Nat bits. Take and drop accept raw Nat
bits first and a List second; taking beyond the end returns the complete List,
while dropping beyond the end returns `NIL`. The strict wrappers now use the
generalized checker. They accept tagged Nat and List values, bubble incoming
Errors, and preserve the one remaining application after a bad first argument.

### Natural numbers

Public Nat values are normalized binary digit lists in most-significant-bit
first order. Zero has exactly one representation, `[0]`; positive values have
no leading zeroes. Each digit is a raw lambda Boolean inside the same proper
List structure used elsewhere; the outer Nat object supplies the runtime type.

`core/binary-nat.rkt` normalizes empty or all-zero internal inputs to `[0]` and
removes every unnecessary leading zero. It implements raw zero testing,
successor, addition, saturating subtraction, multiplication, equality, and all
four order comparisons directly on MSB-first digit Lists. Addition and
subtraction reverse their operands for carry and borrow propagation;
multiplication scans one operand with binary shift-and-add. None converts
through Church numerals or host numbers. `ZERO` through `TEN` are canonical
typed constants. Phase 8 adds the strict typed arithmetic API by reusing the
now-implemented generalized checker and Bool layer.

### Errors and results

Every Error is an Error-tagged object whose payload pairs one immutable root
with a proper List of propagation frames. Root kinds are the small Church
discriminants TypeMismatch, EmptyList, InvalidNat, and DivideByZero. A
TypeMismatch root additionally stores its argument position, expected runtime
type, and actual runtime type. The other current roots need no extra details.

A frame pairs an argument position with the expected runtime type at the
current boundary. `raw-bubble-error` reuses the exact root and prepends one
frame, so the frame List is newest-first and root metadata never changes.
Function names remain absent until canonical String exists in Phase 11; Phase
12 adds those names and the Error reader. Language-level failures never use
host exceptions or strings.

`Result` represents an expected success-or-failure outcome. Its error branch
contains an Error value but does not turn expected failure into a language
contract violation.

### Characters and strings

`Char` contains a binary Nat constrained to 0 through 255. `String` is a
List of Char values.

## Runtime typing

`make-typed-function` accepts a raw curried function, an Alone the Lambdas List
of expected type tags, and one unary return policy. It constructs strict typed
functions of arbitrary arity by:

- validating one argument per application;
- bubbling an existing Error with the current expected type and Church-encoded
  argument position;
- creating a structured Error for a wrong runtime type;
- unwrapping a valid argument and partially applying the raw function;
- preserving remaining arity with one unary absorbing continuation per
  unconsumed signature entry after an early failure; and
- applying `raw-wrap-return` for a raw result or `raw-keep-return` for a result
  that is already typed.

The empty signature also supports a zero-argument raw value. No host arity
counting or arity-specific checker variant exists. `typed-if` is the specified
custom polymorphic exception: it reuses the same Error construction and
framing primitives while preserving two untyped branch positions itself.

## Naming

Internal names state their semantic layer:

- `raw-*` for raw representations and algorithms;
- `typed-*` for strict runtime-typed operations.

Public exports use canonical language vocabulary. Underscore prefixes must not
exist solely to avoid Racket bindings. Host collisions are handled at module
boundaries through renaming and selective export.

## Repository layout

```text
macros/
  lazy-with-macros.rkt
  macros.rkt
core/
  pair.rkt
  logic.rkt
  tags.rkt
  objects.rkt
  fix.rkt
  errors.rkt
  lists.rkt
  binary-nat.rkt
  list-nat.rkt
  typecheck.rkt
  typed-logic.rkt
  # Later phases add the modules below.
  result.rkt
  chars.rkt
  strings.rkt
readers/
tests/
tooling/
run-all-tests.sh
```

Eleven production modules currently exist under `core/`; the remaining core
paths are planned in dependency order. New abstraction layers require a
concrete need.

## Verification boundary

The test suite checks macro currying and hygiene, pair selection, every raw
Boolean truth-table row, and lazy non-evaluation of rejected pair fields and
`raw-if` branches. It also proves all 49 pairwise tag comparisons, every tag
and payload round trip, object/accessor currying, and accessor laziness. The
List suite covers NIL identity, proper tails, nested traversal, strict
failures, Error bubbling, laziness, and every implemented raw helper. Binary
Nat tests cover normalization, the typed constants, carries, borrows,
saturating subtraction, multiplication, comparisons, larger bit widths,
currying, and applicable laziness. Nat-dependent List tests cover length,
take, drop, boundary counts, proper tails, strict failures, Error absorption,
currying, and lazy base cases. Structured Error tests cover every kind, root
metadata, the `NIL`/empty-Error knot, frame order, nested root preservation,
canonical List failures, currying, and lazy field access. The generalized
checker suite covers lambda List signatures and zero-, one-, two-, three-, and
five-argument functions; valid partial application; every five-argument
mismatch position; incoming Error framing; raw and already-typed return
policies; exact remaining-arity absorption; and ignored-argument laziness. The
typed-logic suite covers both tagged Bool constants, every strict operation
truth-table row, mismatch and incoming-Error propagation at each applicable
position, curried shape, typed `IS-NIL`, polymorphic branch results, canonical
exports, and divergent unselected branches. The structural purity tool scans
production Racket sources for non-unary lambdas, host-style function
definitions, forbidden host computation, and host literal data. It will be
hardened further as later production forms arrive.

## Deferred boundary

This milestone contains no `host` form. A later milestone may introduce
exactly one explicit host boundary without weakening the purity of ordinary
language code.
