# Architecture

This document records the target architecture. The repository currently
contains specifications and planning only; implementation paths below are
planned, not yet present.

## Computational boundary

The object language is pure untyped lambda calculus:

1. variables;
2. exactly unary `lambda`;
3. application.

Every production value and algorithm must reduce to those forms after
mechanical macro expansion. Multi-argument functions are nested unary lambdas,
and partial application is ordinary application.

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

Lists use an explicit Michaelson-style representation. `NIL` is a List value,
not false and not numeric zero. Every nonempty cell has a head and a tail whose
runtime type is List.

### Natural numbers

Public Nat values are normalized binary digit lists in most-significant-bit
first order. Zero has exactly one representation, `[0]`; positive values have
no leading zeroes. Raw arithmetic works directly on this representation.

### Errors and results

`Error` represents a violated language contract or broken invariant. It
contains a root error kind plus a stack of frames added while the error
bubbles.

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

## Planned repository layout

```text
macros/
  lazy-with-macros.rkt
  macros.rkt
core/
  pair.rkt
  logic.rkt
  tags.rkt
  objects.rkt
  lists.rkt
  binary-nat.rkt
  errors.rkt
  typecheck.rkt
  typed-logic.rkt
  result.rkt
  chars.rkt
  strings.rkt
readers/
tests/
run-all-tests.sh
```

The exact paths may become simpler if the dependency graph proves a better
layout. New abstraction layers require a concrete need.

## Deferred boundary

This milestone contains no `host` form. A later milestone may introduce
exactly one explicit host boundary without weakening the purity of ordinary
language code.
