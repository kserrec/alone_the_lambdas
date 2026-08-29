# AttaLambda

AttaLambda is a greenfield language project pursuing the most faithful
pure untyped lambda calculus that remains practical for real programs. It uses
Racket's lazy evaluator as a host while keeping object-language computation to
variables, unary lambdas, and application.

> **Status:** The core-language and effects-and-standalone milestones are
> complete. The lambda-only
> foundation now includes all seven tagged data types, explicit Lists,
> scalable binary Nat arithmetic, strict Bool and Nat operations, Result,
> Char, String, and one generalized curried runtime checker. Structured Errors
> preserve their root cause and accumulate canonical function-name Strings in
> propagation frames; a one-way reader renders those frames as human-facing
> diagnostics. The full acceptance suite and structural purity gate are
> green. The approved Phase 13
> [host-boundary design](docs/design/host-boundary.md) is fully implemented:
> Phase 14 adds exact String-byte conversion, one unary `host`, and
> pure injected-host `stdout`; Phase 15 adds pure `read-file`/`write-file`
> wrappers and byte-exact whole-file effects; Phase 16 adds pure blocking TCP
> wrappers, canonical Nat/host-integer conversion, and a private listener and
> connection registry inside that same closed host; Phase 17 adds pure HTTP/1.1
> request parsing and deterministic response rendering without changing the
> host; Phase 18 adds pure path routing, one-connection serving, and a blocking
> sequential HTTP loop over the same TCP wrappers; Phase 19 added the
> fresh-installable standalone reader and facade, canonical
> public syntax, host-bound effect names, and pure Nat/String literal lowering;
> Phase 20 adds runnable stdout, isolated file-round-trip, and ephemeral-port
> HTTP applications plus the final cross-class and milestone acceptance sweep.
> Phase 21 then approved the original independent-distribution contract and
> proved the Racket 9.3 embedding path; Phase 22 added the separately trusted
> development runner and the `0.2.0-dev` product
> version source; Phase 23 freezes concise AttaLambda launch diagnostics, strict
> source encoding, original-path/source-position reporting, and stable failure
> statuses without changing the object language or its host authority; Phase
> 24 added a deterministic, self-contained Linux x86-64 development archive and
> proved it in a transferred no-Racket Ubuntu container; Phase 25 added native
> Intel and Apple Silicon macOS development archives and proves each in a
> separate same-architecture no-Racket consumer job before immediately
> deleting the temporary transfer artifacts; Phase 26 did the same for native
> Windows x86-64. Those observations retain their literal pre-rename artifact
> names as history. Phase 27 approved Apache License 2.0 and completed the
> `AttaLambda`, `attalambda`, `.attl`, `#lang attalambda`, and direct
> `attalambda FILE.attl` rename across the project, then revalidated all four
> renamed native archives in independent no-Racket consumers and deleted the
> three temporary cross-job artifacts immediately. For Phase 28, the complete
> bundled-runtime notice set, implementation scope, and temporary native
> artifact transfer received explicit approval. Candidate commit `91ba3a9`
> then passed all four native builds and independent no-Racket, guide-driven
> consumers; the three temporary cross-job artifacts were deleted
> immediately. Phase 29 promoted the source and archive contract to final
> version `0.2.0`; commit `42ff0a7` passed all four native builders and clean
> consumers, the three approved temporary artifacts were verified into local
> staging and deleted, and ordinary immediate cleanup was restored. The
> separately approved unsigned annotated tag `v0.2.0` and public latest
> non-prerelease [AttaLambda 0.2.0 release](https://github.com/kserrec/attalambda/releases/tag/v0.2.0)
> now publish those exact four archives and `SHA256SUMS`; all five public files
> were anonymously downloaded and verified byte-for-byte after publication.
> Separate structural gates enforce every boundary class. See
> [PLAN.md](PLAN.md) for the completed core build and the
> effects-and-standalone roadmap, and
> [docs/ACCEPTANCE.md](docs/ACCEPTANCE.md) for criterion-by-criterion evidence.

## Download, verify, extract, and run

AttaLambda `0.2.0` is the first independently runnable release. Its
authoritative public distribution is the
[AttaLambda 0.2.0 GitHub Release](https://github.com/kserrec/attalambda/releases/tag/v0.2.0),
which supplies all four archives and their sibling `SHA256SUMS`. The five
manually uploaded files were anonymously downloaded and verified
byte-for-byte against the tested staging files after publication. Archive
users do not install Racket, run `raco`, or register a package.

Choose the archive matching the computer that will run it:

| Computer | Archive |
| --- | --- |
| Linux x86-64 | `attalambda-0.2.0-linux-x86_64.tar.gz` |
| macOS Intel | `attalambda-0.2.0-macos-x86_64.tar.gz` |
| macOS Apple Silicon | `attalambda-0.2.0-macos-arm64.tar.gz` |
| Windows x86-64 | `attalambda-0.2.0-windows-x86_64.zip` |

Keep the archive and `SHA256SUMS` in the same directory. On Linux x86-64:

```sh
awk '$2 == "attalambda-0.2.0-linux-x86_64.tar.gz" { print }' SHA256SUMS | sha256sum -c -
tar -xzf attalambda-0.2.0-linux-x86_64.tar.gz
cd attalambda-0.2.0-linux-x86_64
./bin/attalambda --version
./bin/attalambda examples/hello.attl
```

On macOS Intel:

```sh
awk '$2 == "attalambda-0.2.0-macos-x86_64.tar.gz" { print }' SHA256SUMS | shasum -a 256 -c -
tar -xzf attalambda-0.2.0-macos-x86_64.tar.gz
cd attalambda-0.2.0-macos-x86_64
./bin/attalambda --version
./bin/attalambda examples/hello.attl
```

On macOS Apple Silicon:

```sh
awk '$2 == "attalambda-0.2.0-macos-arm64.tar.gz" { print }' SHA256SUMS | shasum -a 256 -c -
tar -xzf attalambda-0.2.0-macos-arm64.tar.gz
cd attalambda-0.2.0-macos-arm64
./bin/attalambda --version
./bin/attalambda examples/hello.attl
```

On Windows x86-64 PowerShell:

```powershell
$archive = 'attalambda-0.2.0-windows-x86_64.zip'
$line = @(Get-Content .\SHA256SUMS | Where-Object { $_ -like "*$archive" })
if ($line.Count -ne 1) { throw 'checksum entry mismatch' }
$expected = ($line[0] -split '\s+')[0]
$actual = (Get-FileHash ".\$archive" -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -cne $expected) { throw 'SHA-256 mismatch' }
Expand-Archive -LiteralPath ".\$archive" -DestinationPath .
Set-Location .\attalambda-0.2.0-windows-x86_64
.\bin\attalambda.exe --version
.\bin\attalambda.exe examples\hello.attl
```

Successful execution prints `AttaLambda 0.2.0` and
`Hello from AttaLambda.`. The archive's
`GETTING_STARTED.md` then explains `.attl` source syntax, exit statuses,
runtime authority, release notes, and exact known limitations.

## Commitments

- Every ordinary object-language function is a chain of one-argument lambdas.
- Core representations and algorithms contain no host-language data or
  computation; pure effect wrappers can invoke only an injected unary host.
- Racket is limited to modules, lazy evaluation, mechanical macros, readers,
  tests, tooling, deterministic boundary conversion in `runtime/codec.rkt`,
  the one approved privileged bridge in `runtime/host.rkt`, and the isolated
  command/path/module-loading scaffolding in `runner/attalambda.rkt`.
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
- The standalone language exports canonical `lambda`, `def`, `let`, `if`, and
  `cons`; Racket collision workarounds, raw operations, typed implementation
  names, and ordinary Racket bindings remain private.
- The completed core contains no `host` boundary. The effects milestone adds
  exactly one explicit bridge without weakening ordinary lambda computation.

## Specifications

The repository preserves the complete design inputs in
[docs/specifications](docs/specifications/README.md). The addenda take
precedence over conflicting examples in the base specification.

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) records the language boundary, verified
  layers, representations, and dependency direction.
- [docs/ACCEPTANCE.md](docs/ACCEPTANCE.md) maps the completed core and effects
  phases to executable or structural evidence.
- [docs/design/host-boundary.md](docs/design/host-boundary.md) fixes the
  approved second-milestone protocol, authority, codecs, and purity
  classifications; Phases 14 through 20 implement and accept its `stdout`,
  file, TCP, pure HTTP-message/server, standalone-language, and runnable-
  application slices.
- [docs/design/standalone-distribution.md](docs/design/standalone-distribution.md)
  fixes the approved `.attl`, runner, version, artifact, platform, and release
  contracts for the independent-distribution milestone.
- [PLAN.md](PLAN.md) divides both milestones into ordered, testable phases.
- [AGENTS.md](AGENTS.md) contains the project-specific implementation rules
  every contributor and coding agent must follow.

## Implemented foundation

- `macros/lazy-with-macros.rkt` provides the minimal Lazy Racket module shell.
- `macros/macros.rkt` provides arbitrary-arity curried `def` and the internal
  `lambda-let` sugar exported by the standalone facade as `let`. It also
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
- `effects/http.rkt` provides a pure strict parser for the minimal `GET`
  request subset plus the shared fixed message bytes and Error-kind sequence.
- `effects/http-response.rkt` separately provides the pure deterministic
  renderer for 200, 400, 404, and 500 responses with byte-accurate decimal
  content lengths and connection-close framing.
- `effects/http-server.rkt` composes only the pure HTTP modules and injected-
  host TCP wrappers. It provides a unary path handler factory, one-connection
  serving over a caller-owned listener, and a blocking sequential loop that
  closes every accepted connection.
- `runtime/codec.rkt` performs exact deterministic conversion between lambda
  Lists/Chars/Strings/Nats/Results and private host bytes, integers, and
  temporary collections, with no operating-system effects or mutation.
- `runtime/host.rkt` alone defines the privileged `host` and is its direct
  producer export; the standalone facade re-exports that same binding once.
  Its Phase 16 dispatcher
  accepts only the approved stdout, whole-file, and six blocking TCP requests,
  owns the private monotonic handle registry, normalizes external failures,
  and returns canonical Result/Error values without exposing ports or host
  collections.
- `VERSION` is the sole product-version source and currently contains
  `0.2.0`; `info.rkt` declares the single `attalambda` collection and carries
  its mechanically verified Racket-package projection `0.2`.
- `lang/reader.rkt` retains Racket's Lisp reader syntax and selects the
  standalone expander without adding a parser or reader-time effect.
- `lang/expander.rkt` exposes the canonical language surface, mechanically
  curries multi-operand applications, restricts `lambda` to one argument,
  lowers only nonnegative Nat and UTF-8 String literals into pure existing
  encodings, binds the nine public effect wrappers once to the real `host`,
  and suppresses Racket printing of final lambda values.
- `runner/attalambda.rkt` implements only direct `.attl` execution, `--help`,
  and `--version`. It validates the one explicit `.attl`
  path, declaration, and UTF-8 bytes; delegates once to the existing
  reader/expander with `dynamic-require`; and emits only fixed AttaLambda diagnostics
  with the quoted original path and canonical source position. It exports no
  binding and cannot enter an object-language dependency path.
- `tooling/build-linux-distribution.sh` verifies full Racket CS 9.3, stages the
  package under an isolated Racket user home, embeds dynamic `#lang` support,
  runs `raco distribute`, and emits a normalized Linux archive plus external
  `SHA256SUMS` outside the checkout without modifying the developer's package
  registry.
- `tooling/test-linux-distribution.sh` transfers only that archive, checksum,
  and its consumer harness into a pinned nonroot, read-only Ubuntu container
  with no Racket command and no external network, then proves CLI, arbitrary
  source, stdout, file, loopback HTTP, embedded-reader precedence, and
  relocation behavior.
- `tooling/build-macos-distribution.sh` applies the same isolated Racket CS 9.3
  contract on native Intel and Apple Silicon runners, verifies every Mach-O
  architecture and dynamic dependency, and emits normalized versioned
  `.tar.gz` archives with external checksums.
- `tooling/test-macos-distribution.sh` is the self-contained clean-consumer
  harness. Separate native jobs receive only one archive, its checksum, and
  this harness; with no Racket command or checkout they prove exact CLI,
  arbitrary-source, stdout, file, loopback HTTP, embedded-reader precedence,
  and relocation behavior. The one explicitly approved Phase 29 staging run
  retained both temporary transfer artifacts only until their exact tested
  bytes were downloaded locally, then deleted them through the GitHub API;
  one-day retention was the failure fallback. Ordinary `always()` cleanup is
  restored for future runs.
- `distribution/` contains the platform-expanded novice guide, the exact
  approved bundled-runtime notice text, and the retired development-warning
  input retained as historical implementation evidence. Final release
  builders package the repository `LICENSE` and approved notices, never the
  development warning.
- `examples/hello.attl`, `examples/stdout.attl`,
  `examples/file-round-trip.attl`, and `examples/http-server.attl` are the exact
  runnable language programs. The HTTP program uses an ephemeral loopback
  port, prints its URL, serves one request, closes its caller-owned listener,
  and exits.
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
  modules, the package metadata, the standalone reader and expander, pure
  effect and HTTP-message/server modules, deterministic codec conversion, the
  exact sole-host import/export path, and the unchanged closed stdout,
  whole-file, and five-binding `racket/tcp` capability set. It rejects wrapped
  privileged imports, every second production filesystem/TCP importer,
  authorizes imports before reading their exports, validates every project-root
  and production-path component before discovery, rejects symlinks without
  traversing their targets, rejects additional macro/language modules, and
  permits only the facade's exact import and re-export of production `host`.
  It also pins the product/package version projection, the non-exporting
  runner's exact imports, diagnostic formatter, UTF-8 preflight, and closed
  vocabulary, its sole validated loader call, and the four-file application
  inventory. Its repository-wide
  inventory classifies all 80 Racket and `.attl` sources: readers may
  observe through a closed source vocabulary but cannot perform effects or
  import upward; tests and tooling retain normal host authority but cannot
  enter a production dependency path; standalone examples must use the public
  language; and unknown source locations fail closed.

## Contributor setup

This section is for contributors working from source; archive users do not
need it. From a new checkout, this command registers and compiles the
collection in the current Racket user installation. It changes that user-level
package registry but does not require administrator privileges:

```sh
raco pkg install --auto --name attalambda .
```

The package declares only Racket's `base` and `lazy` runtime packages, plus
`rackunit-lib` and `net-lib` for tests. There is no third-party dependency.

## Contributor runnable applications

Every application uses only `#lang attalambda` and the public language
surface. Programs run with the real `host` have the same relevant stdout,
filesystem, and network permissions as their launching Racket process, so
inspect and trust a program before running it.

Phases 24 through 27 proved native development artifacts and the current
AttaLambda names. Phase 28 promoted the source to `0.2.0-rc.1`, installed the
approved runtime notices and novice guide, and validated four unpublished
candidates. Phase 29 staged the final `0.2.0` archives, then a separate exact
approval authorized and produced the unsigned annotated `v0.2.0` tag and
public Release with only those four archives and `SHA256SUMS`. After the
contributor setup above, invoke the source-checkout development entry point
through Racket.

The minimal hello application emits one line:

```sh
racket runner/attalambda.rkt examples/hello.attl
```

The stdout application has no side effect beyond these emitted bytes:

```sh
racket runner/attalambda.rkt examples/stdout.attl
```

The file application creates or truncates
`attalambda-round-trip.txt` in its current directory. This invocation
runs it in a newly created empty temporary directory, so it cannot replace an
existing project file:

```sh
repository_directory="$(pwd)"
scratch_directory="$(mktemp -d)"
(
  cd "$scratch_directory"
  racket "$repository_directory/runner/attalambda.rkt" \
    "$repository_directory/examples/file-round-trip.attl"
)
```

The HTTP application binds an operating-system-selected loopback port, prints
the exact `/lambda` URL, serves one request, closes the listener, and exits:

```sh
racket runner/attalambda.rkt examples/http-server.attl
```

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

Run only the complete repository boundary-classification scan with:

```sh
racket tooling/check-boundaries.rkt
```

Each implementation phase adds focused tests and must leave the complete suite
green. The repository currently has 4,751 assertions across 32 test files,
plus the independent expanded scan of all 16 core modules and the complete
repository boundary-classification gate. The application acceptance test
installs a copied package under an isolated Racket user home before running
the exact three effect examples through the copied runner; the focused runner
suite separately covers `hello.attl`, the complete command/source contract,
and explicit rejection of the retired public spellings.
GitHub Actions runs the same suite for pushes and pull requests.

Development happens directly on `main`. Commit and push after each meaningful
phase.

## License

Copyright 2026 Kyle Serrecchia.

AttaLambda is licensed under the [Apache License 2.0](LICENSE). Bundled Racket
runtime components retain the exact separately approved terms in
[`distribution/THIRD_PARTY_NOTICES.md.in`](distribution/THIRD_PARTY_NOTICES.md.in).
Source version `0.2.0` and construction of final archives did not themselves
authorize a public download. The separately approved `v0.2.0` Git tag,
GitHub Release, and five exact release assets constitute the current
publication.
