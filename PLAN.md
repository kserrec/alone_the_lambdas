# Plan

This plan implements the first specification milestone in dependency order.
Each phase is one coherent unit: implement every listed step, add focused
tests, run the full suite, update documentation, then commit and push `main`.

The three files under [docs/specifications](docs/specifications/README.md) are
the authority. The purity addendum overrides weaker purity examples, and the
naming addendum overrides earlier naming examples.

## Phase 0 — Repository foundation

Status: complete (2026-08-24)

- [x] Preserve the three source specifications verbatim.
- [x] Record the language boundary and planned dependency layers.
- [x] Establish project-specific implementation rules.
- [x] Add minimal editor, line-ending, and ignore policy.
- [x] Define the ordered implementation phases.

## Phase 1 — Raw calculus and mechanical syntax

Status: complete (2026-08-24)

- [x] Add the lazy Racket module shell and expansion-only macro layer.
- [x] Implement `def` and lambda-based `let` as nested unary-lambda sugar.
- [x] Implement lambda pairs and raw Boolean operations, including internal
  `raw-if`.
- [x] Add focused pair and Boolean tests plus the first purity checks.

Acceptance: macro expansion preserves unary lambdas; pair selection and every
Boolean truth table pass without host conditionals deciding results.

## Phase 2 — Church tags and typed objects

Status: complete (2026-08-24)

- [x] Implement Church numerals only for tags 0 through 6.
- [x] Implement the generic lambda-encoded tag/payload object representation.
- [x] Add raw tag equality and object access operations.
- [x] Test every tag, payload round trip, and purity invariant.

Acceptance: all seven discriminants are distinct and typed objects contain no
host data.

## Phase 3 — Michaelson-style List

Status: complete (2026-08-24)

- [x] Implement typed `NIL` and nonempty List cells.
- [x] Implement raw list structure and strict typed `cons`, head, tail, and
  nil predicate operations.
- [x] Add the Nat-independent foundational folds and list helpers required by
  later phases.
- [x] Test proper-tail enforcement, NIL distinction, traversal, and errors.

Acceptance: every public List is properly typed and every tail is a List.

## Phase 4 — Binary Nat

- [ ] Implement binary digits and normalized most-significant-bit-first Nat
  representation.
- [ ] Implement canonicalization with `[0]` as the only zero.
- [ ] Implement the required raw comparisons and arithmetic directly on binary
  lists.
- [ ] Complete List `LEN`, `TAKE`, and `DROP` with canonical binary Nat values.
- [ ] Test zero, carries, borrows, normalization, and representative larger
  values.

Acceptance: public arithmetic never converts through Church numerals or host
numbers.

## Phase 5 — Structured Error

- [ ] Implement the Error type, root kinds, and frame representation.
- [ ] Implement creation, frame addition, and bubbling primitives.
- [ ] Replace provisional bootstrap Error payloads with canonical structured
  roots.
- [ ] Establish canonical function-name values used in frames.
- [ ] Test root preservation and frame order through nested failures.

Acceptance: errors remain ordinary lambda-encoded values and accumulate
context without losing their root cause.

## Phase 6 — Generalized curried runtime checker

- [ ] Represent arbitrary signatures as Lists.
- [ ] Implement the single unary, progressive argument-checking mechanism.
- [ ] Support raw-result and already-typed-result functions.
- [ ] Preserve remaining arity after early failure with unary absorbing
  continuations.
- [ ] Migrate bootstrap List checks onto the generalized checker where
  appropriate.
- [ ] Test valid partial application, wrong types at every argument position,
  incoming Error bubbling, and final return validation.

Acceptance: no arity-specific checker exists, and every failure has the same
remaining application shape as the function it replaces.

## Phase 7 — Strict typed Bool and public `if`

- [ ] Wrap raw Booleans as tagged Bool values.
- [ ] Implement strict typed Boolean operations through the generalized
  checker.
- [ ] Implement lazy public `if` with a typed Bool condition.
- [ ] Test strict condition checking and non-evaluation of the unselected
  branch.

Acceptance: public `if` is canonical, typed, lazy, and distinct from internal
`raw-if`.

## Phase 8 — Strict typed Nat API

- [ ] Route every public Nat operation through the generalized checker.
- [ ] Keep raw binary algorithms isolated below the typed layer.
- [ ] Attach canonical function frames to Nat errors.
- [ ] Run raw arithmetic, typed behavior, and propagation tests together.

Acceptance: all public Nat operations enforce signatures uniformly without
changing binary semantics.

## Phase 9 — Result and safe division

- [ ] Implement typed Result success and failure variants.
- [ ] Define strict constructors and access operations.
- [ ] Implement safe binary division with expected failure represented as
  Result Err.
- [ ] Test the Error-versus-Result boundary and division laws.

Acceptance: expected division failure is data, while contract failure remains
a bubbled Error.

## Phase 10 — Char

- [ ] Implement Char as a tagged binary Nat constrained to 0 through 255.
- [ ] Add the required character constants and operations.
- [ ] Add a human-facing Char reader outside production computation.
- [ ] Test boundaries, invalid values, comparisons, and reader output.

Acceptance: Char validation is lambda-calculus computation; only presentation
uses host facilities.

## Phase 11 — String

- [ ] Implement String as a typed List of Char values.
- [ ] Implement construction and the specified initial String algorithms.
- [ ] Return String length through the specified typed result.
- [ ] Add a human-facing String reader and comprehensive List/Char interaction
  tests.

Acceptance: String algorithms operate on lambda-encoded List and Char values,
not host strings.

## Phase 12 — Error frames, documentation, and purity hardening

- [ ] Complete canonical String-related function names in Error frames.
- [ ] Add the Error reader and finish reader diagnostics.
- [ ] Run repository-wide forbidden-form and unary-lambda validation.
- [ ] Complete specification acceptance tests and synchronize all
  documentation with the implementation.

Acceptance: every completion criterion in the three specifications is covered
by an executable test or a documented structural check, and the full suite is
green.

## Deferred milestone

After this plan is complete, design the standalone public language surface and
the single explicit `host` boundary described by the specifications. Neither
belongs in the current milestone.
