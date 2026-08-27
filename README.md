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
> green. The approved Phase 13
> [host-boundary design](docs/design/host-boundary.md) now has three implemented
> slices: Phase 14 adds exact String-byte conversion, one unary `host`, and
> pure injected-host `stdout`; Phase 15 adds pure `read-file`/`write-file`
> wrappers and byte-exact whole-file effects; Phase 16 adds pure blocking TCP
> wrappers, canonical Nat/host-integer conversion, and a private listener and
> connection registry inside that same closed host. A separate structural gate
> enforces the boundary. Pure HTTP messages are the next unstarted phase. See
> [PLAN.md](PLAN.md) for the completed core build and the
> effects-and-standalone roadmap, and
> [docs/ACCEPTANCE.md](docs/ACCEPTANCE.md) for criterion-by-criterion evidence.

## Commitments

- Every ordinary object-language function is a chain of one-argument lambdas.
- Core representations and algorithms contain no host-language data or
  computation; pure effect wrappers can invoke only an injected unary host.
- Racket is limited to modules, lazy evaluation, mechanical macros, readers,
  tests, tooling, deterministic boundary conversion in `runtime/codec.rkt`,
  and the one approved privileged bridge in `runtime/host.rkt`.
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
  `let`, `if`, and `cons`; today `if` is exported under its canonical name
  and the rest arrive with the standalone surface. Racket collision
  workarounds never become public language design.
- The completed core contains no `host` boundary. The effects milestone adds
  exactly one explicit bridge without weakening ordinary lambda computation.

## Specifications

The repository preserves the complete design inputs in
[docs/specifications](docs/specifications/README.md). The addenda take
precedence over conflicting examples in the base specification.

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) records the language boundary, planned
  layers, representations, and dependency direction.
- [docs/ACCEPTANCE.md](docs/ACCEPTANCE.md) maps the completed core and effects
  phases to executable or structural evidence.
- [docs/design/host-boundary.md](docs/design/host-boundary.md) fixes the
  approved second-milestone protocol, authority, codecs, and purity
  classifications; Phases 14 through 16 implement its `stdout`, file, and TCP
  slices.
- [PLAN.md](PLAN.md) divides both milestones into ordered, testable phases.
- [AGENTS.md](AGENTS.md) contains the project-specific implementation rules
  every contributor and coding agent must follow.

## Implemented foundation

- `macros/lazy-with-macros.rkt` provides the minimal Lazy Racket module shell.
- `macros/macros.rkt` provides arbitrary-arity curried `def` and the internal
  `lambda-let` sugar that will later be exported publicly as `let`. It also
  mechanically expands identifier spellings as UTF-8 bytes into pure String
  terms for Error frame names.
- `core/pair.rkt` provides lambda-encoded pairs and selectors.
- `core/logic.rkt` provides raw Boolean selectors and lambda-based Boolean
  operations, including lazy `raw-if`.
- `core/tags.rkt` provides Church tags 0 through 6 and pure tag equality.
- `core/objects.rkt` provides the raw tag/payload object constructor,
  selectors, and canonical-object type comparison.
- `core/fix.rkt` provides the pure fixed-point term used by recursive raw
  algorithms.
- `core/errors.rkt` provides structured Error roots and metadata, canonical
  root Errors, newest-first named propagation frames, result frames for
  failing algorithms, the raw List cell constructor, and the lazy
  `NIL`/empty-Error representation knot.
- `core/function-names.rkt` provides the canonical typed String constants used
  to identify strict operation boundaries without introducing host strings.
- `core/typecheck.rkt` provides the single generalized progressive checker,
  the shared one-argument validation step it and the polymorphic boundaries
  use, named signature-driven Error absorbers, and raw-result or
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
  constructors and variant-checked unwrap operations, and the explicit
  Error-as-data boundary.
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
- `effects/protocol.rkt` provides pure canonical operation/reason Strings,
  host Error constructors, request validation, and the injected-dispatcher
  builder for the sole host bridge.
- `effects/stdout.rkt` provides the pure typed request constructor and unary
  injected-host `stdout` wrapper.
- `effects/files.rkt` provides pure typed request constructors and curried
  injected-host `read-file` and `write-file` wrappers.
- `effects/tcp.rkt` provides pure typed request constructors and curried
  injected-host wrappers for blocking connect, listen, accept, read, write,
  and close.
- `runtime/codec.rkt` performs exact deterministic conversion between lambda
  Lists/Chars/Strings/Nats/Results and private host bytes, integers, and
  temporary collections, with no operating-system effects or mutation.
- `runtime/host.rkt` alone defines and exports `host`; its Phase 16 dispatcher
  accepts only the approved stdout, whole-file, and six blocking TCP requests,
  owns the private monotonic handle registry, normalizes external failures,
  and returns canonical Result/Error values without exposing ports or host
  collections.
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
- `readers/error.rkt` renders structured roots, result frames, and
  oldest-to-newest named frames without feeding diagnostic text back into
  computation.
- `tooling/check-purity.rkt` judges what Racket compiles: it expands every
  `core/*.rkt` production module exactly as `raco make` does and admits only
  the trusted Lazy Racket shell, project-only phase-0 imports, plain or renamed
  exports, single-identifier definitions, and terms alpha-equivalent to Lazy
  Racket's own expansion of a unary `lambda` and a unary application. Every
  remaining identifier must be lambda-bound, defined in the module, or
  imported from a project module that passes the same scan. The two `macros/`
  files and the Racket installation are its semantic trusted base.
- `tooling/check-boundaries.rkt` separately pins the two mechanical macro
  modules, admits only pure effect modules, deterministic codec conversion,
  the exact sole-host import/export path, and Phase 16's closed stdout,
  whole-file, and five-binding `racket/tcp` capability set. It rejects wrapped
  privileged imports, every second production filesystem/TCP importer,
  authorizes imports before reading their exports, validates every project-root
  and production-path component before discovery, rejects symlinks without
  traversing their targets, rejects additional macro modules, and rejects any
  premature `lang/` implementation.

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

Run only the production boundary-classification scan with:

```sh
racket tooling/check-boundaries.rkt
```

Each implementation phase adds focused tests and must leave the complete suite
green. The repository currently has 3,845 assertions across 26 test files,
plus the independent expanded scan of all 16 core modules and the production
boundary-classification gate. GitHub Actions runs the same suite for pushes
and pull requests.

Development happens directly on `main`. Commit and push after each meaningful
phase.

## License

No license has been selected yet.
