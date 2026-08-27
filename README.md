# Alone the Lambdas

Alone the Lambdas is a greenfield language project pursuing the most faithful
pure untyped lambda calculus that remains practical for real programs. It uses
Racket's lazy evaluator as a host while keeping object-language computation to
variables, unary lambdas, and application.

> **Status:** The first core-language milestone is complete. Its lambda-only
> foundation now includes all seven tagged data types, explicit Lists,
> scalable binary Nat arithmetic, strict Bool and Nat operations, Result,
> Char, String, and one generalized curried runtime checker. Structured Errors
> preserve their root cause and accumulate canonical function-name Strings in
> propagation frames; a one-way reader renders those frames as human-facing
> diagnostics. The full acceptance suite and structural purity gate are
> green. The Phase 13
> [host-boundary design](docs/design/host-boundary.md) was approved on
> 2026-08-27; Phase 14 is unblocked, but no production host implementation
> exists. See
> [PLAN.md](PLAN.md) for the completed core build and the
> effects-and-standalone roadmap, and
> [docs/ACCEPTANCE.md](docs/ACCEPTANCE.md) for criterion-by-criterion evidence.

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
- The completed core contains no `host` boundary. The next milestone adds
  exactly one explicit bridge without weakening ordinary lambda computation.

## Specifications

The repository preserves the complete design inputs in
[docs/specifications](docs/specifications/README.md). The addenda take
precedence over conflicting examples in the base specification.

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) records the language boundary, planned
  layers, representations, and dependency direction.
- [docs/ACCEPTANCE.md](docs/ACCEPTANCE.md) maps every first-milestone
  completion criterion to executable or structural evidence.
- [docs/design/host-boundary.md](docs/design/host-boundary.md) fixes the
  approved second-milestone protocol, authority, codecs, and purity
  classifications; Phase 14 implementation has not started.
- [PLAN.md](PLAN.md) divides both milestones into ordered, testable phases.
- [AGENTS.md](AGENTS.md) contains the project-specific implementation rules
  every contributor and coding agent must follow.

## Implemented foundation

- `macros/lazy-with-macros.rkt` provides the minimal Lazy Racket module shell.
- `macros/macros.rkt` provides arbitrary-arity curried `def` and the internal
  `lambda-let` sugar that will later be exported publicly as `let`. It also
  mechanically expands identifier spellings into pure String terms for Error
  frame names.
- `core/pair.rkt` provides lambda-encoded pairs and selectors.
- `core/logic.rkt` provides raw Boolean selectors and lambda-based Boolean
  operations, including lazy `raw-if`.
- `core/tags.rkt` provides Church tags 0 through 6 and pure tag equality.
- `core/objects.rkt` provides the raw tag/payload object constructor,
  selectors, and canonical-object type comparison.
- `core/fix.rkt` provides the pure fixed-point term used by recursive raw
  algorithms.
- `core/errors.rkt` provides structured Error roots and metadata, canonical
  root Errors, newest-first named propagation frames, and the lazy
  `NIL`/empty-Error representation knot.
- `core/function-names.rkt` provides the canonical typed String constants used
  to identify strict operation boundaries without introducing host strings.
- `core/typecheck.rkt` provides the single generalized progressive checker,
  named signature-driven Error absorbers, and raw-result or
  already-typed-result finalizers.
- `core/typed-logic.rkt` provides tagged `TRUE` and `FALSE`, checker-backed
  strict Boolean operations, and the polymorphic lazy `typed-if` with its
  canonical `if` export.
- `core/lists.rkt` provides canonical `NIL`, the proper polymorphic `typed-cons`
  constructor, checker-backed typed access operations, and raw fold, append,
  reverse, map, and filter operations.
- `core/binary-nat.rkt` provides normalized MSB-first Nat payloads, typed
  constants `ZERO` through `TEN`, and raw zero, successor, arithmetic, and
  comparison algorithms, including binary long division.
- `core/result.rkt` provides lambda-encoded Ok and Err variants, strict
  constructors and access operations, and the explicit Error-as-data boundary.
- `core/chars.rkt` provides strict `MAKE-CHAR` and comparisons, normalized
  binary payloads limited to 0 through 255, and the required lambda-built
  character constants.
- `core/typed-nat.rkt` provides the checker-backed strict Nat API, including
  canonical `SUCC`, `ADD`, `SUB`, `MULT`, `DIV`, `EQ`, `LT`, `LTE`, `GT`,
  `GTE`, and `IS-ZERO` exports. `DIV` returns Result.
- `core/list-nat.rkt` provides raw List length, take, and drop algorithms plus
  checker-backed strict operations using canonical Nat values.
- `core/strings.rkt` provides the strict `MAKE-STRING` invariant boundary,
  `EMPTY-STRING`, and the complete initial String operation set over lambda
  Lists and Chars.
- `readers/raw-boolean.rkt` observes raw Booleans for tests without entering
  the production dependency graph.
- `readers/bool.rkt` observes tagged Bool values at the same one-way boundary.
- `readers/type-tag.rkt` observes Church tags as host integers at the same
  one-way boundary.
- `readers/list.rkt` traverses completed Lists for human-facing observation.
- `readers/nat.rkt` observes completed Nat values as host bit lists or integers
  without entering production computation.
- `readers/char.rkt` renders supported ASCII Char values and deterministic
  numeric fallbacks at the same one-way boundary.
- `readers/string.rkt` renders a completed lambda String to a host string at
  the same one-way boundary.
- `readers/error.rkt` renders structured roots and oldest-to-newest named
  frames without feeding diagnostic text back into computation.
- `tooling/check-purity.rkt` admits only the trusted Lazy Racket shell,
  project-only imports with validated selection or renaming, mechanical sugar,
  variables, unary lambdas, and unary application. It also verifies that every
  production identifier and export comes from a local binding or a recursively
  validated project export.

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
green. The completed milestone currently has 2,914 assertions across 18 test
files, plus the independent scan of all 16 production modules. GitHub Actions
runs the same suite for pushes and pull requests.

Development happens directly on `main`. Commit and push after each meaningful
phase.

## License

No license has been selected yet.
