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
conditional. Phase 8 adds the strict checker-backed Nat API without changing
the raw binary algorithms. Phase 9 adds lambda-encoded Result values, strict
Result operations, raw binary long division, and safe typed `DIV`. Phase 10
adds bounded binary Char values, strict construction, lambda-built constants,
and a one-way host reader. Phase 11 adds Char-List-backed String values,
recursive invariant validation, the initial strict String algorithms, and a
one-way String reader. Phase 12 adds pure canonical String names to every
strict Error boundary, renders structured diagnostics at the one-way reader
boundary, hardens the production purity gate, and closes the milestone with
criterion-level acceptance coverage. Phase 13 fixes the proposed host request
protocol, trust boundary, module split, and future purity classifications in a
design document; no production interop code exists yet.

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

> Alone the Lambdas does not merely avoid using host libraries for major
> algorithms. Its production computational terms are built exclusively from
> unary lambda abstraction and application. Every multi-argument function is
> represented by nested one-argument lambdas. Racket is used only to
> host/evaluate the terms, provide mechanical syntactic sugar and module
> tooling, test them, and observe completed values for humans. Until `host` is
> deliberately introduced, no other computational escape hatch exists.

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
`core/typed-nat.rkt` similarly sits above binary Nat, Lists, tags, and the
checker. It owns the public strict Nat surface while leaving every binary
algorithm in `core/binary-nat.rkt` raw and reusable.
`core/result.rkt` sits above Errors, Lists, objects, and the checker. Typed Nat
depends on Result only for safe `DIV`, so Result itself remains independent of
Nat and available to later data types.
`core/chars.rkt` sits above raw binary Nat, Errors, Lists, objects, and the
checker. Its reader depends on Char and Nat observation, while no production
module depends on that reader. `core/strings.rkt` sits above Char, List, raw
List length, Errors, objects, and the checker. It reuses those raw layers
directly, while `readers/string.rkt` remains outside the production dependency
graph.

Named Error frames would create a cycle if Errors depended on the full String
module. `core/function-names.rkt` therefore builds only the representation it
needs from lower object, pair, tag, and raw-logic layers. The
`define-function-name` macro translates an identifier spelling into an
expression made from those pure constructors. Racket computes syntax during
mechanical expansion; every generated runtime value is still a tagged String
containing a proper List of tagged Chars. Strict modules depend on these name
constants, while Errors remain below String algorithms.

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
multiplication scans one operand with binary shift-and-add. Division performs
MSB-first binary long division, maintaining a remainder and building quotient
bits without repeated host or Church arithmetic. Its raw contract requires a
nonzero divisor; the strict layer owns the zero policy. None of these
algorithms converts through Church numerals or host numbers. `ZERO` through
`TEN` are canonical typed constants.

`core/typed-nat.rkt` routes every public Nat operation through the generalized
checker. `SUCC`, `ADD`, `SUB`, and `MULT` return tagged Nat values; `EQ`, `LT`,
`LTE`, `GT`, `GTE`, and `IS-ZERO` return tagged Bool values. `DIV` uses the
same two-Nat signature but keeps its already-typed Result return. Valid
division by a nonzero value returns Ok containing a canonical Nat; valid
division by zero returns Err containing the canonical DivideByZero Error.
Unary operations use one Nat signature entry, and binary operations use two,
so partial application, wrong-type failures, incoming-Error bubbling, and
remaining-arity absorption all have the same behavior as other strict typed
functions. Every Nat boundary records its canonical function-name String,
argument position, and expected Nat type when it creates or propagates an
Error.

### Errors and results

Every Error is an Error-tagged object whose payload pairs one immutable root
with a proper List of propagation frames. Root kinds are the small Church
discriminants TypeMismatch, EmptyList, InvalidNat, DivideByZero, and
InvalidChar, plus InvalidString for a List that violates the String element
invariant. A TypeMismatch root additionally stores its argument position,
expected runtime type, and actual runtime type. The other current roots need
no extra details.

A frame contains a canonical function-name String, argument position, and
expected runtime type for the current boundary. `raw-bubble-error` reuses the
exact root and prepends one frame, so the frame List is newest-first and root
metadata never changes. Fresh TypeMismatch roots receive the same named frame
as propagated Errors. Root Errors produced by a valid raw algorithm remain
unframed until another strict boundary propagates them. The polymorphic
`typed-cons` head and `make-ok` also preserve an incoming Error without adding
a frame because neither position has an expected runtime type to record.

`readers/error.rkt` reverses the stored frame List for causal display, renders
the oldest mismatch frame with its actual type, and then prints each later
boundary as an arrow. Function names remain structured String values inside
the Error; only the reader flattens them to diagnostic text. Language-level
failures never use host exceptions or strings.

`core/result.rkt` represents Result as a Result-tagged object whose payload
pairs a raw Boolean discriminator with a payload. True identifies Ok; false
identifies Err. `make-ok` accepts a polymorphic value but preserves an incoming
Error instead of hiding it. `make-err` is the intentional exception to normal
Error bubbling: it requires an Error and stores that Error as data. A wrong
non-Error argument remains a TypeMismatch Error.

`is-ok`, `is-err`, `unwrap-ok`, and `unwrap-err` strictly require Result via
the generalized checker. The predicates return tagged Bool values; the unwrap
operations return the stored payload without automatically propagating it.
Callers use the predicates to select the matching unwrap operation. This is
the semantic boundary: a Result Err is an ordinary valid Result until a caller
explicitly unwraps and uses its Error payload.

### Characters and strings

`core/chars.rkt` represents Char as a Char-tagged object containing normalized
raw Nat bits rather than a nested Nat object. Its pure upper bound is computed
as `(16 × 16) − 1` with raw binary operations. `MAKE-CHAR` uses the generalized
checker for its Nat argument, returns Char for values 0 through 255, and returns
the canonical InvalidChar Error above that range.

`CHAR-EQ`, `CHAR-LT`, `CHAR-LTE`, `CHAR-GT`, and `CHAR-GTE` use two-Char
signatures through the same checker. They reuse raw binary Nat comparisons on
unwrapped Char payloads and return tagged Bool values.

The module defines every required upper- and lowercase letter, decimal digit,
control constant, and named punctuation constant as a genuine lambda-built
Char. Constants are derived from binary Nat values and unary successor chains;
production code contains no host numbers or character literals.

`readers/char.rkt` converts a completed Char payload to a host integer or
display string. It renders TAB, LF, CR, and printable ASCII directly and uses
`char:<integer>` for unsupported values. This observation is one-way and never
feeds host characters back into production computation.

`core/strings.rkt` represents String as a String-tagged object whose payload is
the canonical List object containing typed Char elements. `EMPTY-STRING` uses
`NIL`. `MAKE-STRING` strictly requires a List and recursively checks every
element's Char tag using lambda computation; a well-typed List containing any
non-Char element returns the canonical InvalidString Error.

`STRING-EMPTY?`, `STRING-LENGTH`, `STRING-EQ`, `STRING-APPEND`,
`STRING-HEAD`, `STRING-TAIL`, `STRING-PREFIX?`, and `STRING-CONTAINS?` all use
the generalized checker. The raw algorithms traverse List structure and
compare Char binary payloads directly. Length reuses the canonical raw binary
List counter and returns Nat. Head returns Char; tail returns String; either
partial operation returns EmptyList Error on the empty String. Prefix and
contains take the searched String first and the candidate prefix or substring
second; an empty candidate succeeds.

`readers/string.rkt` traverses the completed Char List and joins the Char
reader's host output. No production module imports it, and no host string
operation participates in equality, append, prefix, or substring search.

## Runtime typing

`make-typed-function` accepts, in order, a raw curried function, a canonical
function-name String, an Alone the Lambdas List of expected type tags, and one
unary return policy. It constructs strict typed functions of arbitrary arity
by:

- validating one argument per application;
- bubbling an existing Error with the current function name, expected type,
  and Church-encoded argument position;
- creating and framing a structured Error for a wrong runtime type;
- unwrapping a valid argument and partially applying the raw function;
- preserving remaining arity with one unary absorbing continuation per
  unconsumed signature entry after an early failure; and
- applying `raw-wrap-return` for a raw result or `raw-keep-return` for a result
  that is already typed.

The empty signature also supports a zero-argument raw value. No host arity
counting or arity-specific checker variant exists. The purity gate explicitly
rejects numbered checker names. `typed-if` is the specified custom polymorphic
exception: it reuses the same named Error construction and framing primitives
while preserving two untyped branch positions itself. `typed-make-ok` is
likewise polymorphic, while `typed-make-err` intentionally accepts Error as
data instead of invoking the checker's normal Error bubbling.

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
  function-names.rkt
  lists.rkt
  binary-nat.rkt
  result.rkt
  chars.rkt
  typed-nat.rkt
  list-nat.rkt
  typecheck.rkt
  typed-logic.rkt
  strings.rkt
readers/
  char.rkt
  error.rkt
  string.rkt
tests/
tooling/
run-all-tests.sh
```

Sixteen production modules currently exist under `core/`. New abstraction
layers require a concrete need.

## Verification boundary

The test suite checks macro currying and hygiene, pair selection, every raw
Boolean truth-table row, and lazy non-evaluation of rejected pair fields and
`raw-if` branches. It also proves all 49 pairwise tag comparisons, every tag
and payload round trip, object/accessor currying, and accessor laziness. The
List suite covers NIL identity, proper tails, nested traversal, strict
failures, Error bubbling, laziness, and every implemented raw helper. Binary
Nat tests cover normalization, the typed constants, carries, borrows,
saturating subtraction, multiplication, long division, quotient laws,
comparisons, larger bit widths, currying, and applicable laziness.
Nat-dependent List tests cover length, take, drop, boundary counts, proper
tails, strict failures, Error absorption, currying, and lazy base cases.
Structured Error tests cover every kind, root
metadata, the `NIL`/empty-Error knot, frame order, nested root preservation,
canonical function-name Strings, List failures, currying, and lazy field
access. The Error reader suite exercises all 43 named strict boundaries, all
seven rendered type tags, every current root kind, and nested causal output.
The generalized
checker suite covers lambda List signatures and zero-, one-, two-, three-, and
five-argument functions; valid partial application; every five-argument
mismatch position; incoming Error framing; raw and already-typed return
policies; exact remaining-arity absorption; and ignored-argument laziness. The
typed-logic suite covers both tagged Bool constants, every strict operation
truth-table row, mismatch and incoming-Error propagation at each applicable
position, curried shape, typed `IS-NIL`, polymorphic branch results, canonical
exports, and divergent unselected branches. The typed Nat suite covers all
constants and public operations, representative large values, arithmetic and
comparison semantics, every applicable mismatch and incoming-Error position,
root preservation, exact absorber arity, ignored-argument laziness, currying,
and canonical exports. The Result suite covers Ok and Err representation,
strict constructors and accessors, Error encapsulation, mismatch and incoming
Error behavior, safe division results, quotient laws, exact absorber arity,
zero-divisor laziness, explicit post-unwrap propagation, currying, and public
exports. The Char suite covers every required constant, normalized raw-bit
payloads, 0 and 255 acceptance, 256 rejection, InvalidChar roots, mismatch and
incoming-Error behavior, reader output and fallbacks, currying, and reader
isolation. The String suite covers representation, recursive Char validation,
InvalidString roots, raw and strict operations, canonical binary length,
empty partial-operation errors, List/Char interaction, prefix and substring
boundaries, mismatch and incoming-Error propagation, exact binary-operation
absorbers, laziness, currying, and reader output. The milestone acceptance
suite composes Bool, List, Nat, Result, Char, String, and Error behavior in one
strict typed flow and runs the same structural scan over the complete core.

The structural purity tool scans all 16 production Racket modules for
non-unary lambdas, host-style function definitions, forbidden host computation
and literals, the absent `host` escape, and numbered arity-specific checker
variants. Focused tests prove representative violations are rejected. The
complete evidence map is [docs/ACCEPTANCE.md](docs/ACCEPTANCE.md).

## Planned boundary

The completed core contains no `host` form. Phases 13 through 20 in
[PLAN.md](PLAN.md) design and then introduce exactly one explicit host
boundary, ordinary lambda effect wrappers, a minimal lambda-built HTTP server,
and the standalone language surface. The proposed protocol and its full
process-level filesystem/network authority are recorded in
[docs/design/host-boundary.md](docs/design/host-boundary.md). Phase 13 is
complete as design work, but Phase 14 remains blocked pending explicit
approval because the three specifications deliberately leave that protocol
undefined.
