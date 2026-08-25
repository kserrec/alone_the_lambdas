# Plan

This plan implements the specification milestones in dependency order. Phases
0 through 12 complete the pure core. Phases 13 through 20 build the explicitly
deferred effects and standalone-language milestone. Each phase is one coherent
`$next` unit: implement every listed step, add focused tests, run the full
suite, update documentation, then commit and push `main`.

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

Status: complete (2026-08-24)

- [x] Implement binary digits and normalized most-significant-bit-first Nat
  representation.
- [x] Implement canonicalization with `[0]` as the only zero.
- [x] Implement the required raw comparisons and arithmetic directly on binary
  lists.
- [x] Complete List `LEN`, `TAKE`, and `DROP` with canonical binary Nat values.
- [x] Test zero, carries, borrows, normalization, and representative larger
  values.

Acceptance: public arithmetic never converts through Church numerals or host
numbers.

## Phase 5 — Structured Error

Status: complete (2026-08-24)

- [x] Implement the Error type, root kinds, and frame representation.
- [x] Implement creation, frame addition, and bubbling primitives.
- [x] Replace provisional bootstrap Error payloads with canonical structured
  roots.
- [x] Use canonical argument-position and expected-type metadata in frames.
- [x] Test root preservation and frame order through nested failures.

Acceptance: errors remain ordinary lambda-encoded values and accumulate
context without losing their root cause.

## Phase 6 — Generalized curried runtime checker

Status: complete (2026-08-24)

- [x] Represent arbitrary signatures as Lists.
- [x] Implement the single unary, progressive argument-checking mechanism.
- [x] Support raw-result and already-typed-result functions.
- [x] Preserve remaining arity after early failure with unary absorbing
  continuations.
- [x] Migrate bootstrap List checks onto the generalized checker where
  appropriate.
- [x] Test valid partial application, wrong types at every argument position,
  incoming Error bubbling, and final return validation.

Acceptance: no arity-specific checker exists, and every failure has the same
remaining application shape as the function it replaces.

## Phase 7 — Strict typed Bool and public `if`

Status: complete (2026-08-24)

- [x] Wrap raw Booleans as tagged Bool values.
- [x] Implement strict typed Boolean operations through the generalized
  checker.
- [x] Implement lazy public `if` with a typed Bool condition.
- [x] Test strict condition checking and non-evaluation of the unselected
  branch.

Acceptance: public `if` is canonical, typed, lazy, and distinct from internal
`raw-if`.

## Phase 8 — Strict typed Nat API

Status: complete (2026-08-24)

- [x] Route every public Nat operation through the generalized checker.
- [x] Keep raw binary algorithms isolated below the typed layer.
- [x] Attach canonical function frames to Nat errors.
- [x] Run raw arithmetic, typed behavior, and propagation tests together.

Acceptance: all public Nat operations enforce signatures uniformly without
changing binary semantics.

## Phase 9 — Result and safe division

Status: complete (2026-08-24)

- [x] Implement typed Result success and failure variants.
- [x] Define strict constructors and access operations.
- [x] Implement safe binary division with expected failure represented as
  Result Err.
- [x] Test the Error-versus-Result boundary and division laws.

Acceptance: expected division failure is data, while contract failure remains
a bubbled Error.

## Phase 10 — Char

Status: complete (2026-08-24)

- [x] Implement Char as a tagged binary Nat constrained to 0 through 255.
- [x] Add the required character constants and operations.
- [x] Add a human-facing Char reader outside production computation.
- [x] Test boundaries, invalid values, comparisons, and reader output.

Acceptance: Char validation is lambda-calculus computation; only presentation
uses host facilities.

## Phase 11 — String

Status: complete (2026-08-24)

- [x] Implement String as a typed List of Char values.
- [x] Implement construction and the specified initial String algorithms.
- [x] Return String length through the specified typed result.
- [x] Add a human-facing String reader and comprehensive List/Char interaction
  tests.

Acceptance: String algorithms operate on lambda-encoded List and Char values,
not host strings.

## Phase 12 — Error frames, documentation, and purity hardening

Status: complete (2026-08-24)

- [x] Complete canonical String-related function names in Error frames.
- [x] Add the Error reader and finish reader diagnostics.
- [x] Run repository-wide forbidden-form and unary-lambda validation.
- [x] Complete specification acceptance tests and synchronize all
  documentation with the implementation.

Acceptance: every completion criterion in the three specifications is covered
by an executable test or a documented structural check, and the full suite is
green.

# Milestone 2 — Effects and standalone language

Status: planned

The specifications fix the order and outer boundary of this milestone but do
not define the `host` request protocol. Phase 13 therefore resolves that
contract before any privileged implementation begins. It is an explicit
approval gate: Phase 14 must not start until the resulting design is approved.

The following constraints apply throughout:

- `host` is the only privileged bridge between lambda values and Racket or the
  operating system. It is unary, explicit, and closed over a documented
  request protocol.
- The 16 completed `core/` modules retain their zero-exception purity rule.
  Adding `host` must not permit any other host shortcut in ordinary language
  computation.
- Requests, successful values, and failures cross the boundary through
  lambda-encoded project values. Expected external failure uses Result Err;
  contract or representation failure remains Error.
- Effect wrappers and HTTP behavior are ordinary lambda computations except
  for their explicit applications of `host`. Raw Racket ports, paths, socket
  objects, exceptions, and collections never become object-language values.
- The initial runtime is synchronous and blocking. Concurrency, async, TLS,
  a general HTTP framework, JSON, records, static or coercive typing,
  optimization, compilation, and arbitrary Racket interop remain out of
  scope.

## Phase 13 — Host contract and trust boundary

- [ ] Write `docs/design/host-boundary.md` with the exact request and response
  algebra for `stdout`, file access, and the complete blocking TCP lifecycle.
- [ ] Fix the lambda encodings for operation identity, argument Lists, typed
  acknowledgements, expected I/O failures, and opaque resource handles.
- [ ] Define handle ownership and cleanup, blocking behavior, path and byte
  semantics, and the authority granted to a running program.
- [ ] Define the dependency split between pure `effects/`, the single trusted
  `runtime/` bridge, and the future `lang/` surface, including deterministic
  fake-host testing.
- [ ] Specify the purity-checker classifications and the narrow project-rule
  changes that become valid only after this design is approved.
- [ ] Record which Lazy Racket and macro-shell patterns remain reusable from
  `all_the_lambdas`; do not import its underscore names, coercive layers, or
  superseded representations.

Acceptance: every later phase can implement against one unambiguous protocol;
no production interop code exists yet; the design is presented for explicit
approval before Phase 14.

## Phase 14 — Single `host` bridge and `stdout`

- [ ] Apply the approved rule and architecture changes without weakening the
  completed core boundary.
- [ ] Implement one unary `host` binding and one closed dispatcher inside the
  designated trusted runtime module.
- [ ] Implement the pure `stdout` request constructor and wrapper, with typed
  success and expected-failure results.
- [ ] Add a deterministic fake dispatcher plus real output-capture tests for
  request validation, result encoding, failure mapping, and laziness.
- [ ] Make the purity tool reject privileged definitions and Racket effects
  everywhere except the one trusted bridge, while scanning `core/` with no
  new exceptions.

Acceptance: a lambda String reaches standard output only through the single
bridge, and repository checks prove no second escape hatch exists.

## Phase 15 — File effects

- [ ] Add pure `read-file` and `write-file` wrappers over the approved request
  protocol.
- [ ] Encode file contents as String byte values using Char 0 through 255; do
  not route language computation through the existing human-facing readers.
- [ ] Map missing paths, denied access, invalid byte data, and other expected
  operating-system failures to the approved Result Err representation.
- [ ] Test round trips, empty and non-ASCII byte content, replacement
  semantics, cleanup, contract Errors, and fake-host request structure in
  isolated temporary directories.

Acceptance: a lambda program can write and recover identical byte content,
and all filesystem access is confined to the trusted dispatcher.

## Phase 16 — Blocking TCP effects

- [ ] Add the approved connect, listen, accept, read, write, and close host
  operations and their pure lambda wrappers.
- [ ] Keep ports and connections in a runtime-owned handle registry; expose
  only the approved lambda-encoded opaque handles.
- [ ] Make close behavior and failure cleanup deterministic, including stale
  handles, peer closure, partial writes, and read bounds.
- [ ] Add fake-host protocol tests and real loopback integration tests with
  test-only host concurrency where needed.

Acceptance: a loopback client and server exchange lambda String bytes and
release every resource, with no socket or host collection crossing into the
object language.

## Phase 17 — Pure HTTP messages

- [ ] Implement only the String and List helpers demonstrably required for a
  minimal HTTP/1.1 request and response path.
- [ ] Parse a request line and header terminator into existing lambda values;
  reject malformed or unsupported input through Result rather than host
  exceptions.
- [ ] Build status lines, required response headers, byte-accurate content
  length, and response bodies entirely in lambda computation.
- [ ] Cover fragmented input, CRLF boundaries, empty bodies, malformed
  requests, and deterministic response formatting with pure focused tests.

Acceptance: representative HTTP bytes parse and render correctly while the
production purity scan rejects Racket String, regex, arithmetic, and HTTP
helpers from the implementation.

## Phase 18 — Minimal lambda-built HTTP server

- [ ] Compose the TCP wrappers and pure HTTP message layer into a blocking,
  sequential server with an ordinary lambda request handler.
- [ ] Support the minimal useful subset: one request per connection, GET
  routing by path, explicit status/body output, and connection close.
- [ ] Preserve expected network and parse failures as Result values and close
  acquired handles on every completed path.
- [ ] Add a real loopback acceptance test driven by a test-side external HTTP
  client, plus deterministic fake-host traces proving the only effects are the
  documented TCP requests.

Acceptance: an external client receives the response selected by a lambda
handler, and neither parsing, routing, nor response construction uses host
computation.

## Phase 19 — Standalone `#lang` surface

- [ ] Add the minimal Racket collection, reader, and expander needed for
  `#lang alone_the_lambdas` while retaining Lisp syntax and lazy evaluation.
- [ ] Export canonical `lambda`, `def`, `let`, strict typed `if`, proper typed
  `cons`, the completed data API, effect wrappers, and the single explicit
  `host`; hide internal raw bindings and Racket collision workarounds.
- [ ] Mechanically lower only nonnegative Nat literals and byte-range String
  literals into the existing pure representations; reject unsupported datum
  forms during expansion and add no general parser.
- [ ] Add package metadata and fresh-install tests for canonical names,
  currying, branch laziness, literals, module isolation, and runnable programs.

Acceptance: the specification's canonical sample shape runs under
`#lang alone_the_lambdas` with no underscore names or unintended Racket
bindings, and all literal runtime values are ordinary lambda encodings.

## Phase 20 — Runnable applications and milestone acceptance

- [ ] Add terse standalone examples for stdout, a file round trip, and the
  minimal HTTP server; every example must run from a fresh repository setup.
- [ ] Extend structural checks across pure core, effect wrappers, trusted
  runtime, macros, language surface, readers, tests, and tooling with the
  correct rule for each classification.
- [ ] Add end-to-end acceptance coverage for every second-milestone claim,
  including proof that only the one trusted bridge performs effects.
- [ ] Synchronize README, architecture, project rules, setup instructions, and
  acceptance documentation with observed behavior and remaining limits.

Acceptance: a new developer can install the language, run ordinary standalone
programs, perform the four specified effect families, and serve the minimal
HTTP response; the full suite and CI are green and the one-bridge claim has an
explicit evidence map.
