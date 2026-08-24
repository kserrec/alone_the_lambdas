# Architecture

This document records both the target architecture and the verified current
state. Phase 1 implements the lazy host shell, mechanical syntax, lambda pairs,
and raw Boolean logic. Phase 2 adds the seven Church tags, the generic
lambda-encoded typed-object shape, external observation, and a structural
purity gate that rejects host computation and host data. Phase 3 adds explicit
Michaelson-style Lists, strict bootstrap primitives, and raw recursive List
algorithms.

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
Fixed-point recursion and provisional bootstrap Errors support Lists. Readers
are test-only, and no production module depends on them.

`def` mechanically builds any requested arity as nested unary lambdas.
`lambda-let` expands one binding into one unary-lambda application; the future
standalone language will export that binding as canonical `let`. `raw-if` is an
ordinary curried selector function, not a host conditional. The reader forces
and formats raw Booleans only from outside production computation.

`core/tags.rkt` defines Church zero through six solely to name Error, Bool,
List, Nat, Result, Char, and String. Its private predecessor and subtraction
terms exist only to implement `raw-tag-equal`; they are not a public arithmetic
system. `core/objects.rkt` represents a typed object as a lambda pair of tag
and payload. `raw-object-type`, `raw-object-value`, and `raw-is-type` operate
only on canonical project objects, not arbitrary untyped lambda terms.

## Representation contracts

### Type tags

Only type tags use Church numerals:

| Tag | Type |
| ---: | --- |
| 0 | Error |
| 1 | Bool |
| 2 | List |
| 3 | Nat |
| 4 | Result |
| 5 | Char |
| 6 | String |

Tags are closed discriminants, not public arithmetic values.

### Objects

A runtime-typed object carries a tag and payload using lambda-encoded
structure. The representation must remain entirely inside the calculus.

### Lists

Lists use an explicit Michaelson-style representation. A nonempty List is a
List-tagged object whose payload pairs a head with another List object. `NIL`
is itself List-tagged; its payload contains the provisional empty-List Error in
both positions, so it is neither false nor numeric zero. `typed-cons` is the
only strict constructor and accepts only a List tail. NIL recognition checks
the tail's Error tag in O(1), so an Error head does not make a nonempty List
look empty.

During bootstrap, `typed-cons`, `typed-head`, `typed-tail`, and `typed-is-nil`
perform their checks manually and bubble an incoming Error unchanged. Their
opaque Error payloads are provisional: Phase 5 replaces them with structured
roots, and Phase 6 moves ordinary strict checks onto the generalized checker.
`typed-is-nil` returns a raw Boolean until the typed Bool layer exists. The raw
layer currently provides a right fold, append, reverse, map, and filter; the
fold callback receives the head followed by the folded tail. Nat-dependent
length, take, and drop wait for canonical binary Nat in Phase 4.

### Natural numbers

Public Nat values are normalized binary digit lists in most-significant-bit
first order. Zero has exactly one representation, `[0]`; positive values have
no leading zeroes. Raw arithmetic works directly on this representation.

### Errors and results

The current List bootstrap uses opaque Error-tagged placeholders. Phase 5
replaces them with canonical `Error`, representing a violated language contract
or broken invariant with a root error kind plus a stack of propagation frames.

`Result` represents an expected success-or-failure outcome. Its error branch
contains an Error value but does not turn expected failure into a language
contract violation.

### Characters and strings

`Char` contains a binary Nat constrained to 0 through 255. `String` is a
List of Char values.

## Runtime typing

One generalized curried checker accepts a signature list and constructs strict
typed functions of arbitrary arity. It must:

- validate one argument per application;
- bubble an existing Error;
- create a structured Error for a wrong runtime type;
- preserve the function's remaining arity by returning unary absorbing
  continuations after an early error;
- support both raw-result and already-typed-result functions.

No arity-specific checker variants are allowed.

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
  bootstrap-errors.rkt
  lists.rkt
  # Later phases add the modules below.
  binary-nat.rkt
  errors.rkt
  typecheck.rkt
  typed-logic.rkt
  result.rkt
  chars.rkt
  strings.rkt
readers/
tests/
tooling/
run-all-tests.sh
```

Seven production modules currently exist under `core/`; the remaining core
paths are planned in dependency order. New abstraction layers require a
concrete need.

## Verification boundary

The test suite checks macro currying and hygiene, pair selection, every raw
Boolean truth-table row, and lazy non-evaluation of rejected pair fields and
`raw-if` branches. It also proves all 49 pairwise tag comparisons, every tag
and payload round trip, object/accessor currying, and accessor laziness. The
List suite covers NIL identity, proper tails, nested traversal, strict
failures, Error bubbling, laziness, and every implemented raw helper. The
structural purity tool scans production Racket sources for non-unary lambdas,
host-style function definitions, forbidden host computation, and host literal
data. It will be hardened further as later production forms arrive.

## Deferred boundary

This milestone contains no `host` form. A later milestone may introduce
exactly one explicit host boundary without weakening the purity of ordinary
language code.
