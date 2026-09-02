# Plan

This plan implements the specification milestones in dependency order. Phases
0 through 12 complete the pure core. Phases 13 through 20 build the explicitly
deferred effects and standalone-language milestone. Completed Phases 0 through
30 use one Phase as one coherent `$next` unit. Milestone 4 is intentionally
larger: each explicitly numbered Step is one coherent `$next` unit, and each
Phase groups related Steps. Every `$next` unit implements all of its listed
work, adds focused tests, runs the full suite, updates relevant documentation,
then commits and pushes `main`.

The three files under [docs/specifications](docs/specifications/README.md) are
the authority. The purity addendum overrides weaker purity examples, and the
naming addendum overrides earlier naming examples.

Completed phase records preserve the literal public spellings and artifact
names that were true when their evidence was collected. Phase 27 supersedes
those spellings for current work without rewriting history.

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

Status: complete (2026-08-27)

The specifications fix the order and outer boundary of this milestone but do
not define the `host` request protocol. Phase 13 therefore resolves that
contract before any privileged implementation begins. It is an explicit
approval gate: Phase 14 must not start until the resulting design is approved.
Kyle approved the high-level use of the single `host` boundary in Alone the
Lambdas and the detailed request, codec, authority, and runtime contract on
2026-08-27. The gate is satisfied; Phases 14 through 20 and the complete
effects-and-standalone milestone are complete.

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

Status: complete (2026-08-27)

- [x] Add the minimal Racket collection, reader, and expander needed for
  `#lang alone_the_lambdas` while retaining Lisp syntax and lazy evaluation.
- [x] Export canonical `lambda`, `def`, `let`, strict typed `if`, proper typed
  `cons`, the completed data API, effect wrappers, and the single explicit
  `host`; hide internal raw bindings and Racket collision workarounds.
- [x] Mechanically lower only nonnegative Nat literals and UTF-8 String
  literals into the existing pure representations, with one Char per encoded
  byte; reject unsupported datum forms during expansion and add no general
  parser.
- [x] Add package metadata and fresh-install tests for canonical names,
  currying, branch laziness, literals, module isolation, and runnable programs.

Acceptance: the specification's canonical sample shape runs under
`#lang alone_the_lambdas` with no underscore names or unintended Racket
bindings, and all literal runtime values are ordinary lambda encodings.

Completion evidence: 4,224 assertions across 29 test files, the unchanged
expanded purity scan over all 16 `core/` modules, and the Phase 19 boundary
gate passed on 2026-08-27. `info.rkt`, `lang/reader.rkt`, and
`lang/expander.rkt` form a fresh-installable single collection. The facade
exports only the canonical syntax, strict typed data API, host-bound public
effect wrappers, documented pure HTTP operations, and one explicit `host`;
multi-operand source calls lower to nested unary applications, while public
`lambda` itself accepts exactly one argument. The 75 focused language
assertions install a copy into an isolated Racket user home and prove the
canonical sample, currying, lazy branch selection, exact UTF-8 output,
canonical literal representation, unsupported-datum rejection, and absence
of raw, typed, underscore, and Racket bindings. The boundary suite separately
pins the reader, package metadata, exact expander imports/exports, fixed
one-time host injections, source vocabulary, and sole authorized facade
import/export of `host`.

## Phase 20 — Runnable applications and milestone acceptance

- [x] Add terse standalone examples for stdout, a file round trip, and the
  minimal HTTP server; every example must run from a fresh repository setup.
- [x] Extend structural checks across pure core, effect wrappers, trusted
  runtime, macros, language surface, readers, tests, and tooling with the
  correct rule for each classification.
- [x] Add end-to-end acceptance coverage for every second-milestone claim,
  including proof that only the one trusted bridge performs effects.
- [x] Synchronize README, architecture, project rules, setup instructions, and
  acceptance documentation with observed behavior and remaining limits.

Acceptance: a new developer can install the language, run ordinary standalone
programs, perform the four specified effect families, and serve the minimal
HTTP response; the full suite and CI are green and the one-bridge claim has an
explicit evidence map.

Completion evidence: 4,261 assertions across 30 test files, the unchanged
expanded purity scan over all 16 `core/` modules, and the complete boundary
gate passed on 2026-08-27. The three exact `examples/` programs ran from a
copied package installation under an isolated Racket user home: stdout was
byte-exact, write/read recovered identical bytes in an empty temporary
directory, and the HTTP program announced an ephemeral loopback URL, served a
lambda-built 200 response to a test-side external client, closed its listener,
and exited. The boundary gate now inventories all 76 Racket sources, enforces
closed-vocabulary, effect-free one-way readers, keeps host-enabled tests and
tooling outside every production dependency path, requires public-language
applications, rejects
unknown source locations, and pins host-exclusive primitives outside the sole
bridge. `docs/ACCEPTANCE.md` records the final criterion map and explicit
one-bridge evidence map. Phase 20 added no executable production module and
changed no operation, authority, representation, or language semantic.

# Milestone 3 — Independent distribution

Status: complete (2026-08-29)

This milestone turns the completed Racket-hosted implementation into a product
that a programmer can download and use without installing, configuring, or
knowing Racket. It changes delivery and launch infrastructure, not the
object-language computational model.

The following constraints apply throughout:

- `.attl` is the canonical public source extension. A source file uses the
  exact `#lang attalambda` declaration so the verified reader, expander,
  source locations, and Lisp syntax remain authoritative; users run it
  through `attalambda`, never through a separately installed `racket` command.
- The initial public command surface is exactly `attalambda FILE.attl`,
  `attalambda --help`, and `attalambda --version`. A REPL, compiler command, package manager,
  formatter, debugger, editor integration, installer, and automatic updater
  remain outside this milestone unless a later phase proves one necessary.
- A release artifact bundles the Racket runtime and every language module it
  needs. It must not consult a system Racket installation, user package
  registry, source checkout, build directory, or network service at run time.
- The launcher is trusted module-loading scaffolding, not object-language
  computation and not another language-visible effect primitive. Its exact
  dynamic-loading and diagnostic capabilities must be separately classified;
  no AttaLambda program may import, name, or invoke them.
- The approved unary `host` remains the sole language-visible bridge for
  stdout, file, and TCP effects. Packaging must not add parsing, arithmetic,
  routing, Result control flow, or other ordinary language behavior in the
  launcher.
- Real-host programs retain the launching process's documented filesystem and
  network authority. Distribution adds no implied sandbox, permission prompt,
  backup, or trust guarantee.
- Use Racket's included executable-embedding and distribution facilities
  before considering another dependency. The expected artifact cost is a
  bundled Racket runtime and its transitive support files; every platform
  phase must measure compressed size, installed size, startup time, and the
  included file set.
- Release builds use one pinned Racket CS toolchain. Start with Racket 9.3,
  which the existing CI already pins; the Phase 21 proof must record and
  justify any change instead of silently building artifacts with the local
  Racket 8.10 installation.
- Native artifacts are required initially for Linux x86-64, macOS x86-64,
  macOS arm64, and Windows x86-64. Each artifact is built and tested on its
  own operating-system family because Racket distributions are platform
  specific.
- A public release is blocked until Kyle explicitly approves both the
  repository license and publication of the release. Planning or building a
  release candidate is not permission to publish one.

Phases 21 through 26 below preserve the exact names, artifact measurements,
commands, and URLs observed before the Phase 27 rename. They are historical
evidence, not the current public naming contract. Phase 27 supersedes those
names without retroactively relabeling the artifacts that were actually
built and tested.

## Phase 21 — Distribution contract and feasibility proof

Status: complete and approved (2026-08-27)

- [x] Write `docs/design/standalone-distribution.md` with the exact `.atl`
  source contract, command grammar, exit-status rules, trusted-launcher
  boundary, artifact layouts, target matrix, version source, and release
  authority.
- [x] Define launcher behavior for missing files, wrong extensions, malformed
  language declarations, source/expansion failures, unexpected implementation
  failures, and ordinary lambda-encoded Error or Result values. The launcher
  must not reinterpret an object-language Error as a host exception or use it
  to decide later object-language effects.
- [x] Prove in disposable test space under the pinned Racket 9.3 toolchain
  that it can load a `.atl` module and that `raco exe` with explicit dynamic
  `#lang` support plus `raco distribute` can carry the reader, expander, compiler
  support, language modules, and runtime files needed to run a user-supplied
  source outside the checkout.
- [x] Record the observed artifact dependency closure and identify every
  trusted module-loading capability that later boundary tooling must admit;
  do not add production launcher code during the proof.
- [x] Obtain explicit approval of the completed distribution design before
  Phase 22 changes the language surface or introduces launcher code.

Acceptance: the end-user and trust contracts are unambiguous, the current
toolchain has demonstrated that arbitrary external `.atl` files can be carried
by a self-contained distribution, and no new purity exception or public
capability has been implemented before approval.

## Phase 22 — Canonical `.atl` runner

Status: complete (2026-08-27)

- [x] Implement the minimal `atl` entry point in its own `runner/` layer with
  the approved `run`, `--help`, and `--version` interface and no third-party
  dependency.
- [x] Load exactly the path supplied to `atl run`, require the canonical
  `.atl` extension and `#lang alone_the_lambdas` declaration, reject every
  dotenv spelling before content access, preserve source filename/line/column
  information, and avoid implicit directory, package, network, or source-file
  discovery.
- [x] Establish one version source shared by package metadata, the CLI, build
  scripts, and future artifact names; initialize the public product version as
  `0.2.0-dev`. Because Racket 9.3 rejects that SemVer spelling in `info.rkt`,
  mechanically derive and verify the approved `0.1.900` package-metadata
  projection rather than duplicating version authority.
- [x] Add an exact runner classification to the structural boundary gate. It
  may contain only the approved command-line and module-loading scaffolding,
  must export no object-language binding, and must remain unreachable from
  core, effects, codec, host, macros, readers, and the language facade.
- [x] Rename the three public programs to `.atl`, add the minimal `hello.atl`
  used by the end-user guide, update copied-package and application inventory
  rules to recognize the official extension, and reject unknown or symlinked
  application inputs without inspecting their targets.
- [x] Add focused source-tree tests for help, version, argument validation,
  paths containing spaces and non-ASCII characters, the hello smoke program,
  all three canonical applications, and proof that the runner uses the
  existing language rather than a second parser or evaluator.

Acceptance: from the development checkout, the new entry point runs canonical
`.atl` programs through the existing language with stable command behavior,
while structural checks prove the loader is scaffolding rather than a second
object-language escape hatch.

Completion evidence: `./run-all-tests.sh` passed on 2026-08-27 with 4,412
assertions across 31 test files, the unchanged expanded purity scan over all
16 `core/` modules, and a zero-finding structural inventory of all 79
repository source files. The 126-check runner suite used a copied package
installation under an isolated Racket user home and proved the exact help,
version, argument, source-contract, path, symlink, dotenv, existing-expander,
Error, and Result behavior. The 110-check boundary suite pins the one
non-exporting loader call, exact runner imports and vocabulary, all three
version projections, the four canonical `.atl` applications, and every
forbidden dependency direction. The three real effect applications also ran
through that copied runner. No core, effect, codec, host, macro, reader, or
language-facade executable behavior changed.

## Phase 23 — User-facing launch diagnostics

Status: complete (2026-08-28)

- [x] Give command misuse, missing/unreadable source, invalid extension,
  malformed declaration, read/expansion failure, and unexpected launcher
  failure concise Alone the Lambdas diagnostics on stderr with documented,
  stable nonzero exit statuses.
- [x] Preserve the original `.atl` path and useful source position while
  removing checkout paths, temporary build paths, host procedure renderings,
  and irrelevant Racket implementation stack details from normal diagnostics.
- [x] Keep lambda-encoded Error and Result semantics unchanged: a successfully
  instantiated module exits successfully unless the program explicitly turns
  a value into an effect or the approved design establishes a one-way final
  observation rule that cannot affect object-language computation.
- [x] Test syntax errors, unbound identifiers, unsupported datums, wrong public
  names, ordinary contract Errors, Result Err values, real-host failures, and
  internal launcher failures separately so the CLI never disguises one class
  as another.
- [x] Synchronize the architecture and acceptance evidence with the exact
  distinction between launcher failure, completed language data, and requested
  host failure.

Acceptance: a user who does not know Racket receives actionable ATL-level
launch diagnostics without changing Error/Result behavior, effect order, or
the sole-host claim.

Completion evidence: `./run-all-tests.sh` passed on 2026-08-28 with 4,449
assertions across 31 test files, the unchanged expanded purity scan over all
16 `core/` modules, and a zero-finding structural inventory of all 79 source
files. The 161-check runner suite pins every diagnostic byte and exit status,
strict UTF-8 rejection, original relative path plus source position, absence
of temporary/package/raw host detail, and separate contract Error, pure Result
Err, real-host Result Err, and injected internal-failure behavior. The
112-check boundary suite pins the exact safe formatter and sole encoding
preflight in addition to the existing non-exporting one-loader class. No core,
effect, codec, host, reader, expander, or public-language executable changed.

## Phase 24 — Self-contained Linux distribution

Status: complete (2026-08-28)

- [x] Add one deterministic build entry point that compiles the runner,
  explicitly embeds dynamic support for `#lang alone_the_lambdas`, assembles
  its runtime with `raco distribute`, and produces a versioned Linux x86-64
  archive without modifying the developer's package registry.
- [x] Keep build outputs outside source control and include only the executable
  tree plus the provisional runtime notices, getting-started document, build
  manifest, and `.atl` examples approved for internal testing. Until Phase 27
  records an approved repository license, label every archive as an
  unpublished development artifact rather than a releasable download.
- [x] In a fresh Linux container with no `racket` or `raco` command, no ATL
  package installation, no source checkout, and no inherited Racket
  collection path, unpack the archive after transferring it as an opaque
  artifact and run help, version, stdout, isolated file round trip, and
  ephemeral-loopback HTTP acceptance.
- [x] Move the unpacked tree to a second path and repeat a smoke run to prove
  it contains no absolute build-tree or package-registry dependency.
- [x] Record compressed size, unpacked size, startup time, runtime file
  inventory, remaining system-library assumptions, and SHA-256 digest. Do not
  optimize with demodularization or another tool until this correct baseline
  exists and measurement demonstrates a need.

Acceptance: the Linux archive runs arbitrary canonical `.atl` source on a
machine with no Racket installation and performs the completed language's real
stdout, file, and loopback-network work entirely from the unpacked tree.

Completion evidence: two isolated builds from the same approved uncommitted
Phase 24 state based on
`ce55da42a06a4edc5ef37e2d1ca787b5bc1de8fc` produced the same 10-file archive;
later hardening rebuilds retained SHA-256
`a5e43c54467fa4afe0bb74aeeda962ae617de26b35c6cf50d65891de81b64cf0`.
That disposable development archive was `13,679,991` compressed bytes and
`59,299,555` unpacked regular-file bytes. Its executable tree was exactly
`bin/atl` (`7,853,237` bytes) plus `lib/plt/racketcs-9.3` (`51,412,696`
bytes); both retained only the ELF loader, `libc`, `libdl`, `libm`,
`libpthread`, `librt`, and `libz` as observed system-library assumptions. A
digest-pinned Ubuntu 24.04 container with no Racket commands, no checkout, no
package install, a read-only root, an unprivileged user, and no external
network verified the external checksum; exact help/version/stdout/file/HTTP
bytes; a source created after packaging; embedded-reader precedence; and a
move between paths containing spaces. Final runs observed 290–344 ms
first-process startup and 294–302 ms after relocation. The recorded digest
belongs only to the
unpublished validation artifacts, not a release or later clean commit. The
build added no dependency or demodularization and modified no production
Racket source, operation, representation, or host authority.

Final completion verification passed 4,492 assertions across all 32 test
files, the unchanged expanded purity scan over 16 `core/` modules, and the
complete zero-finding structural inventory of all 80 Racket and `.atl`
sources. The focused distribution contract suite passed 43 assertions.

## Phase 25 — Native macOS distributions

Status: complete (2026-08-28)

- [x] Add pinned native macOS x86-64 and arm64 build jobs using the same
  version and audited build contract as Linux; do not treat a launcher tied to
  a CI Racket installation as a distributable executable.
- [x] Produce predictably named `.tar.gz` archives that preserve the runtime-
  relative layout and canonical `atl` entry point on both architectures.
- [x] Transfer each archive to a separate same-architecture consumer job that
  does not install Racket, then run the CLI, canonical stdout/file
  applications, and loopback-network acceptance from a writable temporary
  directory.
- [x] Verify archive contents, executable permissions, paths containing spaces,
  clean stderr, version agreement, checksums, and absence of checkout,
  package-registry, or build-runner dependencies on both targets.
- [x] Record the oldest macOS versions actually demonstrated by clean consumer
  jobs; do not claim an untested release, architecture, signing state, or
  minimum version.

Acceptance: both macOS architectures provide the same ATL behavior as Linux
without a preinstalled Racket environment, and each passes its acceptance
suite after a build-to-consumer job boundary.

Completion evidence: validation commit
`ed0db7df9ca17d4e7b2ea458069f7861c1207a2d` passed the complete
[GitHub Actions run](https://github.com/kserrec/alone_the_lambdas/actions/runs/33181962284).
Native Racket CS 9.3 builds produced the predictably named Intel and Apple
Silicon archives, and separate same-architecture jobs received only each
archive, its external `SHA256SUMS`, and the consumer harness. The consumers
had no `racket` command, `raco` command, or checkout and passed exact
help/version/source/stdout/file/loopback-HTTP behavior, hostile collection-path
precedence, paths containing spaces, and relocation.

The demonstrated Apple Silicon consumer was macOS 15.7.7 arm64. Its 9-file
payload was `13,698,161` compressed bytes and `62,117,801` unpacked
regular-file bytes, with SHA-256
`8f428ff16be4acbf4a8ad41ce7241a40a623931ef9b5451c81b83e2fd2aad63f`;
first and relocated startup observations were 194 ms and 121 ms. The
demonstrated Intel consumer was macOS 15.7.9 x86_64. Its 9-file payload was
`13,669,470` compressed bytes and `59,412,300` unpacked regular-file bytes,
with SHA-256
`7ac92ca6aa49ce2882e43ab0d318d034932cc06cfe88e9554048b018ec0742ab`;
first and relocated startup observations were 1,170 ms and 319 ms. Each
archive contained one Mach-O runtime file and observed only CoreFoundation,
`libSystem`, `libiconv`, and `libncurses` as system-library assumptions.
These versions, timings, sizes, and digests are observations for those
disposable validation artifacts, not compatibility floors, performance
guarantees, release checksums, signing claims, or public downloads.

Kyle explicitly approved temporary public GitHub Actions transfer for these
two unpublished artifacts. Both uploads used one-day retention only as a
cleanup-failure fallback; the final cleanup job deleted them immediately, and
the run artifact API reported zero remaining artifacts. Phase 25 changed only
CI, shell packaging/consumer tooling, focused tests, and documentation. It
changed no production Racket source, language operation, representation, or
host authority. Completion verification passed 4,541 assertions across all
32 test files, the unchanged expanded purity scan over 16 `core/` modules,
and the complete zero-finding structural inventory of all 80 Racket and
`.atl` sources. The focused distribution contract suite passed 92 assertions.

## Phase 26 — Native Windows distribution

Status: complete (2026-08-28)

- [x] Add a pinned native Windows x86-64 build job using the same version and
  audited build contract as Linux and macOS, including every DLL and runtime
  file required by a machine without Racket.
- [x] Produce a predictably named `.zip` archive with the canonical `atl.exe`
  entry point and a runtime-relative layout that survives extraction to a
  different drive and a path containing spaces.
- [x] Transfer the archive to a separate Windows consumer job that does not
  install Racket, then run help, version, stdout, isolated file round trip,
  and ephemeral-loopback HTTP acceptance from the extracted tree.
- [x] Verify archive contents, exit statuses, clean stderr, version agreement,
  checksum, absence of checkout/package-registry/build-runner dependencies,
  and the exact unsigned or signed executable status.
- [x] Record the oldest Windows version actually demonstrated by a clean
  consumer environment; do not claim an untested release, architecture,
  signing state, or installer experience.

Acceptance: the Windows archive runs the same canonical `.atl` programs as
the Linux and macOS archives with no external Racket installation, survives
relocation, and passes its independent consumer suite.

Completion evidence: validation commit
`a9f2bdc7d07a0283871ede548aa0c33cee0a3b78` passed the Windows build,
independent consumer, and immediate-cleanup jobs in [GitHub Actions run
33193791101](https://github.com/kserrec/alone_the_lambdas/actions/runs/33193791101).
The pinned `windows-2025` build used full x86-64 Racket CS 9.3, staged only
approved nonsymlink production inputs under an isolated user home with
`--deps fail`, invoked `raco exe --embed-dlls ++lang alone_the_lambdas` and
`raco distribute`, and produced the predictable
`alone-the-lambdas-0.2.0-dev-windows-x86_64.zip` plus external
`SHA256SUMS`.

The separate consumer performed no checkout and installed no Racket. It
reported absent `racket` and `raco` commands, verified the external checksum
before extraction, rejected unsafe ZIP paths, checked the exact nine-file
payload and one x86-64 PE runtime, and matched the build's `dumpbin` system-DLL
inventory and Authenticode result. It then passed exact help/version/status
and clean-stderr checks, a source created after packaging, hostile collection-
path precedence, stdout, isolated file replacement/readback, ephemeral-
loopback HTTP, and relocation from the runner's `D:` drive to a path containing
spaces on `C:`.

The demonstrated consumer was Microsoft Windows Server 2025 Datacenter
10.0.26100, build 26100, x86-64. The disposable nine-file artifact was
`15,251,225` compressed bytes and `23,875,480` unpacked regular-file bytes,
with SHA-256
`32323a72bb4dad11690f5189cdc543fcc49bb6138d1e1abe19e4694c0595b397`.
Its only PE/runtime file was `bin/atl.exe`; Racket emitted no loose runtime
files, so `lib/` was empty. The executable was `NotSigned` and observed only
`KERNEL32.dll`, `msvcrt.dll`, and `USER32.dll` as system-DLL assumptions.
Startup observations were 282 ms before relocation and 360 ms afterward.
These are observations for that disposable validation artifact, not a lower
Windows compatibility floor, performance guarantee, signing promise, release
checksum, installer, or public download.

Kyle explicitly approved only the temporary public transfer of this one
unpublished archive, its checksum, and its self-contained harness. The
workflow reused the existing full-commit-pinned official upload/download
actions; their Phase 26 cost is one transient artifact and no new package or
runtime dependency. Retention was one day only as a cleanup-failure fallback;
the `always()` cleanup deleted the exact artifact immediately, and the run
artifact API reported zero remaining artifacts.

Phase 26 changed CI, PowerShell build/consumer tooling, focused tests, and
documentation only. It changed no production Racket source, language
operation, representation, effect order, or host authority. Completion
verification passed 4,589 assertions across all 32 test files, the unchanged
expanded purity scan over 16 `core/` modules, and the complete 80-source
boundary inventory. The focused distribution contract suite passed 140
assertions.

## Phase 27 — Apache license and AttaLambda public rename

Status: complete (2026-08-28)

- [x] Select and record Apache License 2.0 after Kyle explicitly approved its
  legal terms and confirmed Kyle Serrecchia as the 2026 copyright owner.
- [x] Adopt `AttaLambda` as the public project and language name,
  `attalambda` as the repository, package, collection, executable, and
  machine-facing name, and `.attl` as the only public source extension.
- [x] Make the source declaration exactly `#lang attalambda` and the direct
  execution grammar exactly `attalambda FILE.attl`, `attalambda --help`, and
  `attalambda --version`, with no `atl`, `.atl`, old declaration, or `run`
  compatibility aliases.
- [x] Synchronize the runner, examples, package metadata, reader, native build
  and consumer tooling, workflow artifact names, specifications, architecture,
  acceptance map, and current user/developer documentation with the new
  identity while preserving pre-rename evidence as explicitly labeled history.
- [x] Prove the renamed collection from a fresh isolated package install, run
  every canonical application through the direct command grammar, pass the
  complete suite and structural inventory, and reject every retired public
  spelling.
- [x] Rename the public GitHub repository to `kserrec/attalambda` and update
  the verified local `origin` to that destination.
- [x] Push the exact tested commit and verify CI without creating a Git tag,
  GitHub Release, release-candidate file, signature, or public download. Kyle
  explicitly authorized only the two renamed unpublished macOS archives and
  one renamed unpublished Windows archive, their external checksums, and their
  consumer harnesses as temporary workflow artifacts, with immediate deletion
  and one-day retention solely as a cleanup-failure fallback.

Acceptance: every current public and machine-facing surface says AttaLambda,
`attalambda`, or `.attl` according to its role; a fresh user runs
`attalambda FILE.attl`; retired spellings fail rather than silently aliasing;
and object-language computation, representations, effects, host authority,
version `0.2.0-dev`, and release state remain unchanged.

Local evidence: `./run-all-tests.sh` passed on 2026-08-28 with 4,617
assertions across all 32 test files, the unchanged expanded purity proof over
16 `core/` modules, and the complete zero-finding structural inventory of all
80 Racket and `.attl` sources. Focused totals include 181 runner assertions,
78 fresh-language assertions, 113 boundary assertions, 144 distribution-
contract assertions, and 22 real-application acceptance assertions. The
public repository rename and local remote are verified. Validation commit
`a048550e619499e0fbb3f944ba959ef84c4cc586` passed the complete suite and all
ten build, clean-consumer, and cleanup jobs in [GitHub Actions run
33204885605](https://github.com/kserrec/attalambda/actions/runs/33204885605).
The renamed Linux, macOS arm64, macOS x86-64, and Windows x86-64 archives all
passed their no-Racket consumer checks and relocation. Both macOS artifacts
and the Windows artifact were deleted immediately; the completed run's
artifact API reported `total_count: 0`. Public `main` resolves to that exact
commit. Product version remains `0.2.0-dev`, and no Git tag, GitHub Release,
release-candidate file, signature, binary release, or public download was
created.

## Post-Phase 27 maintenance — seam refactor, bug hunt, and test audit

Status: complete (2026-08-28)

- [x] Simplify the deterministic codec, readers, structural gates, and native
  consumer helpers without changing language behavior or boundary authority.
- [x] Correct the pure HTTP parser's origin-target grammar and request-body
  framing validation, including zero-only `Content-Length` and rejection of
  `Transfer-Encoding` in the bodyless request subset.
- [x] Reject forged noncanonical List terminators in deterministic codec
  conversion instead of silently truncating them as `NIL`.
- [x] Audit the complete test suite, prove representative tests by temporary
  mutation, and close the four confirmed gaps: exact stdout Error frames,
  inherited `PLTCOLLECTS`, automatic CI triggers, and external completion
  attestation for the source suite and native artifact consumers.

Completion evidence: commits `706acee79392f011e056b94418d63b998a15e261`,
`a9da8b72ea58ef8a4b3c4dc4bad15847b3d2c0ef`, and
`505a46bba37d68efb4f3ffcb17048c03d85fb767` contain the refactor, three
correctness fixes, and test-audit hardening respectively. The final local
verification passed 4,687 assertions across all 32 test files, the expanded
purity scan over all 16 `core/` modules, and the complete repository boundary
and source-inventory gate. A fresh read-only cold review found no remaining
test-audit issue. No release artifact, tag, signature, version change, or new
language/host capability was created.

## Post-Phase 27 security audit — HTTP request bound

Status: complete (2026-08-28)

- [x] Full ship-readiness security audit of the repository (runner, host
  boundary, codec, lang/macros, effects/HTTP protocol code, tooling and
  distribution, CI, repo hygiene, and the structural purity/boundary gates).
  One confirmed finding; everything else examined and cleared.
- [x] **F1 — unbounded HTTP request buffering (fixed).** `effects/http-server.rkt`
  accumulated a connection's bytes with no size limit while waiting for a
  complete request header, so a hostile peer that streams bytes never forming
  `\r\n\r\n` (and never closing) could exhaust process memory. The read loop now
  caps the accumulated request at 8192 bytes and checks the size *before* each
  parse, rejecting an over-limit request as the existing malformed-request
  Result (kind 10); the connection is then closed on the normal cleanup path.
  Regression tests in `tests/http-server-test.rkt` prove the loop terminates on
  a single oversized read, on sub-cap chunks that accumulate past the cap, and
  through the whole-server loop; removing the guard fails the suite.

Deferred hardening (named reason — redesign, not a spot fix):

- **HTTP re-parse cost within the cap.** Within the 8192-byte bound the whole
  buffer is still re-parsed after every partial read, so a peer dribbling tiny
  chunks pays O(cap^2) interpreter work on its one connection before rejection.
  Memory and termination are now bounded, and this grants no capability beyond
  the deliberately blocking single-connection server's already-documented "one
  client can tie it up" property (a peer that simply stalls already blocks the
  no-timeout `tcp-read`). Fully removing the quadratic cost requires an
  incremental HTTP parser — scanning only the newly-read region for the
  terminator instead of re-scanning the buffer — which is a redesign of the
  read/parse loop with terminator-boundary and trailing-byte correctness risk,
  beyond an afternoon and beyond this minimal server's contract. Revisit if the
  HTTP server graduates from a minimal demonstration to a supported surface.

## Phase 28 — Downloadable release candidate and novice documentation

Status: complete (2026-08-29)

The pinned Racket CS 9.3 inventory produced a 100,029-byte exact notice file
with SHA-256
`1343f218ba484a79fbef498d4e8fb02e202763a19e46c5e610a8bfe900bcbefd`.
Kyle reviewed and approved those exact bytes, then separately approved the
Phase 28 implementation scope and the temporary transfer of only the two
macOS and one Windows unpublished candidates, checksums, and consumer
harnesses. The full approval text and boundaries are recorded in
`docs/design/standalone-distribution.md`. No approval authorizes a tag, GitHub
Release, signing operation, public download, or publication.

- [x] Prepare and present the exact bundled Racket runtime notices, obtain
  approval only after Kyle has seen those terms, then include the approved
  notices and the repository license in every release-candidate artifact.
- [x] Separate contributor setup from end-user setup. The primary getting-
  started path must begin with downloading the correct platform archive,
  extracting it, and running `attalambda hello.attl`; it must not instruct an
  end user to install Racket, use `raco`, or register a package.
- [x] Document `.attl` syntax, the required `#lang attalambda` declaration,
  executable location, supported platforms, exit statuses, archive
  verification, and the real host's unsandboxed stdout/filesystem/network
  authority in plain language.
- [x] Promote the single version source to `0.2.0-rc.1`, rebuild and stage the
  four archives with the approved license, one checksum manifest, source
  commit, dependency/runtime inventory, release notes, and exact known
  limitations as an unpublished release candidate.
- [x] Have clean consumer jobs execute every command printed in the end-user
  guide and verify the downloaded-artifact workflow independently of the
  source-tree tests.

Acceptance: a person with no Racket installation or knowledge can follow the
release-candidate documentation verbatim, verify the archive, and run a real
`.attl` program; the candidate remains unpublished pending explicit approval.

Completion evidence: candidate source commit
`91ba3a9a8d57f0f19f4e8620317a85cb781148df` passed 4,745 assertions
across all 32 test files, the unchanged 16-module purity proof, the complete
boundary inventory, all four native builders, and all four independent
no-Racket consumers in [GitHub Actions run
33258685537](https://github.com/kserrec/attalambda/actions/runs/33258685537).
Every consumer reported `guide_workflow=passed` and relocation success. The
two macOS and one Windows transfer artifacts were deleted immediately; the
completed run's artifact API reported `total_count: 0`.

The four exact disposable CI archive hashes are recorded in
`docs/design/standalone-distribution.md` and were assembled into one local
four-entry `SHA256SUMS` staging record. They are unpublished validation
checksums, not public downloads or Phase 29 release checksums. Phase 28
created no tag, GitHub Release, signature, or public download. It changed no
object-language computation or host authority; the intended executable-visible
change is the runner's version projection from `0.2.0-dev` to `0.2.0-rc.1`.

## Phase 29 — First independent release

Status: complete (2026-08-29)

Kyle separately approved the exact final-version implementation scope and the
one-time temporary transfer of only the two macOS and one Windows final-but-
unpublished archives, their one-entry checksums, and their self-contained
consumer harnesses. That transfer is complete: all consumers passed, Codex
downloaded and verified the exact tested bytes into local staging, deleted the
three exact GitHub artifacts through the API, and verified that the run now
has zero artifacts. Linux remained within one job, and ordinary `always()`
cleanup is restored. Neither approval authorizes paid GitHub usage, a tag,
GitHub Release, signing, release-asset upload, public-download claim, or
publication. Kyle later gave a separate exact publication approval; its
literal text and the resulting public evidence are recorded in
`docs/design/standalone-distribution.md`.

- [x] Set `0.2.0` as the single release version, make the CLI, package
  metadata, artifact names, documentation, and release notes derive from it,
  and reject mismatches in CI.
- [x] Run the complete source suite, expanded core purity proof, repository
  boundary inventory, four native artifact builds, and four no-Racket consumer
  suites from the exact commit proposed for release.
- [x] Present the final license, public Git tag, GitHub Release, artifact
  names, checksums, platform support, unsigned/signing status, and any user
  warnings to Kyle, then obtain explicit permission to publish that exact
  release. State any account, credential, monetary, or irreversible
  consequence literally before requesting it.
- [x] After approval, create the annotated Git tag (cryptographically signed
  only if separately approved signing credentials are available) and public
  GitHub Release, attach only the verified artifacts and checksum manifest,
  then download and reverify each published artifact rather than trusting the
  upload step.
- [x] Confirm the public instructions resolve from a clean browser-visible
  release URL, `attalambda --version` reports `0.2.0`, all checksums match, and
  `main` remains clean and synchronized with its verified remote.

Completion evidence: source commit
`42ff0a7810ebeced445ab23561433a2dc423e433` passed 4,751 assertions across
all 32 test files, the unchanged 16-module purity proof, the complete
zero-finding source inventory, all four native builds, and all four clean
consumers in [GitHub Actions run
33262922610](https://github.com/kserrec/attalambda/actions/runs/33262922610).
The exact published archives have SHA-256 values
`86f980d696b45b42c251b78e6a66b9cd875f649217bfb09731cf6b47c66b00ac`
(Linux x86-64),
`5791ca3c28717972409d0d3503e135f685bcb7011ec24e6e4f9e70c7e5426b2b`
(macOS arm64),
`72f56f4d95665a3ca802160175c4082ce42b08054a35b963a10b0597b9d91fdc`
(macOS x86-64), and
`0ffcf7cd7218459efe1de1de87c7ff650328d01b16caa253deb6aa621188015a`
(Windows x86-64). Their 410-byte combined `SHA256SUMS` has SHA-256
`7786bf553caac0087ab22f3636d546a1fe00f89a446611c1516cc58f411f6f7f`;
all four entries verify. The unsigned annotated tag `v0.2.0` peels to that
exact source commit and carries annotation `AttaLambda 0.2.0`. The public
latest non-prerelease [AttaLambda 0.2.0
Release](https://github.com/kserrec/attalambda/releases/tag/v0.2.0) contains
only those four manually uploaded archives and the combined manifest, in
addition to GitHub's automatic source-code links. An authenticated draft
download and a subsequent anonymous public download both matched all five
staging files byte-for-byte. The anonymous Linux archive then passed the full
digest-pinned, no-Racket Ubuntu 24.04 consumer again. The public API and HTML
show the exact title, tag, non-prerelease/latest state, asset names, sizes,
digests, notes, signing warnings, and public URLs; the anonymous latest URL
resolves successfully. Publication used no signing or notarization operation,
paid GitHub feature, purchase, or GitHub Actions run.

Acceptance: AttaLambda has a verified public `0.2.0` release whose users
download a platform archive, write `.attl`, and run `attalambda` without
installing or learning Racket, while the language's lambda purity and single
explicit host boundary remain unchanged.

## Phase 30 — Withdraw unsupported desktop release assets

Status: complete (2026-08-29)

A real public-download attempt demonstrated that Gatekeeper blocks the
unsigned, unnotarized macOS artifacts. The Windows artifact is verified
Authenticode `NotSigned`; Microsoft's current SmartScreen documentation says
unsigned downloads receive the “Windows protected your PC” warning and may be
non-bypassable under enterprise policy, while Windows 11 Smart App Control can
block unsigned apps outright. The previous native consumer jobs proved
portable execution after internal artifact transfer, not the browser-download
security path a user actually encounters. Kyle therefore authorized removing
macOS and, after that Windows evidence was established, Windows from the
documentation and public Release.

- [x] Resolve the exact three public asset IDs and reverify byte-identical
  local recovery copies before deletion.
- [x] Make Linux x86-64 the sole supported public binary target throughout
  current user documentation while preserving literal Phase 21 through 29
  history and the internal macOS/Windows portability harnesses.
- [x] Keep the original 410-byte `SHA256SUMS` unchanged as an immutable
  publication record; label its removed-platform entries as historical rather
  than replacing bytes under the same public filename.
- [x] Delete only macOS asset IDs `535549609` and `535549602` and Windows asset
  ID `535549611`; retain Linux asset ID `535549598`, manifest asset ID
  `535549605`, Release ID `379061612`, tag `v0.2.0`, and GitHub's automatic
  source archives.
- [x] Rewrite the Release notes for the current Linux-only surface and verify
  the resulting public API state and withdrawn download URLs.
- [x] Re-run the focused documentation/distribution tests and complete source
  suite without changing production behavior.

Completion evidence: immediately before withdrawal, all three public assets
matched the exact locally staged SHA-256 values recorded in Phase 29. A fresh
Ubuntu 24.04 Docker userspace on x86-64 downloaded the retained public Linux
archive and manifest, reported the archive checksum `OK`, confirmed Racket was
absent, printed `AttaLambda 0.2.0`, and ran the bundled hello program to print
`Hello from AttaLambda.`. The revised public Release exposes only the retained
Linux archive and original historical manifest as manual assets. Exact
deletion and post-edit verification are preserved in
`docs/design/standalone-distribution.md` and `HANDOFF.md`.

Acceptance: a reasonable visitor sees one supported public binary target,
Linux x86-64, and receives no instruction to bypass macOS or Windows security
controls. Historical evidence remains literal. No language, runner, runtime,
effect, reader, macro, expander, build harness, CI job, legal notice, Linux
binary, tag, or version behavior changes.

# Milestone 4 — Exact rational numbers and foundational values

Status: complete (2026-09-01)

Kyle directed (2026-09-01) that the entire Milestone 4 update lands on the
single branch `milestone-4-rationals`. Every Milestone 4 `$next` unit commits
and pushes that branch instead of `main`; `main` receives the milestone only
when it is complete and Kyle merges or approves the merge.

## Controlling rule — absolute object-language purity

Every new object-language value and every computation involving private Nat,
private Int, public Rat, Unit, Byte, Option, or Map must be implemented
entirely with variables, unary `lambda`, and application after macro
expansion. This governs representations, constructors, normalization,
arithmetic, comparison, powers, conversions between object-language types,
type and value checks, error decisions, Option selection, and every Map
operation.

Racket must not calculate or decide an AttaLambda program's result. In
particular, Rat and Int operations may not use Racket arithmetic, Map may not
use a Racket hash table or other host collection, and no new type may use
Racket conditionals, pattern matching, equality, loops, mutation, exceptions,
or data access for object-language computation.

The existing classified seams remain unchanged in purpose:

- macros may mechanically expand source into pure unary lambda terms;
- `runtime/codec.rkt` may deterministically translate validated values across
  the Racket/AttaLambda boundary, but may not perform object-language
  arithmetic or decide object-language results;
- `runtime/host.rkt` may perform only the explicitly approved external effects
  and conversions at its existing narrow boundary; and
- readers, tests, and tooling may observe or verify values but may not enter a
  production computation path.

`all_the_lambdas` is an algorithmic ancestor and source of test cases, not an
authority over AttaLambda's purity rules. Every borrowed idea must be rebuilt
as pure untyped lambda calculus and rejected or changed if it cannot satisfy
this rule. If any planned feature appears to require a broader Racket role,
implementation stops and the conflict is surfaced instead of weakening the
purity promise.

## Settled design

- Rat becomes the only number type users see.
- Binary Nat remains private machinery for magnitudes, counting, characters,
  bytes, ports, and similar whole-number work.
- Int remains private machinery: a sign plus a binary Nat magnitude.
- Rat contains an Int numerator and a positive Nat denominator.
- Int zero has only one representation: positive zero.
- Rat zero has only one representation: positive `0/1`.
- Every Rat is reduced to its simplest equivalent fraction.
- A zero denominator is invalid. It never means zero.
- `DIV` by zero returns `Result Err`.
- `EXP` accepts only whole-number exponents. Every fractional exponent is
  rejected, even when that particular power would happen to have a rational
  answer.
- Negative whole exponents use the reciprocal. Zero raised to a negative
  exponent returns `Result Err`.
- `0^0` remains `1`, following `all_the_lambdas`.
- Exponentiation uses repeated squaring rather than decrementing the exponent
  one by one.
- Wrong argument types produce Error. Expected arithmetic failures produce
  `Result Err`.
- The existing generalized exact-tag checker remains. There is no numeric
  hierarchy, automatic promotion system, generic arithmetic dispatcher, or
  arity-specific checker.
- Unit, Byte, Option, and Map become public types.
- Byte is data, not a second number type. Rat arithmetic rejects Byte.
- A byte sequence is `List Byte`; there is no separate Bytes type.
- Map receives a pure object-language equality function for comparing keys.
  The central type checker gains no special Map mechanism.
- Map lookup returns Option.
- Unit replaces uses of `NIL` that currently mean “the operation succeeded but
  has no useful answer.”
- Pair remains. Tuples remain nested Pairs. A Set can later be represented by
  a Map whose values are Unit.
- No public Nat, public Int, floating point, approximate decimal arithmetic,
  logarithms, trigonometry, irrational constants, Tuple type, Bytes type, or
  Set type is added in this milestone.

## Phase 31 — Make the new language contract authoritative

This Phase changes the specifications before executable work begins. The
three specifications remain the authority over every later Step.

### Step 31.1 — Amend the specifications

Status: complete (2026-09-01)

- [x] Update all three specification documents together so they state the final
  public type set and exact public operation names.
- [x] Specify the private Nat and Int representations and the canonical Rat
  representation.
- [x] Specify rational construction, normalization, arithmetic, comparison,
  floor, division, reciprocal, and exponent behavior.
- [x] Specify accepted exact integer and fraction literals and rejection of
  inexact Racket numbers.
- [x] Specify Unit, Byte, Option, and Map representations and operations.
- [x] Specify every new contract, invariant, and expected-computation error.
- [x] Specify the pure equality-function contract used by Map.
- [x] Preserve the existing host, codec, reader, type-checker, and absolute-purity
  boundaries without expanding their authority.
- [x] Retire the Nat tag without renumbering existing non-Nat tags.
- [x] Change no production module, test behavior, or executable behavior in this
  Step.

Acceptance: all three specifications agree on the new language, their stated
precedence remains unambiguous, and every later Step has an authoritative
contract rather than making a language-design decision during implementation.

Completion evidence: each specification received an explicitly dated,
append-only "Milestone 4 Amendment (2026-09-01)" section that wins over its
own earlier sections; pre-amendment bytes are unchanged above the amendment
markers. The main specification's amendment fixes the eleven-type public set,
private Nat/Int machinery, canonical reduced Rat with sole positive zero and
nonzero denominator, the exact Rat operation set (`SUCC ADD SUB MULT DIV EXP
RECIP NEG ABS FLOOR EQ LT LTE GT GTE IS-ZERO IS-WHOLE IS-NONNEGATIVE-WHOLE`),
exact-literal acceptance and inexact rejection, Unit, Byte with `List Byte`
sequences, Option, persistent Map with its pure key-equality contract, the
post-milestone effect signatures, and the new `NON-WHOLE-EXPONENT`,
`INVALID-COUNT`, and `INVALID-BYTE` kinds. The purity addendum's amendment
retires tag 3 permanently unassigned, assigns 7 RAT, 8 UNIT, 9 BYTE,
10 OPTION, 11 MAP, and extends absolute purity verbatim to every new type
without widening the macro/codec/host/reader seams. The naming addendum's
amendment fixes retained, new, and retired public spellings. The
specifications README records the new provenance hashes with the prior hashes
preserved as history. No production module, test, or executable behavior
changed; the full suite passed unchanged after the edit.

## Phase 32 — Turn binary Nat into a clean private arithmetic foundation

### Step 32.1 — Separate raw Nat arithmetic from the public Nat object

Status: complete (2026-09-01)

- [x] Make `core/binary-nat.rkt` contain only normalized binary-list values and
  raw binary Nat operations.
- [x] Move the current tagged Nat construction and public constants into the
  existing typed Nat layer as temporary compatibility code.
- [x] Preserve every current public result while this separation is made.
- [x] Set the single development version to `0.3.0-dev` and keep every projection
  of that version synchronized.
- [x] Add structural tests proving that private binary Nat arithmetic does not
  depend on tags, objects, typed functions, effects, the codec, or the host.

Acceptance: current programs behave identically, while the raw Nat foundation
can support Int and Rat without carrying a public Nat object into them.

Completion evidence: `core/binary-nat.rkt` now requires exactly the macro
layer, `fix.rkt`, `lists.rkt`, and `logic.rkt`, exports only `raw-` bindings
(including the newly exported `raw-zero-bits` and `raw-one-bits`), and
contains no tag, object, typed-function, effect, codec, or host reference.
`raw-make-nat`, `raw-nat-value`, and `ZERO` through `TEN` moved into
`core/typed-nat.rkt` as explicitly commented temporary compatibility code;
every production importer (chars, list-nat, the five effect modules, the
codec, the two Nat-observing readers, and the expander) now takes the tagged
bindings from the typed layer, and the boundary gate's pinned expander
require form tracks the move. New structural tests in
`tests/binary-nat-test.rkt` read the raw module's source and fail on any
non-raw export, any forbidden require, or any tagged/privileged symbol.
The single version source is `0.3.0-dev` with the `0.2.900` package
projection synchronized across `info.rkt`, the runner's approved-state
regex, the boundary gate and its test, the runner test, and all four native
build/consumer scripts. The full suite passed 5,978 assertions across all
32 test files (the growth over Phase 30's 4,755 is dominated by the new
per-symbol structural scan of the raw module), with the unchanged 16-module
purity proof and the zero-finding boundary inventory, on 2026-09-01; no
public operation, representation, or host authority changed.

### Step 32.2 — Add quotient with remainder, remainder, greatest common divisor, and least common multiple

Status: complete (2026-09-01)

- [x] Extend AttaLambda's current binary long-division traversal so one pure
  calculation produces both quotient and remainder.
- [x] Keep the existing raw division operation as selection of the quotient from
  that result, preserving its current answers.
- [x] Build remainder, greatest common divisor, and least common multiple from
  that pure result.
- [x] Do not replace AttaLambda's current division with the older
  `all_the_lambdas` implementation.
- [x] Test normalization, a smaller dividend, exact division, nonzero remainder,
  zero dividend, large binary values, and the internal zero-divisor guard.

Acceptance: Rat reduction and floor have the private division information they
need, with no host arithmetic and no change to existing Nat division results.

Completion evidence: the existing MSB-first long-division loop now returns a
raw pair of quotient and remainder (`raw-nat-div-rem`); `raw-nat-div` selects
the quotient from that pair with unchanged answers, `raw-nat-rem` selects the
remainder, `raw-nat-gcd` iterates Euclid's algorithm on the remainder with
its zero test guarding the recursive division, and `raw-nat-lcm` divides the
product by the greatest common divisor behind an explicit either-operand-zero
guard, so no zero divisor reaches the division loop (the `lcm 0 0` test fails
without it). `core/binary-nat.rkt` additionally requires only `pair.rkt`,
which the structural require pin now reflects. Focused tests cover the
quotient/remainder pair across all previous division cases, smaller
dividends, exact division, nonzero remainders, zero dividends,
non-normalized operands, nine-digit values, gcd/lcm identities and large
values, and unary arity. The full suite passed 6,296 assertions across all
32 test files with the unchanged 16-module purity proof and zero-finding
boundary inventory on 2026-09-01.

### Step 32.3 — Add the helpers needed for powers

Status: complete (2026-09-01)

- [x] Add pure binary Nat even, odd, halving, and exponentiation-by-squaring
  operations.
- [x] Keep these as private raw operations.
- [x] Test zero and one exponents, odd and even exponents, zero and negative-case
  prerequisites, and values large enough to prove that the implementation is
  not decrementing the exponent once per multiplication.

Acceptance: private Nat supplies every magnitude operation required by Int and
Rat powers while remaining pure unary lambda computation.

Completion evidence: `raw-nat-odd` reads the last bit of the normalized
value, `raw-nat-even` negates it, `raw-nat-half` drops the last bit and
renormalizes, and `raw-nat-exp` recurses on the halved exponent with one
squaring per exponent bit, so `raw-nat-exp 2 4096` produces the exact
4097-bit result in interpreted lazy evaluation — practical only because the
recursion performs twelve squarings rather than 4,095 multiplications. All
four remain private raw exports of `core/binary-nat.rkt` under the pinned
require set. Tests cover parity across boundaries and non-normalized input,
halving including zero and one, zero/one bases and exponents (`0^0 = 1`
groundwork), odd and even exponents, host-exponentiation agreement through
`7^13`, the 2^4096 magnitude proof, and unary arity.

## Phase 33 — Add private Int

### Step 33.1 — Add the representation and enforce one zero

Status: complete (2026-09-01)

- [x] Add a private Int representation consisting of a Bool sign and normalized
  binary Nat magnitude.
- [x] Route every construction through one pure function that turns any attempted
  signed zero into positive zero.
- [x] Add private sign, magnitude, zero, negation, and absolute-value operations.
- [x] Add an Int reader for tests and human inspection only.
- [x] Add no Int type tag, public Int constructor, Int literal, typed Int layer, or
  `#lang attalambda` export.

Acceptance: negative zero cannot be constructed through any supported private
Int operation, and Int remains pure untagged machinery unavailable to users.

Completion evidence: `core/int.rkt` represents an Int as a raw untagged pair
of raw Boolean sign (true means nonnegative) and normalized binary
magnitude; `raw-make-int` normalizes the magnitude and forces every zero —
including non-normalized and empty zero spellings — to positive zero, and
negation and absolute value route through it. `readers/int.rkt` renders a
completed Int as a signed host integer for tests only; the boundary gate's
reader vocabulary gained exactly `int->integer`, `raw-int-sign`,
`raw-int-magnitude`, and `-`. The purity scan now proves 17 core modules
(the purity-test and acceptance-test pins updated), and the boundary
classification counts nine readers. No tag, typed layer, literal, or
language export was added; the expander's pinned imports and exports are
unchanged. The full suite passed 6,663 assertions across all 33 test files.
`tests/int-test.rkt` covers sign/magnitude/reader round trips, all
negative-zero construction attempts, non-normalized magnitudes, constants,
zero testing, negation/absolute-value including zero results, and unary
arity.

### Step 33.2 — Add signed arithmetic and comparison

Status: complete (2026-09-01)

- [x] Adapt the useful `all_the_lambdas` Int algorithms for successor,
  predecessor, addition, subtraction, multiplication, equality, ordering,
  absolute value, and parity.
- [x] Route every result through the canonical Int constructor.
- [x] Test every combination of positive, negative, and zero operands, including
  operations whose mathematical result is zero.
- [x] Do not copy `all_the_lambdas`'s separate negative zero, division-by-zero-as-
  zero, or negative-integer-power-as-zero conventions.
- [x] Add only the private Int operations that Rat actually uses; do not create an
  unused public or typed Int library.

Acceptance: Rat has a complete signed numerator foundation, and every Int
answer is produced solely by pure untyped lambdas in one standard form.

Completion evidence: `core/int.rkt` adds succ, pred, add, sub, mult, equal,
the four orderings, odd, and even as raw curried operations. Same-sign
addition adds magnitudes; mixed-sign addition subtracts the smaller
magnitude from the larger under the larger operand's sign; subtraction adds
the negation; multiplication compares signs; ordering places negatives below
nonnegatives and reverses magnitude comparison between negatives; parity
reads the magnitude. Every arithmetic result routes through the canonical
constructor, and the 13×13 signed operand matrix in `tests/int-test.rkt`
verifies add/sub/mult/all comparisons against host integers, that every
zero-valued result carries the positive sign, successor and predecessor
across zero, sign-independent parity, nine-digit magnitudes, and unary
arity. The full suite passed 8,128 assertions across all 33 test files with the 17-module purity proof and zero-finding boundary inventory. No public or typed Int surface exists.

## Phase 34 — Add private canonical Rat arithmetic

### Step 34.1 — Add Rat construction and reduction

Status: complete (2026-09-01)

- [x] Add a private Rat representation consisting of an Int numerator and a
  positive binary Nat denominator.
- [x] Reject denominator zero as an invariant failure.
- [x] Reduce numerator and denominator by their greatest common divisor.
- [x] Force every zero result to positive `0/1`.
- [x] Add private selectors, constants, and a Rat reader for tests and human
  inspection.
- [x] Route every supported Rat construction through the same canonical
  constructor.

Acceptance: equal rational values have one stored representation, denominator
zero is never a value, and neither positive nor negative noncanonical zero can
escape construction.

Completion evidence: `core/rat.rkt` stores a raw pair of Int numerator and
positive normalized denominator; `raw-make-rat` normalizes the denominator,
divides both parts by their greatest common divisor, and routes the reduced
numerator through the canonical Int constructor, which automatically forces
every zero numerator to positive zero over denominator one. A zero
denominator is documented as an internal invariant failure exactly like a
zero raw-division divisor: it is never a value, and every supported entry
path must guard it before construction. `readers/rat.rkt` renders a
completed Rat as an exact host rational for tests only (reader vocabulary
extended by `rat->number`, the two selectors, and `/`; reader count now 10;
purity pins now 18 core modules). `tests/rat-test.rkt` checks the 13×9
construction grid against Racket's exact rationals with stored-part
verification, every zero spelling including negative and non-normalized
zeros, non-normalized denominators, the two constants, and unary arity. The full suite passed 8,507 assertions across all 34 test files with the 18-module purity proof and zero-finding boundary inventory.

### Step 34.2 — Add ordinary rational operations

Status: complete (2026-09-01)

- [x] Add pure negation, absolute value, addition, subtraction, and
  multiplication.
- [x] Add pure equality and ordering.
- [x] Add zero, whole-number, and nonnegative-whole-number checks.
- [x] Add floor with correct behavior for negative fractions and negative whole
  values.
- [x] Route every Rat result through canonical construction.
- [x] Reuse sound `all_the_lambdas` algorithms and test cases, but retain
  AttaLambda's existing binary arithmetic where it is already clearer or more
  efficient.

Acceptance: ordinary Rat operations are exact, reduced, have only positive
zero, and contain no Racket computation in their implementation path.

Completion evidence: `core/rat.rkt` adds negate, abs, add (cross-multiplied
over the product denominator), sub (add of negation), mult, equal (canonical
part comparison), the four orderings (signed cross-multiplication), is-zero,
is-whole (denominator one), is-nonnegative-whole, and floor (magnitude
division with a predecessor step for negative fractions carrying a nonzero
remainder); every Rat result routes through the canonical constructor. The
16×16 rational operand matrix in `tests/rat-test.rkt` — spanning negative
and positive fractions, wholes, zero, and 123456/7 — matches Racket's exact
rational arithmetic for all eight binary operations through the one-way
reader, with unary operations, floor denominators, canonical positive-zero
results, stored-part reduction checks, and unary arity all verified. The full suite passed 10,709 assertions across all 34 test files with the 18-module purity proof and zero-finding boundary inventory.

### Step 34.3 — Add rational division and powers

Status: complete (2026-09-01)

- [x] Add reciprocal and exact division with explicit zero checks.
- [x] Add whole-exponent rational powers using the private binary
  exponentiation-by-squaring operation.
- [x] Reject every fractional exponent rather than flooring it or attempting
  special perfect-root detection.
- [x] Support negative whole exponents through reciprocal.
- [x] Preserve `0^0 = 1`; reject zero raised to a negative exponent.
- [x] Test division by zero, reciprocal of zero, positive and negative exponents,
  odd and even powers of negative bases, fractional exponents that would and
  would not happen to yield rationals, and large exponents.

Acceptance: division and exponent failure are explicit, no operation silently
changes its mathematical question, and every successful answer is a canonical
Rat produced by pure lambdas.

Completion evidence: `raw-rat-recip` and `raw-rat-div` guard zero and return
raw Result values whose expected failure is the canonical DivideByZero
Error; `raw-rat-exp` rejects every non-whole exponent with the new
NonWholeExponent kind (13, numbered after the host-protocol and HTTP
kinds, added to errors and the error reader without renumbering), powers magnitudes through the private squaring
exponentiation, flips for negative whole exponents, keeps `0^0 = 1`, and
maps zero to a negative exponent to DivideByZero. The 16×16 division grid
and reciprocal sweep match Racket's exact division with kind-3 failures on
zero; power cases cover positive/negative/zero/fractional bases, odd and
even powers of negative bases, negative exponents through reciprocal,
(4/9)^(1/2) and (8/27)^(1/3) rejected despite having rational answers, and
exact large results including 2^200 and (3/2)^64. `tests/rat-test.rkt`
passes 3,184 assertions; the full suite passed 11,313 assertions across all 34 test files with the 18-module purity proof and zero-finding boundary inventory.

## Phase 35 — Replace the public Nat surface with Rat

Rat may exist privately during the early Steps in this Phase, but Nat and Rat
must never both be presented as public number types.

### Step 35.1 — Add the tagged Rat layer

Status: complete (2026-09-01)

- [x] Add the Rat type tag without changing the numeric identities of existing
  non-Nat tags.
- [x] Add strict Rat functions using the existing generalized checker unchanged.
- [x] Provide Rat implementations for `SUCC`, `ADD`, `SUB`, `MULT`, `DIV`, `EXP`,
  `EQ`, `LT`, `LTE`, `GT`, `GTE`, and `IS-ZERO`.
- [x] Add the approved public operations for negation, absolute value, reciprocal,
  floor, whole-number checking, and nonnegative-whole-number checking.
- [x] Make division, reciprocal, and exponentiation return `Result` where their
  expected arithmetic failures require it; keep wrong argument types as
  Error.
- [x] Keep this tagged Rat layer out of the `#lang attalambda` exports until the
  complete public switch.

Acceptance: the exact-tag checker handles Rat exactly as it handles every
other tag, with no numeric hierarchy, promotion logic, dispatcher, or new
checker form.

Completion evidence: `rat-type` is church-seven, leaving tags 0 through 6
untouched, and `readers/type-tag.rkt` renders it as `RAT`.
`core/typed-rat.rkt` builds all eighteen strict operations
(`typed-rat-succ` through `typed-rat-is-nonnegative-whole`) on the
unchanged generalized checker with the canonical function names `EXP`,
`RECIP`, `NEG`, `ABS`, `FLOOR`, `IS-WHOLE`, and `IS-NONNEGATIVE-WHOLE`
added to `core/function-names.rkt`; `DIV`, `EXP`, and `RECIP` keep their
already-typed Result, re-wrapping a successful raw payload as a tagged Rat.
`raw-rat-succ` joined the raw layer. Nothing is exported through the
language facade; the expander's pinned imports and exports are unchanged.
`tests/typed-rat-test.rkt` passes 690 assertions covering tagged results
across a 6×6 rational grid, all unary operations and checks, Ok and Err
Results for division/reciprocal/powers, exact `RAT` error frames on every
argument position, Error bubbling with appended frames, remaining-arity
absorption, and unary arity. Purity pins now prove 19 core modules; the full suite passed 12,004 assertions across all 35 test files with the zero-finding boundary inventory.

### Step 35.2 — Add Rat conversion and literal construction

Status: complete (2026-09-01)

- [x] Extend `runtime/codec.rkt` to translate exact Racket integers and fractions
  into canonical Rat values and translate Rat values back for approved host or
  reader use.
- [x] Add the production-free Rat reader support needed for human-readable tests
  and errors.
- [x] Reject inexact numbers rather than converting an approximate binary
  floating-point value into a surprising fraction.
- [x] Keep every arithmetic operation on an existing Rat inside the pure
  object-language modules. Racket may only decompose or construct the
  corresponding boundary representation deterministically.
- [x] Add boundary tests proving that no other production module imports or
  recreates these conversions.

Acceptance: exact source and boundary numbers can enter and leave AttaLambda
deterministically without granting Racket any role in Rat computation.

Completion evidence: `exact->object-rat` accepts only exact Racket rationals
(raising the standard contract error for `1.5`, `-0.0`, `1e3`, infinities,
NaN, and complex numbers) and builds the stored representation directly from
Racket's canonical reduced positive-denominator form, running no
object-language arithmetic; `object-rat->exact` validates the tag,
sign, magnitude, and denominator, rejecting forged unreduced parts, negative
or non-`0/1` zeros, zero denominators, and non-normalized bits as codec
failures before producing the exact host rational. The boundary gate's
pinned codec provide form and closed codec vocabulary were extended in the
same change, so any second production module recreating or importing these
conversions still fails the sole-importer and vocabulary rules; the
`readers/rat.rkt` observation support from Step 34.1 needed no production
change. Codec tests round-trip integers, fractions, negatives, zero, and a
2^200-magnitude value, and prove every rejection path. The full suite passed 12,061 assertions across all 35 test files with the 19-module purity proof and zero-finding boundary inventory.

### Step 35.3 — Prepare Rat-based List, String, and Char operations

Status: complete (2026-09-01)

- [x] Prepare `LEN` and `STRING-LENGTH` to return whole-valued Rat objects.
- [x] Prepare `TAKE`, `DROP`, and `MAKE-CHAR` to accept Rat and verify that it
  represents an allowed nonnegative whole number.
- [x] Keep their actual counting and indexing work on private binary Nat values.
- [x] Return clear Errors for negative or fractional counts and out-of-range Char
  values.
- [x] Keep the existing public Nat behavior active until the single public switch.

Acceptance: every core consumer of the current public Nat surface has a tested
Rat replacement ready without temporarily exposing two public number types.

Completion evidence: `typed-len-rat`, `typed-take-rat`, and `typed-drop-rat`
in `core/list-nat.rkt`, `typed-make-char-rat` in `core/chars.rkt`, and
`typed-string-length-rat` in `core/strings.rkt` are strict prepared variants
kept off the language surface. Lengths convert the existing raw binary List
counter to a whole Rat through the new `raw-whole-rat` helper; counts and
character codes validate `IS-NONNEGATIVE-WHOLE` in pure lambda computation
and then reuse the unchanged raw binary take/drop/range machinery through
`raw-rat-magnitude-bits`. A negative or fractional count is the new
INVALID-COUNT contract Error (kind 15, added to errors and the error
reader), rendered as `INVALID-COUNT\n  -> TAKE(result)` style
frames; an out-of-range code above 255 remains INVALID-CHAR. Focused tests
cover whole-Rat lengths for Lists and Strings, take/drop across zero,
partial, full, and beyond-length counts, all rejection paths, and unchanged
wrong-type mismatches, while every existing public Nat test still passes. The full suite passed 12,087 assertions across all 35 test files with the 19-module purity proof and zero-finding boundary inventory.

### Step 35.4 — Prepare Rat-based effect and host fields

Status: complete (2026-09-01)

- [x] Prepare ports, handles, backlog sizes, read limits, and other ordinary
  numeric fields to use Rat objects representing nonnegative whole numbers.
- [x] Check whole-number and range requirements in pure object-language code
  before an effect request reaches the host.
- [x] Convert validated Rat values at the existing deterministic codec boundary.
- [x] Keep tiny type tags, error kinds, host-operation codes, and argument
  positions as their separately allowed fixed Church numerals.
- [x] Keep existing public Nat requests active until the single public switch.

Acceptance: every runtime and effect dependency on public Nat has a tested Rat
replacement, while host authority and the codec exception remain no broader
than before.

Completion evidence: `effects/tcp.rkt` gains the six prepared `-rat` request
constructors and six prepared `-rat` wrapper factories. Ports, backlog
sizes, read limits, and opaque handles arrive as Rat objects; pure lambda
computation verifies `IS-NONNEGATIVE-WHOLE` before any request value
exists, so a negative or fractional field is an INVALID-COUNT Error carrying
the operation's function name and — proven by fake-host call counting — the
host is never applied. Valid requests carry tagged Rat numeric fields that
the Step 35.2 codec conversions decode deterministically at the boundary;
operation codes, error kinds, and argument positions remain fixed Church
numerals, and stdout/file wrappers have no numeric fields. The current
public Nat wrappers, the real host dispatcher, and the sole-bridge authority
are unchanged until the single switch (the real host's Rat decode/encode
swap is part of Step 35.5's prepared-path switch). The extended TCP suite
verifies exact decoded request shapes for all six operations, Ok
passthrough, force-once dispatch, INVALID-COUNT bubbling with zero host
calls, and ordinary strict RAT mismatches, passing 266 assertions. The full suite passed 12,161 assertions across all 35 test files with the 19-module purity proof and zero-finding boundary inventory.

### Step 35.5 — Perform the public switch

Status: complete (2026-09-01)

- [x] Change every accepted exact number literal to construct Rat.
- [x] Export the Rat operations through `#lang attalambda`.
- [x] Switch the prepared List, String, Char, effect, codec, and host paths to Rat.
- [x] Remove public Nat constants, typed functions, type tag, reader, language
  exports, and obsolete tests.
- [x] Retain and test only the private raw binary Nat machinery.
- [x] Update all current examples and documentation together without rewriting
  completed historical records.
- [x] Add a repository-wide check that fails if a public or production typed Nat
  surface is reintroduced.

Acceptance: users see exactly one number type, Rat; every existing numeric
consumer has its defined Rat behavior; and private Nat remains pure internal
machinery rather than a second public number system.

Completion evidence: the expander lowers every exact integer and fraction
datum (including negatives) to the canonical stored Rat representation and
rejects inexact and non-real datums with "only exact Rat and String literals
are supported"; the facade exports the eighteen Rat operations and no Nat
name. `core/typed-nat.rkt`, `readers/nat.rkt`, and `tests/typed-nat-test.rkt`
are deleted; tag 3 is retired from `core/tags.rkt` and renders as `TYPE:3`;
`ZERO` through `TEN` are gone (chars, list-nat, and the HTTP modules build
their private magnitudes from raw bits). The prepared paths switched
together: LEN/TAKE/DROP/MAKE-CHAR/STRING-LENGTH are the Rat variants, the
six TCP wrappers are the Rat versions carrying tagged Rat request fields,
`effects/protocol.rkt` validates canonical nonnegative-whole Rat fields
purely, HTTP statuses are whole Rats with a Rat renderer signature, the
codec dropped its Nat conversions, and the host decodes bounded counts with
`object-rat->exact` and returns handles via `exact->object-rat`. During the
switch a latent kind collision was found and fixed: the Step 34.3/35.3 kinds
had reused Church 7 and 8, which already belong to the host protocol, so
NON-WHOLE-EXPONENT and INVALID-COUNT are now kinds 14 and 15, numbered after
the host, HTTP, and HTTP-server kinds (a second miscount — starting them at
13, which the HTTP server already owned — was found by the pre-release
branch review and fixed in commit fb96dea). The boundary gate gained
`reintroduced-nat-surface`, a repository-wide scan that fails if any
production source mentions a retired Nat spelling, and its pinned expander
forms, codec provide, and codec/host/reader/expander vocabularies moved with
the switch. `examples/http-server.attl` now floors its decimal-digit
quotients under exact division. Twenty-two test files were updated
(canonical literal representation, `expected RAT` frames, tag 7
expectations, exact-division semantics, forged-Rat host defenses); the full
suite passed 11,705 assertions across all 34 test files with the 18-module
purity proof and the zero-finding boundary inventory including the new
reintroduction check.

## Phase 36 — Add Unit

### Step 36.1 — Add Unit and use it where “nothing” is the answer

Status: complete (2026-09-01)

- [x] Add one Unit type with exactly one value, `UNIT`.
- [x] Add its reader and public export.
- [x] Change successful stdout, file-write, TCP-write, TCP-close, and related
  server operations from `Ok NIL` to `Ok UNIT`.
- [x] Preserve `NIL` wherever an actual empty List is the answer.
- [x] Implement Unit construction, checking, propagation, and effect use entirely
  with pure object-language lambdas; the host may only return its encoded
  value through the existing codec boundary.
- [x] Add effect, host, reader, error, laziness, purity, and boundary tests.

Acceptance: Unit carries successful no-value results, NIL means only an empty
List, and neither the type nor its effect integration broadens host authority.

Completion evidence: `core/unit.rkt` defines `UNIT` as the single
`unit-type` (church-eight, tag 8) value over one fixed raw payload, exported
through the facade; the codec exposes the same canonical value as
`object-unit`, and the host's four no-value acknowledgements (stdout,
file write, TCP write, TCP close) return `Ok(UNIT)` instead of `Ok(NIL)`
with the host's `NIL` import removed entirely. `readers/unit.rkt` renders
the type name one way. The pinned expander forms, codec provide, and
codec/host/reader vocabularies, the reintroduction-safe boundary gate, the
19-module purity pins, and the ten-reader classification all moved in the
same change. `tests/unit-test.rkt` proves the tag, distinctness from NIL,
false, zero, and every other public type, the reader, the codec value, the
Ok(UNIT) acknowledgement shape, NIL's List meaning, and lazy payload
handling, while the stdout, files, host, TCP-host, TCP, and HTTP-server
suites now assert tag-8 payloads for every successful no-value result. The
full suite passed 11,720 assertions across all 35 test files with the
zero-finding boundary inventory.

## Phase 37 — Add Byte and distinguish binary data from text

### Step 37.1 — Add Byte

Status: complete (2026-09-01)

- [x] Add Byte values from 0 through 255, internally backed by private binary Nat
  magnitudes.
- [x] Add construction from a nonnegative whole Rat, conversion back to Rat,
  equality, and ordering.
- [x] Reject negative, fractional, and over-255 inputs.
- [x] Ensure ordinary Rat arithmetic rejects Byte.
- [x] Add Byte reader, type, invariant, error, purity, and public-language tests.

Acceptance: Byte is a distinct pure data type with exactly 256 valid values,
not a second numeric type or a host byte hidden inside an object.

Completion evidence: `core/byte.rkt` defines Byte as tag 9 (church-nine)
over private normalized magnitudes. `MAKE-BYTE : Rat -> Byte` validates
`IS-NONNEGATIVE-WHOLE` and the 255 bound purely, rejecting every other
value as the new InvalidByte Error (kind 16, rendered `INVALID-BYTE`);
`BYTE-VALUE : Byte -> Rat` returns the whole Rat; `BYTE-EQ` through
`BYTE-GTE` compare magnitudes through the unchanged checker. All seven
operations are facade exports with pinned forms, vocabularies, 20-module
purity pins, and the eleven-reader classification updated together.
`tests/byte-test.rkt` passes 210 assertions covering boundary construction,
round trips, every rejection class, Rat arithmetic rejecting Byte with
`ADD(arg1 expected RAT got BYTE)`, host-agreement of all comparisons, and
unary arity. This step also root-caused and fixed a concurrency defect the
Rat/Unit work exposed: `tests/tcp-host-test.rkt` forced Lazy Racket values
from two threads at once (a worker blocked mid-force in a wrapper read while
the main thread forced wrapper writes), and Racket promises are not
thread-safe, so runs failed intermittently with "force: reentrant promise" —
about half the time after the switch widened the forcing windows, versus a
stable pre-switch baseline reproduced 6/6 in a worktree. The suite now keeps
every lambda force on one thread and drives concurrency through a raw
Racket loopback peer socket (the pattern the HTTP suites already use for
test-side clients); ten consecutive runs pass. The full suite passed 11,860
assertions across all 36 test files with the zero-finding boundary
inventory.

### Step 37.2 — Add pure String and byte-sequence conversion

Status: complete (2026-09-01)

- [x] Represent a byte sequence as `List Byte`; add no Bytes tag or host-backed
  byte collection.
- [x] Add pure conversions between String and `List Byte`.
- [x] Validate every List element rather than assuming that any List is a byte
  sequence.
- [x] Implement traversal, validation, and element conversion entirely with
  object-language lambdas.
- [x] Test empty, ordinary text, every boundary byte, embedded zero, invalid List
  elements, laziness, and Error propagation.

Acceptance: AttaLambda can explicitly cross between text and binary data
without using Racket to walk, validate, or transform an object-language List.

Completion evidence: `STRING-TO-BYTES : String -> List` maps one Byte per
Char with the existing pure `raw-map`, and `BYTES-TO-STRING : List ->
String` walks the List validating each element's Byte tag before any
conversion, rejecting a non-Byte element as
`INVALID-BYTE\n  -> BYTES-TO-STRING(result)`. Both are strict facade
exports built on the unchanged checker with pinned forms updated. Tests
cover ABC text, empty values in both directions, the boundary bytes
0/1/127/128/255 with an embedded zero round-tripping byte-exactly,
non-Byte and Char elements rejected, wrong argument types, incoming Error
bubbling, unary arity, and validation stopping at the first bad element
without examining a divergent later element. The full suite passed 11,875 assertions across all 36 test files with the 20-module purity proof and zero-finding boundary inventory.

### Step 37.3 — Move file contents to `List Byte`

Status: complete (2026-09-01)

- [x] Keep filesystem paths as String.
- [x] Make file reads return `Result Ok(List Byte)`.
- [x] Make file writes accept `List Byte` and return `Result Ok(Unit)`.
- [x] Extend only the deterministic codec conversions and existing host operation
  needed to exchange external bytes.
- [x] Keep all object-language List and Byte validation in pure lambdas before the
  host call.
- [x] Update file examples, fake hosts, real-host tests, failures, purity checks,
  and boundary checks together.

Acceptance: arbitrary file bytes round-trip exactly, text and binary data are
no longer conflated, and the host gains no object-language computation.

Completion evidence: `write-file : String -> List -> Result` validates the
byte List purely (`raw-byte-list-valid?`) before any request value exists,
so a non-Byte element is an INVALID-BYTE Error with no host call; the
protocol schema's second write field is a byte-List rule validating each
element's tag and canonical bit payload; the codec gained only
`object-byte-list->bytes` and `bytes->object-byte-list`; and the host's
read path returns `Ok(List Byte)` while its write dispatch decodes the
byte List deterministically. Rebuilding a List object from a
checker-unwrapped payload now restores the one canonical `NIL` for the
empty case — found when an empty write crashed because the codec's
forged-terminator hardening correctly rejected a structurally-empty but
non-canonical rebuilt terminator. `examples/file-round-trip.attl` converts
explicitly with `STRING-TO-BYTES`/`BYTES-TO-STRING`. Fake-host traces,
real-host round trips (binary, empty, replacement, UTF-8 relative paths,
symlink truncation, denied and synthetic failures), the four-field arity
probe, and the design-document amendment moved together. The full suite passed 11,877 assertions across all 36 test files with the 20-module purity proof and zero-finding boundary inventory.

### Step 37.4 — Move TCP and HTTP boundaries to `List Byte`

Status: complete (2026-09-01)

- [x] Make TCP read and write use `List Byte` and make successful writes return
  `Result Ok(Unit)`.
- [x] Keep pure HTTP parsing and rendering text-oriented by converting explicitly
  at the TCP boundary.
- [x] Preserve binary HTTP bodies without treating arbitrary bytes as text.
- [x] Update the HTTP server, protocol validation, host conversion, fake hosts,
  real loopback tests, examples, purity checks, and boundary checks together.

Acceptance: network payloads are explicit byte lists, HTTP remains pure, and
no Racket string, byte sequence, parser, or branch decides an object-language
HTTP result.

Completion evidence: `tcp-write` takes a `List Byte` validated purely
(canonical-NIL rebuild included) before any request exists, with the
protocol's write schema on the shared byte-List rule; `tcp-read` returns
`Ok(List Byte)` with EOF as the empty List; successful writes were already
`Ok(UNIT)`. The HTTP server converts exactly at the boundary — received
bytes become Chars one-to-one before the pure parser runs, and the rendered
response String becomes bytes one-to-one before `tcp-write` — so parsing,
routing, and rendering remain text-oriented lambda computation and binary
bodies survive byte-exactly. Fake-host scripts, trace decoders, the raw-peer
loopback suite, and the real end-to-end HTTP example all moved together;
the milestone-two acceptance run serves the example over the byte-List
boundary. The full suite passed 11,877 assertions across all 36 test files
with the 20-module purity proof and zero-finding boundary inventory.

## Phase 38 — Add Option

### Step 38.1 — Add Some and None

Status: complete (2026-09-01)

- [x] Add `SOME value` and the singleton `NONE` as the two Option forms.
- [x] Add checks for Some and None and a lazy pure operation that chooses what to
  do in either case.
- [x] Let Some contain any non-Error object-language value without adding an
  `Any` tag or changing the generalized checker.
- [x] Propagate an early Error rather than hiding it inside Some.
- [x] Keep Option distinct from Result: None means expected absence, while
  `Result Err` means a computation failed.
- [x] Add reader, representation, branch-laziness, Error-propagation, purity, and
  public-language tests.

Acceptance: expected absence has a small pure representation and cannot be
confused with failure, false, zero, NIL, or Unit.

Completion evidence: `core/option.rkt` mirrors the Result shape at tag 10
(church-ten). `SOME` accepts any non-Error value and bubbles an Error
argument; `NONE` is the singleton; `IS-SOME`/`IS-NONE` are strict Bool
checks on the unchanged checker; `OPTION-CASE option some-function
none-value` is the lazy polymorphic eliminator, strict on its Option with
`OPTION-CASE(arg1 expected OPTION ...)` frames and no evaluation of the
unselected branch. All five names are facade exports with pinned forms,
vocabularies, 21-module purity pins, and the twelve-reader classification
updated together; `readers/option.rkt` renders SOME/NONE one way. Tests
cover representation tags for Some over Rat/Bool/NIL/nested-Option values,
strict checks, distinctness from Bool/List/Rat/Error/Unit, Error
propagation, both laziness directions, mismatch and bubbling frames, and
unary arity. The full suite passed 11,911 assertions across all 37 test
files with the zero-finding boundary inventory.

## Phase 39 — Add persistent Map

A persistent Map returns a new Map after setting or removing an entry and
never alters the old Map.

### Step 39.1 — Add Map representation and lookup

Status: complete (2026-09-01)

- [x] Construct a Map with a user-supplied pure object-language key-equality
  function.
- [x] Store entries as a private object-language List of Pairs, never as a Racket
  list, association list, hash table, dictionary, struct, or mutable value.
- [x] Add empty, lookup, and reader behavior.
- [x] Make lookup return `SOME value` or `NONE`.
- [x] Check that the supplied equality function returns Bool; otherwise return a
  structured Error.
- [x] Implement every search and branch with pure unary lambdas.

Acceptance: lookup works for user-defined key equality, expected absence uses
Option, and no host collection or host equality participates.

Completion evidence: `core/map.rkt` (tag 11, church-eleven) pairs the fixed
equality function with a raw Pair-entry List. `MAKE-MAP` bubbles Error
arguments; `MAP-EMPTY?` and `MAP-SIZE` (whole Rat via the raw List counter)
use the unchanged checker; `MAP-LOOKUP` validates its Map argument manually
(the `IF`/`OPTION-CASE` polymorphic pattern), bubbles an Error key with a
result frame, and walks entries with the Map's own equality function,
returning `SOME value` or `NONE`. A comparison answering an Error bubbles
with the operation's frame; any other non-Bool answer renders as
`MAP-LOOKUP(arg1 expected BOOL got …)`. All four names are facade exports
with pinned forms, vocabularies, 22-module purity pins, and the
thirteen-reader classification updated together; `readers/map.rkt` renders
the entry count. Tests cover empty and populated lookup under Rat equality,
both malformed-equality answers, wrong and Error Map/key arguments, size
and emptiness, and unary arity. The full suite passed 11,935 assertions
across all 38 test files with the zero-finding boundary inventory.

### Step 39.2 — Add Map updates and queries

Status: complete (2026-09-01)

- [x] Add pure set, remove, contains, empty, and size operations.
- [x] Replace an existing key without creating a duplicate entry.
- [x] Return size as a whole-valued Rat.
- [x] Accept arbitrary non-Error keys and values without adding an `Any` tag or
  changing the generalized checker.
- [x] Prove that an older Map still returns its older answers after a new Map is
  produced from it.
- [x] Test Rat, String, Char, and Byte equality functions, collisions under a
  custom equality function, missing keys, replacement, removal, size, Error
  propagation, partial application, and laziness.

Acceptance: Map is useful, immutable, and entirely lambda-built; Unit values
can represent set membership without adding a Set type.

Completion evidence: `MAP-SET` replaces a matched key in place (no
duplicate entry) or prepends an absent one, `MAP-REMOVE` of an absent key
returns an equivalent Map, and `MAP-CONTAINS?` answers Bool — all built on
the shared find/walk machinery whose mid-walk comparison failure becomes
the whole answer instead of hiding inside a rebuilt List. Error keys and
values bubble with the operation's frame. During this step MAKE-MAP's
former Error-bubbling probe was removed as unsound: applying a tag check
to an arbitrary supplied function is undefined under the closed strict
convention, so the constructor accepts the function as-is and the Bool
contract is enforced at every comparison. Tests build a three-entry Rat
map through replacement and removal while proving every older Map keeps
its older answers, drive String/Char/Byte equality functions, prove
deliberate collisions under an always-true equality collapse to one
entry, and cover contains, Error propagation, wrong-Map mismatches,
mid-walk failure, unary partial application, and update laziness. The
full suite passed 11,970 assertions across all 38 test files with the
22-module purity proof and zero-finding boundary inventory.

## Phase 40 — Milestone acceptance

### Step 40.1 — Prove the complete language together

Status: complete (2026-09-01)

- [x] Add end-to-end standalone examples covering negative fractions, exact
  division, powers, Unit effect results, binary file and TCP data, Option, and
  Map.
- [x] Re-run the complete structural purity proof and boundary inventory so every
  new production file is classified and checked.
- [x] Verify mechanically that every production object-language computation
  expands to variables, unary `lambda`, and application only.
- [x] Verify that no public Nat or Int type, literal, function, reader, tag, or
  export remains.
- [x] Verify that no Racket arithmetic, conditional, collection, mutation, or
  equality operation decides an Int, Rat, Unit, Byte, Option, or Map result.
- [x] Run the complete source suite, supported Linux distribution build, and
  no-Racket Linux consumer test.
- [x] Update current documentation and examples, distinguish observed behavior
  from future possibilities, and record honest performance limits.
- [x] Leave the version at `0.3.0-dev`; release preparation, signing, artifact
  publication, tagging, and public claims require a later separate plan and
  explicit approval.

Acceptance: AttaLambda exposes Rat as its sole number type plus Unit, Byte,
Option, and Map; all underlying definitions and computation remain pure
untyped lambda calculus; Racket remains confined to the same narrow mechanical
and external-world seams; and the complete source and supported-distribution
verification passes.

Completion evidence: `examples/foundations.attl` prints nine deterministic
`ok` lines through the real runner — negative fractions, exact division,
whole powers with negative exponents, floor, a Unit stdout acknowledgement,
byte/text crossing, Option over a Map lookup, and Map persistence — and is
threaded through the boundary inventory, every build script, and every
platform consumer contract; the existing file and HTTP examples cover the
binary file and TCP boundaries. The full suite passed 11,974 assertions
across all 38 test files with the 22-module expanded purity proof (unary
lambda and forbidden-form verification over every production module) and
the zero-finding boundary inventory including the `reintroduced-nat-surface`
scan; retired spellings fail to resolve in the fresh-install language
tests. The supported Linux distribution built from a clean clone of commit
`a1f125b` under the pinned Racket CS 9.3 toolchain in a container:
`attalambda-0.3.0-dev-linux-x86_64.tar.gz`, SHA-256
`0261fcc7e05807f220e5c96ea32feea972c4ca895cd02a32bed947de3ce7c860`,
13,939,568 compressed bytes, 59,742,222 unpacked regular-file bytes, 11
files, 2 runtime files, with only the ELF loader, `libc`, `libdl`, `libm`,
`libpthread`, and `librt` as system-library assumptions. The independent
no-Racket consumer script verified the external checksum, confirmed absent
`racket`/`raco` commands and loopback-only network, ran the complete
end-user guide workflow, and passed relocation, reporting
`consumer_acceptance=passed` with 298 ms first startup and 280 ms after
relocation. These are internal development observations of an unpublished
artifact, not a release; `VERSION` remains `0.3.0-dev`, and release
preparation, tagging, signing, publication, and public claims require a
later separate plan and Kyle's explicit approval. `docs/ACCEPTANCE.md`
carries the Milestone 4 criterion map and honest performance limits
(gcd-reducing interpreted arithmetic, linear Map walks, the documented
HTTP re-parse bound).
