# Alone the Lambdas

Alone the Lambdas is a greenfield language project pursuing the most faithful
pure untyped lambda calculus that remains practical for real programs. It uses
Racket's lazy evaluator as a host while keeping object-language computation to
variables, unary lambdas, and application.

> **Status:** Phase 1 is complete. The repository now contains the lazy module
> shell, mechanical unary-lambda syntax, lambda pairs, and raw Boolean logic.
> See [PLAN.md](PLAN.md) for the ordered build.

## Commitments

- Every object-language function is a chain of one-argument lambdas.
- Production representations and algorithms contain no host-language data or
  computation.
- Racket is limited to modules, lazy evaluation, mechanical macros, readers,
  tests, and tooling.
- Church numerals are used only for the small closed set of type tags.
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
- `readers/raw-boolean.rkt` observes raw Booleans for tests without entering
  the production dependency graph.
- `tooling/check-purity.rkt` performs the initial structural purity scan over
  production modules.

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
