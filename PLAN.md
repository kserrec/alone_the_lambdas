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

Status: implementation in progress; Phase 18 complete

The specifications fix the order and outer boundary of this milestone but do
not define the `host` request protocol. Phase 13 therefore resolves that
contract before any privileged implementation begins. It is an explicit
approval gate: Phase 14 must not start until the resulting design is approved.
Kyle approved the high-level use of the single `host` boundary in Alone the
Lambdas and the detailed request, codec, authority, and runtime contract on
2026-08-27. The gate is satisfied; Phases 14 through 18 are complete and Phase
19 is the next unfinished phase.

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

Status: complete and approved (revised and approved 2026-08-27)

- [x] Write `docs/design/host-boundary.md` with the exact request and response
  algebra for `stdout`, file access, and the complete blocking TCP lifecycle.
- [x] Fix the lambda encodings for operation identity, argument Lists, typed
  acknowledgements, expected I/O failures, and opaque resource handles.
- [x] Define handle ownership and cleanup, blocking behavior, path and byte
  semantics, and the authority granted to a running program.
- [x] Define the dependency split between pure `effects/`, the sole exported
  `runtime/host.rkt` bridge, its separately classified `runtime/codec.rkt`,
  and the future `lang/` surface, including deterministic fake-host testing.
- [x] Isolate exact object-language-to-Racket and Racket-to-object-language
  conversion from effects; define canonicality, codec prohibitions, dependency
  enforcement, and direct round-trip coverage.
- [x] Specify the purity-checker classifications and the narrow project-rule
  changes that become valid only after this design is approved.
- [x] Record which Lazy Racket and macro-shell patterns remain reusable from
  `all_the_lambdas`; do not import its underscore names, coercive layers, or
  superseded representations.

Acceptance: every later phase can implement against one unambiguous protocol;
no production interop code exists yet; the design received explicit approval
before Phase 14.

High-level `host` direction and detailed contract: approved 2026-08-27. The
approval is recorded in
[docs/design/host-boundary.md](docs/design/host-boundary.md).

## Phase 14 — Single `host` bridge and `stdout`

Status: complete (2026-08-27)

- [x] Apply the approved rule and architecture changes without weakening the
  completed core boundary.
- [x] Implement `runtime/codec.rkt` with only the exact Char/String/List and
  Result/Error conversions required by stdout; prove byte round trips,
  canonical output, malformed-value rejection, and absence of effects.
- [x] Implement one unary `host` binding and one closed dispatcher in
  `runtime/host.rkt`, the only production importer of the codec and the only
  language-visible privileged binding.
- [x] Implement the pure `stdout` request constructor and wrapper, with typed
  success and expected-failure results.
- [x] Add a deterministic fake dispatcher plus real output-capture tests for
  request validation, result encoding, failure mapping, and laziness.
- [x] Make the purity tool enforce the distinct codec and effect-module
  allowlists, reject every unapproved importer or privileged definition, and
  scan `core/` with no new exceptions.

Acceptance: a lambda String reaches standard output only through the single
bridge, and repository checks prove no second escape hatch exists.

Completion evidence: 3,151 assertions across 22 test files, the unchanged
purity scan over 16 `core/` modules, and the separate effects/runtime boundary
gate all passed on 2026-08-27.

## Phase 15 — File effects

Status: complete (2026-08-27)

- [x] Add pure `read-file` and `write-file` wrappers over the approved request
  protocol.
- [x] Encode file contents as String byte values using Char 0 through 255; do
  not route language computation through the existing human-facing readers.
- [x] Map missing paths, denied access, invalid path text, and other expected
  operating-system failures to the approved Result Err representation.
- [x] Reuse the verified byte-exact String codec without importing the
  human-facing readers; keep UTF-8 path interpretation in the host operation.
- [x] Test round trips, empty and non-ASCII byte content, replacement
  semantics, cleanup, contract Errors, and fake-host request structure in
  isolated temporary directories.

Acceptance: a lambda program can write and recover identical byte content,
and all filesystem access is confined to the trusted dispatcher.

Completion evidence: 3,307 assertions across 24 test files, the unchanged
purity scan over 16 `core/` modules, and the Phase 15 effects/runtime boundary
gate all passed on 2026-08-27.

Post-completion audit hardening (2026-08-27): function-name macros now lower
identifier spellings to one Char per UTF-8 byte; the boundary gate pins both
mechanical macro modules, rejects wrapped second codec/host imports, rejects
disallowed imports before reading their exports, validates every component of
the project root and production paths before discovery, rejects symlinks
without traversing their targets, rejects additional macro modules and all
premature `lang/` modules, and keeps macro OS/process/environment/dynamic-
loading/FFI/mutation capabilities closed. CI
actions, runner family, and Racket are pinned, and CI verifies the bundled
`lazy` package without live package resolution. The resulting 3,345 assertions
across 24 test files, unchanged 16-module expanded core scan, and strengthened
boundary scan all passed. Phase 15 behavior and the approved host authority are
unchanged.

## Phase 16 — Blocking TCP effects

Status: complete (2026-08-27)

- [x] Add the approved connect, listen, accept, read, write, and close host
  operations and their pure lambda wrappers.
- [x] Extend `runtime/codec.rkt` only with canonical Nat/integer conversions
  and returned List shapes required for port bounds and opaque handles.
- [x] Keep ports and connections in a runtime-owned handle registry; expose
  only the approved lambda-encoded opaque handles.
- [x] Make close behavior and failure cleanup deterministic, including stale
  handles, peer closure, partial writes, and read bounds.
- [x] Add fake-host protocol tests and real loopback integration tests with
  test-only host concurrency where needed.

Acceptance: a loopback client and server exchange lambda String bytes and
release every resource, with no socket or host collection crossing into the
object language.

Completion evidence: 3,845 assertions across 26 test files, the unchanged
expanded purity scan over 16 `core/` modules, and the Phase 16 boundary gate
all passed on 2026-08-27. The TCP tests use only loopback and ephemeral ports;
they cover canonical Nat conversion, pure request traces and contracts,
blocking and bounded reads, complete byte writes, full-duplex transfer, EOF,
wrong/stale handles, monotonic nonreuse, deterministic failure codes, Racket
custodian closure, and explicit cleanup. The boundary gate admits exactly the
host's five imported `racket/tcp` bindings and rejects every second production
filesystem or TCP importer.

## Phase 17 — Pure HTTP messages

Status: complete (2026-08-27)

- [x] Implement only the String and List helpers demonstrably required for a
  minimal HTTP/1.1 request and response path.
- [x] Parse a request line and header terminator into existing lambda values;
  reject malformed or unsupported input through Result rather than host
  exceptions.
- [x] Build status lines, required response headers, byte-accurate content
  length, and response bodies entirely in lambda computation.
- [x] Cover fragmented input, CRLF boundaries, empty bodies, malformed
  requests, and deterministic response formatting with pure focused tests.

Acceptance: representative HTTP bytes parse and render correctly while the
production purity scan rejects Racket String, regex, arithmetic, and HTTP
helpers from the implementation.

Completion evidence: 3,995 assertions across 27 test files, the unchanged
expanded purity scan over all 16 `core/` modules, and the Phase 17 boundary
gate passed on 2026-08-27. `effects/http.rkt` parses the deliberately small
HTTP/1.1 subset into an Ok target String: exact `GET`, an origin-form target,
exact `HTTP/1.1`, CRLF-delimited field lines, exactly one case-insensitive
`Host` field, one header section, and no body or pipelined bytes. Incomplete,
malformed, and unsupported requests are distinct Result Err values.
`effects/http-response.rkt` separately renders only 200, 400, 404, and 500
responses with canonical
reason phrases, decimal byte-accurate `Content-Length`, `Connection: close`,
the empty header terminator, and the exact body bytes; an unsupported status
is its own Result Err. The 146 focused assertions cover fragmented terminator
boundaries, valid and invalid header names/values, binary and empty bodies,
single- and multi-digit lengths, deterministic output, strict contracts,
Error bubbling, and remaining-arity absorption. Boundary regressions reject
host String, regex, arithmetic, and `net/http-client` shortcuts from every
pure effect module.

## Phase 18 — Minimal lambda-built HTTP server

Status: complete (2026-08-27)

- [x] Compose the TCP wrappers and pure HTTP message layer into a blocking,
  sequential server with an ordinary lambda request handler.
- [x] Support the minimal useful subset: one request per connection, GET
  routing by path, explicit status/body output, and connection close.
- [x] Preserve expected network and parse failures as Result values and close
  acquired handles on every completed path.
- [x] Add a real loopback acceptance test driven by a test-side external HTTP
  client, plus deterministic fake-host traces proving the only effects are the
  documented TCP requests.

Acceptance: an external client receives the response selected by a lambda
handler, and neither parsing, routing, nor response construction uses host
computation.

Completion evidence: 4,136 assertions across 28 test files, the unchanged
expanded purity scan over all 16 `core/` modules, and the Phase 18 boundary
gate passed on 2026-08-27. `effects/http-server.rkt` adds a strict pure
single-path handler factory, a one-connection operation over a caller-owned
listener, and a blocking sequential loop. The handler maps the parsed target
String to a Result containing complete response bytes; route comparison,
status/body selection, and rendering remain lambda computation. Every
accepted connection is closed after success, parse failure, EOF, handler
failure, or network failure; an earlier failure remains primary if cleanup
also fails. The 141 focused assertions cover unary partial application,
strict contracts, selected-branch laziness, fragmented reads, malformed and
incomplete requests, accept/read/write/close failures, handler Errors and
invalid results, force-once serving, exact TCP-only traces, two serial
connections, and a real ephemeral-loopback request from test-side
`net/http-client`. Listener ownership remains explicit: the caller that
obtains a listener through `tcp-listen` closes it after serving.

## Phase 19 — Standalone `#lang` surface

- [ ] Add the minimal Racket collection, reader, and expander needed for
  `#lang alone_the_lambdas` while retaining Lisp syntax and lazy evaluation.
- [ ] Export canonical `lambda`, `def`, `let`, strict typed `if`, proper typed
  `cons`, the completed data API, effect wrappers, and the single explicit
  `host`; hide internal raw bindings and Racket collision workarounds.
- [ ] Mechanically lower only nonnegative Nat literals and UTF-8 String
  literals into the existing pure representations, with one Char per encoded
  byte; reject unsupported datum forms during expansion and add no general
  parser.
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
