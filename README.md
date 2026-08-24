# Alone the Lambdas

Alone the Lambdas is a greenfield language project pursuing the most faithful
pure untyped lambda calculus that remains practical for real programs. It uses
Racket's lazy evaluator as a host while keeping object-language computation to
variables, unary lambdas, and application.

> **Status:** Phase 5 is complete. The repository now contains the raw lambda
> foundation, all seven Church type tags, generic typed objects, explicit
> Michaelson-style Lists, canonical binary Nat arithmetic, and structured
> Error roots with propagation frames. See [PLAN.md](PLAN.md) for the ordered
> build.

## Commitments

- Every object-language function is a chain of one-argument lambdas.
- Production representations and algorithms contain no host-language data or
  computation.
- Racket is limited to modules, lazy evaluation, mechanical macros, readers,
  tests, and tooling.
- Church numerals are used only for tiny fixed discriminants such as type
  tags, Error kinds, and argument positions—not ordinary numbers.
- Public natural numbers are normalized, most-significant-bit-first binary
  digit lists; zero is `[0]`.
- Lists use an explicit Michaelson-style tagged representation with a distinct
  `NIL`.
- Runtime typing is strict and centralized in one arbitrary-arity curried
  checker.
- Expected computational failure uses `Result`; contract violations and
  invariant failures use structured `Error` values.
- Public names are canonical language names such as `lambda`, `def`,
  `let`, `if`, and `cons`. Racket collision workarounds never become
  public language design.
- The `host` boundary is deliberately absent from this milestone.

## Specifications

The repository preserves the complete design inputs in
[docs/specifications](docs/specifications/README.md). The addenda take
precedence over conflicting examples in the base specification.

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) records the language boundary, planned
  layers, representations, and dependency direction.
- [PLAN.md](PLAN.md) divides the first milestone into ordered, testable phases.
- [AGENTS.md](AGENTS.md) contains the project-specific implementation rules
  every contributor and coding agent must follow.

## Implemented foundation

- `macros/lazy-with-macros.rkt` provides the minimal Lazy Racket module shell.
- `macros/macros.rkt` provides arbitrary-arity curried `def` and the internal
  `lambda-let` sugar that will later be exported publicly as `let`.
- `core/pair.rkt` provides lambda-encoded pairs and selectors.
- `core/logic.rkt` provides raw Boolean selectors and lambda-based Boolean
  operations, including lazy `raw-if`.
- `core/tags.rkt` provides Church tags 0 through 6 and pure tag equality.
- `core/objects.rkt` provides the raw tag/payload object constructor,
  selectors, and canonical-object type comparison.
- `core/fix.rkt` provides the pure fixed-point term used by recursive raw
  algorithms.
- `core/errors.rkt` provides structured Error roots and metadata, canonical
  root Errors, newest-first propagation frames, and the lazy `NIL`/empty-Error
  representation knot.
- `core/lists.rkt` provides canonical `NIL`, strict bootstrap List primitives,
  and raw fold, append, reverse, map, and filter operations.
- `core/binary-nat.rkt` provides normalized MSB-first Nat payloads, typed
  constants `ZERO` through `TEN`, and raw zero, successor, arithmetic, and
  comparison algorithms.
- `core/list-nat.rkt` provides raw List length, take, and drop algorithms plus
  their strict bootstrap operations using canonical Nat values.
- `readers/raw-boolean.rkt` observes raw Booleans for tests without entering
  the production dependency graph.
- `readers/type-tag.rkt` observes Church tags as host integers at the same
  one-way boundary.
- `readers/list.rkt` traverses completed Lists for human-facing observation.
- `readers/nat.rkt` observes completed Nat values as host bit lists or integers
  without entering production computation.
- `tooling/check-purity.rkt` rejects forbidden host computation, host data,
  and non-unary lambdas in production modules.

## Development

The host is Racket with the `lazy` package. Run the complete test and purity
suite with:

```sh
./run-all-tests.sh
```

Run only the production-source purity scan with:

```sh
racket tooling/check-purity.rkt
```

Each implementation phase adds focused tests and must leave the complete suite
green. GitHub Actions runs the same suite for pushes and pull requests.

Development happens directly on `main`. Commit and push after each meaningful
phase.

## License

No license has been selected yet.
