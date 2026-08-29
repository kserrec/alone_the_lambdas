# Acceptance evidence

This document maps every completed core and effects requirement to observed
evidence in the repository. The authoritative requirements remain the three
[specifications](specifications/README.md) and the approved
[host-boundary design](design/host-boundary.md), together with the approved
[standalone-distribution design](design/standalone-distribution.md); this is
their verification index, not a replacement.

Verified on 2026-08-26 with:

```sh
raco make core/*.rkt readers/*.rkt
./run-all-tests.sh
```

The result was 3,039 passing assertions across 18 test files, followed by a
clean structural scan of all 16 production modules.

Phase 14 was verified on 2026-08-27 with `./run-all-tests.sh`: 3,151 passing
assertions across 22 test files, the same clean 16-module core scan, and a
clean effects/codec/host boundary scan.

Phase 15 was verified on 2026-08-27 with `./run-all-tests.sh`: 3,307 passing
assertions across 24 test files, the unchanged clean 16-module core scan, and
the extended effects/codec/host boundary scan.

The post-Phase 15 audit hardening was verified on 2026-08-27 with
`./run-all-tests.sh`: 3,345 passing assertions across the same 24 test files,
the unchanged clean 16-module expanded core scan, and the extended
effects/macros/codec/host/language-layer boundary scan.

Phase 16 was verified on 2026-08-27 with `./run-all-tests.sh`: 3,845 passing
assertions across 26 test files, the unchanged clean 16-module expanded core
scan, and the blocking-TCP effects/runtime boundary scan.

Phase 17 was verified on 2026-08-27 with `./run-all-tests.sh`: 3,995 passing
assertions across 27 test files, the unchanged clean 16-module expanded core
scan, and the pure HTTP-aware effects/runtime boundary scan.

Phase 18 was verified on 2026-08-27 with `./run-all-tests.sh`: 4,136 passing
assertions across 28 test files, the unchanged clean 16-module expanded core
scan, and the pure HTTP-server-aware effects/runtime boundary scan.

Phase 19 was verified on 2026-08-27 with `./run-all-tests.sh`: 4,224 passing
assertions across 29 test files, the unchanged clean 16-module expanded core
scan, and the reader/expander/package-aware boundary scan.

Phase 20 was verified on 2026-08-27 with `./run-all-tests.sh`: 4,261 passing
assertions across 30 test files, the unchanged clean 16-module expanded core
scan, and the complete 76-source classification and one-bridge boundary scan.
The exact three applications ran from a copied package installation under an
isolated Racket user home; filesystem effects stayed in an empty temporary
directory and network effects stayed on an ephemeral loopback port.

Phase 22 was verified on 2026-08-27 with `./run-all-tests.sh`: 4,412 passing
assertions across 31 test files, the unchanged clean 16-module expanded core
scan, and the complete 79-source classification with a closed runner class.
All runner and application execution used a copied package installation under
an isolated Racket user home rather than a checkout link or existing package
registry entry.

Phase 23 was verified on 2026-08-28 with `./run-all-tests.sh`: 4,449 passing
assertions across the same 31 test files, the unchanged clean 16-module
expanded core scan, and the complete 79-source classification with the exact
diagnostic formatter and strict source-encoding preflight added to the closed
runner class.

Phase 24 was verified on 2026-08-28 with `./run-all-tests.sh`: 4,492 passing
assertions across 32 test files, the unchanged clean 16-module expanded core
scan, and the complete 80-source classification. Its separate digest-pinned
Ubuntu 24.04 consumer passed with no Racket command or checkout.

Phase 25 was verified on 2026-08-28 with `./run-all-tests.sh`: 4,541 passing
assertions across the same 32 test files, the unchanged clean 16-module
expanded core scan, and the complete 80-source classification. The separate
native macOS 15.7.7 arm64 and macOS 15.7.9 x86_64 consumers passed with no
Racket command or checkout, and the workflow deleted both temporary transfer
artifacts.

Phase 26 was verified on 2026-08-28 with `./run-all-tests.sh`: 4,589 passing
assertions across the same 32 test files, the unchanged clean 16-module
expanded core scan, and the complete 80-source classification. A separate
Microsoft Windows Server 2025 Datacenter 10.0.26100 x86-64 consumer passed
with no Racket command or checkout, including cross-drive relocation, and the
workflow immediately deleted its temporary transfer artifact.

Phase 27 was verified locally and remotely on 2026-08-28. The complete suite
passed 4,617 assertions across all 32 test files, the unchanged clean
16-module expanded core scan, and the complete 80-source classification.
Validation commit `a048550e619499e0fbb3f944ba959ef84c4cc586` passed all ten
jobs in [GitHub Actions run
33204885605](https://github.com/kserrec/attalambda/actions/runs/33204885605),
including all four renamed native archives and their no-Racket consumers. The
three approved cross-job transfer artifacts were deleted immediately, and the
completed run's artifact API returned `total_count: 0`.

Phase 28 was verified locally and remotely on 2026-08-29. The complete suite
passed 4,745 assertions across all 32 test files, the unchanged clean
16-module expanded core scan, and the complete 80-source classification.
Candidate source commit `91ba3a9a8d57f0f19f4e8620317a85cb781148df`
passed all four native builders and all four no-Racket, guide-driven consumers
in [GitHub Actions run
33258685537](https://github.com/kserrec/attalambda/actions/runs/33258685537).
The three approved cross-job transfer artifacts were deleted immediately, and
the completed run's artifact API returned `total_count: 0`.

## Base specification criteria

| Completion criterion | Evidence |
| --- | --- |
| Lists are explicit Michaelson-style List objects. | [`lists-test.rkt`](../tests/lists-test.rkt) checks the tag/payload representation, proper tails, traversal, and constructor boundary. |
| Empty List is not raw false. | [`lists-test.rkt`](../tests/lists-test.rkt) distinguishes `NIL` from Bool and Nat; [`acceptance-test.rkt`](../tests/acceptance-test.rkt) observes its `LIST` tag. |
| Numbers are scalable binary digit Lists. | [`binary-nat-test.rkt`](../tests/binary-nat-test.rkt) covers normalized MSB-first bits and larger arithmetic; [`acceptance-test.rkt`](../tests/acceptance-test.rkt) constructs 100 as seven binary digits. |
| Church numerals are used only for tiny tags and discriminants. | Structural check: [`tags.rkt`](../core/tags.rkt) owns Church zero through six; Error kinds and argument positions reuse that closed metadata range, while [`binary-nat.rkt`](../core/binary-nat.rkt) owns all ordinary numeric representation and arithmetic. |
| Arbitrary-arity functions use one generalized curried checker. | [`typecheck-test.rkt`](../tests/typecheck-test.rkt) exercises zero-, one-, two-, three-, and five-argument signatures through `make-typed-function`. |
| No arity-specific checker exists. | [`check-purity.rkt`](../tooling/check-purity.rkt) rejects numbered `type-check` and `make-typed-function` identifiers; [`purity-test.rkt`](../tests/purity-test.rkt) proves both patterns fail. |
| Early type failures preserve remaining curried arity. | [`typecheck-test.rkt`](../tests/typecheck-test.rkt) checks exact absorber depth and ignored-argument laziness at every position; strict operation suites repeat this at their public boundaries. |
| Errors preserve roots and accumulate structured frames. | [`errors-test.rkt`](../tests/errors-test.rkt) checks root identity, newest-first frame storage, result frames on failing algorithms, and unframed pass-through of Errors held as data; [`error-reader-test.rkt`](../tests/error-reader-test.rkt) checks named causal rendering at every raw-failure boundary. |
| Result represents expected failure separately from Error. | [`result-test.rkt`](../tests/result-test.rkt) and [`acceptance-test.rkt`](../tests/acceptance-test.rkt) distinguish `DIV` by zero as Result Err from a wrong argument as contract Error; `result-test.rkt` also proves unwrapping the absent variant is a contract Error, not silent payload access. |
| Typed `if` consumes tagged Bool values. | [`typed-logic-test.rkt`](../tests/typed-logic-test.rkt) checks strict condition typing, polymorphic branches, absorber shape, and divergent unselected branches. |
| Char uses binary payloads from 0 through 255. | [`chars-test.rkt`](../tests/chars-test.rkt) checks normalized payloads, both bounds, rejection of 256, constants, comparisons, and observation. |
| String is a typed List of typed Char values. | [`strings-test.rkt`](../tests/strings-test.rkt) checks the representation, recursive Char invariant, proper tails, and invalid elements. |
| String operations are lambda computations. | [`strings-test.rkt`](../tests/strings-test.rkt) covers every raw and strict algorithm; the purity scan checks [`strings.rkt`](../core/strings.rkt) under the same host-form ban as the rest of production. |
| All core computation remains pure untyped lambda calculus. | [`check-purity.rkt`](../tooling/check-purity.rkt) expands every `core/*.rkt` file and its reachable project imports exactly as the compiler does and admits only Lazy Racket's own expansion of unary `lambda` and unary application, variables, single-identifier definitions, and project-only imports and exports; it verifies the trusted language shell and rejects host data, host forms, non-unary lambdas and applications, strict kernel lambdas, compile-time definitions, explicit `host`, and arity-specific checkers. The command runs after every test file in [`run-all-tests.sh`](../run-all-tests.sh) and in CI. |

## Addenda and Phase 12 refinements

| Refined requirement | Evidence |
| --- | --- |
| Production computation reduces to variables, unary lambda, and application after mechanical expansion. | [`macros-test.rkt`](../tests/macros-test.rkt) checks curried expansion and one-Char-per-UTF-8-byte function-name generation across one-, two-, three-, and four-byte source characters; [`purity-test.rkt`](../tests/purity-test.rkt) compiles real modules and proves zero-/multi-argument applications, multi-formal lambdas, host forms and literals, alternate module languages, host imports and re-exports, unapproved Lazy Racket bindings, and macros that emit host data, reference macro-module values, substitute a strict lambda, or behave differently under source-carrying expansion are all rejected, while local lexical shadowing and pure re-exports remain valid. |
| Readers are a one-way observation boundary. | Structural check: reader modules may use host values and formatting, but no production module imports `readers/`; the dependency direction is recorded in [`ARCHITECTURE.md`](../ARCHITECTURE.md). |
| Error frames contain structured function-name Strings. | [`function-names.rkt`](../core/function-names.rkt) contains pure typed constants; [`error-reader-test.rkt`](../tests/error-reader-test.rkt) verifies all 43 names, every corresponding strict mismatch boundary, and nested propagation. |
| Diagnostics preserve structured data until observation. | [`error.rkt`](../readers/error.rkt) alone flattens roots and frames; its tests cover all root kinds, type names, raw fallback output, and causal order. |
| Internal names expose raw and typed layers without underscore collision workarounds. | Structural check: production implementation APIs use `raw-*` and `typed-*`; [`expander.rkt`](../lang/expander.rkt) exposes canonical `lambda`, `def`, `let`, strict typed `if`, and proper typed `cons` while its exact export gate keeps raw, typed, and underscore workarounds private. |
| No implicit host boundary exists in the core milestone. | `host` remains absent from `core/` and forbidden by its unchanged purity scan. Phase 14's later explicit bridge is isolated in `runtime/host.rkt` and checked separately rather than weakening this evidence. |

## Phase 14 effects-boundary evidence

| Requirement | Evidence |
| --- | --- |
| Exact byte conversion is isolated from effects. | [`codec-test.rkt`](../tests/codec-test.rkt) covers all 256 byte values, empty and embedded-zero Strings, immutable output, source-byte copying, canonical List/Char/String construction, malformed tags/tails/elements, leading-zero and out-of-range Char rejection, and canonical Ok/Err construction. [`check-boundaries.rkt`](../tooling/check-boundaries.rkt) rejects codec I/O, mutation, registries, readers, runtime dependencies, unknown strict-module identifiers, and unauthorized exports. |
| `host` is one unary, closed privileged bridge. | [`host-test.rkt`](../tests/host-test.rkt) checks unary arity, the strict outer List contract, every stdout/file schema failure, malformed representation rejection before effects, canonical InvalidHostRequest/HostFailure details, incoming Error propagation, and cached force-once behavior; [`tcp-host-test.rkt`](../tests/tcp-host-test.rkt) adds the six TCP schemas and real lifecycle. The boundary checker requires the sole `host` definition/direct producer export and its exact protocol/codec imports; sees through classified require wrappers and fails closed on unclassified wrappers; authorizes imports before discovering full-import exports; pins both mechanical macro modules plus the Phase 19 reader, expander, and package metadata; validates the project-root anchor and every production-path component before discovery; rejects symlinks without traversing their targets; rejects additional macro/language modules; and allows only the exact facade to import and re-export that same production `host`. |
| `stdout` remains ordinary lambda computation. | [`stdout-test.rkt`](../tests/stdout-test.rkt) proves the exact `["stdout", bytes]` request, strict String rejection before dispatch, deterministic fake-host traces, unchanged Result propagation, unary shape, and lazy single dispatch. The boundary checker allowlists every effect identifier/import/export and rejects host data, non-unary forms, runtime imports, and unknown Lazy Racket bindings. |
| Real stdout is byte-exact and expected failure is Result Err. | [`host-test.rkt`](../tests/host-test.rkt) captures empty, embedded-zero, and byte-255 output with no newline, observes output only after forcing, proves repeat forcing does not write twice, proves an unselected host branch performs no effect, and maps a closed output port to `Err HostFailure("stdout", "io-failure")`. |
| The completed core boundary is unchanged. | [`check-purity.rkt`](../tooling/check-purity.rkt) still performs its zero-exception expanded scan over exactly 16 `core/` modules. [`run-all-tests.sh`](../run-all-tests.sh) runs that gate and the new boundary-classification gate independently. |

## Phase 15 file-effects evidence

| Requirement | Evidence |
| --- | --- |
| File wrappers remain ordinary lambda computation. | [`files-test.rkt`](../tests/files-test.rkt) proves the exact `["read-file", path]` and `["write-file", path, bytes]` requests, unary curried shape, no fake-host call during construction or partial application, force-once dispatch, unchanged Result propagation, strict String contracts at both positions, and exact remaining-arity absorption after an early Error. [`check-boundaries.rkt`](../tooling/check-boundaries.rkt) scans `effects/files.rkt` under the same pure-form and closed-import rules as the other effect modules. |
| File contents cross as byte-exact String values. | [`file-host-test.rkt`](../tests/file-host-test.rkt) writes and reads empty content plus bytes 0, 128, and 255, proves complete round trips without a reader, and proves a fresh shorter write truncates and replaces an existing longer file. It also verifies relative UTF-8 and absolute paths inside a temporary directory and removes that directory after the test. |
| Paths and expected filesystem failures have closed Result codes. | [`file-host-test.rkt`](../tests/file-host-test.rkt) proves real missing-parent and missing-file mapping, invalid UTF-8 as `invalid-text`, a decoded NUL path as `invalid-path`, a directory read as fallback `io-failure`, deterministic permission/resource/timeout errno categories, and Racket's explicit out-of-memory category. Both read and write permission failures carry their own canonical operation String; no exception text, path, or errno enters the Error. |
| Filesystem authority is confined to the sole host. | [`check-boundaries.rkt`](../tooling/check-boundaries.rkt) permits only the exact `file->bytes` import plus byte output and truncation capabilities in `runtime/host.rkt`; it rejects file access in the codec, effects, and macros, broad `racket/file` imports, deletion, directory operations, wrapped second codec imports, every second host import, and every second `host` definition/export. [`boundary-check-test.rkt`](../tests/boundary-check-test.rkt) proves those denials; observes zero metadata or content access to ordinary disallowed full-import targets, sources beneath intermediate production symlinks, and trees behind root/ancestor symlinks; and proves direct final symlinks are not opened. [`file-host-test.rkt`](../tests/file-host-test.rkt) separately proves the approved host operation itself follows and preserves a symlink without requesting delete authority. |

## Phase 16 blocking-TCP evidence

| Requirement | Evidence |
| --- | --- |
| TCP wrappers remain ordinary lambda computation. | [`tcp-test.rkt`](../tests/tcp-test.rkt) proves the exact connect/listen/accept/read/write/close request shapes, unary curried partial applications, strict String/Nat contracts at every position, exact remaining-arity absorption after early Error, no fake-host call during construction or an unselected branch, unchanged success/failure propagation, exact traces, and force-once dispatch. [`check-boundaries.rkt`](../tooling/check-boundaries.rkt) scans `effects/tcp.rkt` under the same pure-form and closed-import rules as every effect module. |
| Nat and byte conversion stays deterministic and canonical. | [`codec-test.rkt`](../tests/codec-test.rkt) proves exact Nat round trips at 0, 1, 255, 256, 65535, 65536, and a value above 64 bits; normalized zero and positive output; and wrong-tag, empty, leading-zero, invalid-bit, improper-tail, negative-input, and fractional-input rejection. The same suite retains exhaustive byte coverage. The codec boundary rejects TCP, I/O, mutation, registries, readers, runtime dependencies, unknown identifiers, and extra exports. |
| The full blocking lifecycle is byte-exact and releases resources. | [`tcp-host-test.rkt`](../tests/tcp-host-test.rkt) uses only `127.0.0.1` and ephemeral ports. It proves handles begin at one, increase monotonically, and are not reused; validates listener/connection kinds plus fabricated and stale handles; observes a read blocked before peer output; enforces per-call read bounds without assuming packet boundaries; recovers complete binary writes in both directions; proves empty write behavior and orderly EOF; explicitly closes every acquired handle; and verifies Racket custodian closure plus deterministic stale-handle behavior. Test-side threads exist only to drive peers during blocking calls. |
| TCP failures have a closed, nonleaking Result vocabulary. | [`tcp-host-test.rkt`](../tests/tcp-host-test.rkt) deterministically exercises permission, address-in-use, refused, reset, broken-pipe, unreachable, resource, timeout, name-resolution, invalid-text, invalid-handle, wrong-handle-kind, and generic I/O categories without contacting an external service. It also proves malformed schema, representation, arity, type, and range failures remain bare InvalidHostRequest Errors and that no exception text, hostname, errno, port, socket, or host collection crosses the boundary. |
| TCP authority remains confined to the sole host. | [`check-boundaries.rkt`](../tooling/check-boundaries.rkt) permits exactly `tcp-accept`, `tcp-addresses`, `tcp-close`, `tcp-connect`, and `tcp-listen` from `racket/tcp` in `runtime/host.rkt`; all UDP, process, eval, dynamic-loading, environment, FFI, and production-thread capabilities remain closed. Its project-wide scan rejects any second production `racket/file` or `racket/tcp` importer, including wrapped imports and core modules. [`boundary-check-test.rkt`](../tests/boundary-check-test.rkt) proves the exact allowlist, broad-import rejection, codec denial, and sole-importer rule. |

## Phase 17 pure-HTTP evidence

| Requirement | Evidence |
| --- | --- |
| Request parsing remains lambda computation and has a closed useful subset. | [`http-test.rkt`](../tests/http-test.rkt) proves exact GET and HTTP/1.1 validation, visible-byte origin-form target extraction as an existing String, case-insensitive exactly-once Host handling, token-valid field names, permitted field-value bytes, additional field lines, strict String contracts, incoming-Error bubbling, and a unary public shape. [`http.rkt`](../effects/http.rkt) imports no runtime, reader, host String, regex, arithmetic, or HTTP library. |
| Fragmentation and invalid input remain expected Result values. | [`http-test.rkt`](../tests/http-test.rkt) reparses accumulated lambda Strings across request-line and final-terminator CRLF splits; every unfinished prefix is Err IncompleteHttpRequest. Complete bad line endings, missing/duplicate Host fields, invalid field lines, empty targets, bodies, and pipelined bytes are Err MalformedHttpRequest; unsupported methods, versions, and target forms are Err UnsupportedHttpRequest. None uses a host exception. |
| Response bytes and lengths are built entirely in the lambda layer. | [`http-response.rkt`](../effects/http-response.rkt) isolates response construction from parsing. [`http-test.rkt`](../tests/http-test.rkt) proves exact 200, 400, 404, and 500 status lines, `Content-Length` values at zero and across the 9-to-10 decimal boundary, `Connection: close`, the empty header terminator, byte-exact text and 0/128/255 bodies, deterministic repeated rendering, unsupported-status Result Err, strict contracts, and early-Error absorption. |
| The pure HTTP classification is enforced rather than asserted. | [`check-boundaries.rkt`](../tooling/check-boundaries.rkt) discovers both HTTP modules automatically under the same closed unary-lambda/application class as every effect module. [`boundary-check-test.rkt`](../tests/boundary-check-test.rkt) contains direct rejection probes for Racket `string-length`, `regexp-match?`, `+`, and `net/http-client`/`http-sendrecv`; the independent expanded core scan remains exactly 16 zero-exception modules. |

## Phase 18 minimal-HTTP-server evidence

| Requirement | Evidence |
| --- | --- |
| Routing and response selection remain ordinary lambda computation. | [`http-server.rkt`](../effects/http-server.rkt) defines a strict six-position `make-http-path-handler`; applying its path, matched status/body, and fallback status/body produces a unary `String -> Result String` handler. [`http-server-test.rkt`](../tests/http-server-test.rkt) proves exact matched and fallback responses, selected-branch laziness when the other status is unsupported, strict contracts, incoming-Error absorption, and the dedicated invariant Error for an invalid handler result. |
| One request is handled per connection with deterministic cleanup. | `make-http-serve-one` accepts a caller-owned listener and per-read maximum, accumulates lambda String chunks, invokes the Phase 17 parser and handler, writes one complete response, and closes its accepted connection on every completed success or failure path. Focused fake-host cases prove malformed input, incomplete EOF, accept/read/write/close failures, handler Err/Error behavior, primary-failure preservation when cleanup also fails, and force-once execution. |
| The blocking server is sequential and uses only documented TCP effects. | `make-http-server` repeats successful one-connection operations with the pure fixed point and stops at the first Error or Result Err. A deterministic two-connection trace is exactly accept/read/write/close, accept/read/write/close, then the terminating accept failure; no listener close is hidden because the caller owns that handle. The project boundary scan automatically classifies the new module as a pure effect module and rejects runtime, HTTP-library, host String, arithmetic, mutation, control-flow, and non-unary shortcuts. |
| A real external HTTP client receives the lambda-selected response. | [`http-server-test.rkt`](../tests/http-server-test.rkt) obtains an ephemeral `127.0.0.1` listener through the real host, runs one blocking serve operation with test-only concurrency, and uses test-side `net/http-client` to request `/lambda`. It verifies the exact 200 status, `Content-Length`, `Connection: close`, body, successful connection cleanup, and explicit caller cleanup of the listener without contacting any external service. |

## Phase 19 standalone-language evidence

Phase 19 through 26 preserve the public spellings demonstrated at those
historical checkpoints. Current working-tree links point to their Phase 27
renamed successors; the Phase 27 section below owns proof of the new names.

| Requirement | Evidence |
| --- | --- |
| `#lang alone_the_lambdas` resolved from a fresh package installation. | The Phase 19 revision of [`language-test.rkt`](../tests/language-test.rkt) created an isolated Racket user home, explicitly staged only package metadata, production files, and public applications while excluding every dotenv spelling, VCS state, and compiled artifacts and rejecting symlinks, installed that source using [`info.rkt`](../info.rkt), then ran programs outside the installed collection. The install used declared dependencies only and did not rely on a source-tree collection path or package link. |
| Canonical syntax remains unary lambda computation. | The specification's exact `def`/`if`/`cons` sample shape runs and returns the selected List element. Separate programs prove multi-operand source calls and multi-argument `def` lower to nested unary applications, `let` is immediate unary-lambda application, public `lambda` rejects multiple formals, and a divergent unselected branch is never forced. The existing macro suite retains direct curried-expansion coverage. |
| Nat and String literals are canonical lambda values. | The language suite lowers 0, 1, 255, 256, and 65536, then test-only module-namespace observation passes them through the strict codec and recovers the exact integers. A `λ🙂` source String decodes as exactly six UTF-8 bytes and is emitted byte-for-byte through public `stdout`. Booleans, negative/rational/flonum/complex numbers, characters, byte strings, keywords, vectors, and quoted symbols are rejected during expansion; no additional literal family or parser exists. |
| The facade is canonical and isolated from Racket/internal namespaces. | Runnable programs use only `lambda`, `def`, `let`, `if`, `cons`, strict data operations, bound `stdout`, and explicit `host`. Direct probes prove `define`, `require`, `+`, `display`, `raw-cons`, `typed-if`, `_if`, and quote are unavailable. [`check-boundaries.rkt`](../tooling/check-boundaries.rkt) pins exact facade imports, exports, transformer/helper sets, nine host-injection definitions, source vocabulary, sole host path, the exact reader target, and package metadata; 70 boundary checks prove representative import, export, runtime-definition, syntax-helper, reader, metadata, extra-module, and second-host failures. |

## Phase 20 runnable-application and milestone evidence

| Requirement | Evidence |
| --- | --- |
| A fresh checkout can install and run ordinary standalone programs. | [`fresh-language.rkt`](../tests/helpers/fresh-language.rkt) copies only the package metadata, production directories, and exact application directory, excluding every dotenv spelling plus VCS/compiled state before content access and rejecting symlinks, then installs the copy under an isolated Racket user home. [`language-test.rkt`](../tests/language-test.rkt) retains all 75 Phase 19 checks through that shared harness. [`milestone-two-acceptance-test.rkt`](../tests/milestone-two-acceptance-test.rkt) runs the exact repository examples outside the installed collection, so no source-tree package link or undeclared dependency can satisfy resolution. |
| The three terse applications performed all four specified effect families. | The then-named `stdout.atl` (now [`stdout.attl`](../examples/stdout.attl)) proved public `stdout`. The then-named `file-round-trip.atl` (now [`file-round-trip.attl`](../examples/file-round-trip.attl)) sequenced public `write-file` before public `read-file` by inspecting the first Result, emitted the recovered bytes, and was verified only in an empty temporary directory. The then-named `http-server.atl` (now [`http-server.attl`](../examples/http-server.attl)) exercised the TCP listen/accept/read/write/close path, used only public lambda operations to format its ephemeral port, served one lambda-built HTTP response to a test-side external client, closed its caller-owned listener, and exited. |
| Every Racket source had the correct structural classification. | The Phase 20 revision of [`check-boundaries.rkt`](../tooling/check-boundaries.rkt) inventoried all 76 Racket sources across pure core, effects, the two trusted runtime modules, the two exact macros, reader/expander/package surface, one-way readers, tests, tooling, and applications. Applications were required to use `#lang alone_the_lambdas`; unknown locations, symlinks, and forbidden dependency directions failed closed. |
| The core purity claim remains unchanged. | [`check-purity.rkt`](../tooling/check-purity.rkt) still expands and accepts exactly the same 16 zero-exception `core/` modules. No Phase 20 executable production file was created or modified; the example computations pass through the already accepted facade and layers. |

## Phase 22 canonical-runner evidence

| Requirement | Evidence |
| --- | --- |
| The command and `.atl` source contracts were exact. | The Phase 22 revision of [`runner-test.rkt`](../tests/runner-test.rkt) used the copied-package runner for exact `atl run FILE.atl`, help/version output, command misuse, lowercase-extension precedence, input and declaration validation, symlink and dotenv refusal, and paths containing spaces and non-ASCII characters. Covered launcher failures wrote nothing to stdout and used exact statuses 64, 65, and 66 while the structural gate pinned status 70. |
| The runner delegated to the existing language exactly once. | The then-named `runner/atl.rkt` (now [`runner/attalambda.rkt`](../runner/attalambda.rkt)) validated one explicit path and invoked `dynamic-require` on that path without importing a reader, expander, codec, runtime, test, tool, or application. The focused suite ran the then-named `hello.atl` (now [`hello.attl`](../examples/hello.attl)) and all three real effect applications through that copied runner. |
| Runner scaffolding could not become object-language computation or a second effect bridge. | The Phase 22 revision of [`check-boundaries.rkt`](../tooling/check-boundaries.rkt) admitted only `runner/atl.rkt`, its exact imports, fixed definition and status sets, two input targets, closed vocabulary, no export, terminal `main`, and one `(dynamic-require source-path #f)`. It rejected extra runner modules, exports, altered loader targets or status constants, forbidden capabilities, and every production dependency on `runner/`. |
| Product and package versions have one authority. | Root [`VERSION`](../VERSION) now contains exactly `0.2.0-rc.1` plus LF and projects to `info.rkt` version `0.1.901`; Phase 22 initially established the same mechanism at `0.2.0-dev`/`0.1.900`. Runner expansion/build derives and embeds the CLI value from that source, so a native artifact needs no runtime version file and the runner source contains no copied public version literal. The boundary gate accepts only the approved `0.2.0-dev` → `0.1.900`, `0.2.0-rc.1` → `0.1.901`, and `0.2.0` → `0.2` package projections and rejects malformed, mismatched, missing, or symlinked version metadata without reading a symlink target. |
| Completed language failures remain language data. | Runner tests prove a strict contract Error and a real-host `read-file` Result Err both complete with process status 0 and no implicit observation. The runner never decodes, renders, or branches on either value; the unchanged facade module wrapper alone forces requested top-level effects and discards the completed lambda value. |
| The public application inventory was canonical. | At Phase 22 the repository contained exactly `hello.atl`, `stdout.atl`, `file-round-trip.atl`, and `http-server.atl` under `examples/`; Phase 27 supersedes that inventory. |

## Phase 23 user-facing diagnostic evidence

| Requirement | Evidence |
| --- | --- |
| Every launcher-controlled class had stable Alone the Lambdas stderr and status. | The Phase 23 revision of [`runner-test.rkt`](../tests/runner-test.rkt) compared complete stderr bytes for command misuse (64), invalid source (65), refused or unavailable input (66), and an injected launcher failure (70). Help, version, and successful source runs retained empty stderr. Phase 27 supersedes only the product name, extension, declaration, and command text. |
| Diagnostics preserve useful source identity without leaking implementation state. | Relative failing sources are reported with the exact quoted command-line spelling plus canonical reader line/column. Tests explicitly reject the isolated installation's temporary root, `package-source`, injected raw exception text, and host procedure rendering. Absolute and Unicode paths remain the caller-supplied strings; no resolved checkout, registry, or build path substitutes for them. |
| Invalid UTF-8 was rejected before Racket could substitute a replacement character. | A focused malformed-byte fixture proved status 65 and the exact `source is not valid UTF-8` reason. The then-named `runner/atl.rkt` (now [`runner/attalambda.rkt`](../runner/attalambda.rkt)) checked only bytes after the exact ASCII declaration with strict `bytes->string/utf-8` and delegated all tokenization, parsing, expansion, and evaluation to the existing reader/expander. |
| Language data and requested host failure remain outside launcher control flow. | Separate source programs complete with an ordinary strict contract Error, pure `DIV ONE ZERO` Result Err, and real-host missing-file Result Err. All exit 0 with empty stdout/stderr. The runner imports no codec or reader, never receives a final value from `dynamic-require`, and cannot branch on any lambda representation. |
| The diagnostic implementation remains closed loader scaffolding. | [`check-boundaries.rkt`](../tooling/check-boundaries.rkt) pins the exact formatter, safe identifier extraction, strict UTF-8 expression, runner imports/definitions/vocabulary, status definitions, two input paths, one loader call, terminal `main`, and no exports. [`boundary-check-test.rkt`](../tests/boundary-check-test.rkt) now proves raw syntax-object rendering and removal of the strict source preflight are rejected, in addition to the Phase 22 capability and dependency denials. |

## Phase 24 self-contained Linux distribution evidence

The Phase 24 through 26 rows preserve the literal pre-rename collection,
command, executable, extension, archive, and repository names demonstrated by
those completed runs. Links to working-tree tooling point to the Phase 27
renamed successors; they do not retroactively claim that the measured
artifacts had the new names.

| Requirement | Evidence |
| --- | --- |
| The build is isolated, pinned, and deterministic. | The Phase 24 revision of [`build-linux-distribution.sh`](../tooling/build-linux-distribution.sh) accepted only Linux x86-64 and the exact full Racket CS 9.3 banner/VM, verified the closed `VERSION` projection before compilation, staged only nonsymlink production sources, and installed them under a disposable `PLTUSERHOME` with `--deps fail`. It invoked `raco exe ++lang alone_the_lambdas` and `raco distribute`, rejected outputs inside the checkout or existing output files, removed local timestamps/owners/gzip metadata, and scanned the payload for checkout, package-home, temporary-build, and nonstandard toolchain paths. The separate no-Racket consumer proved that an ordinary `/usr` or `/usr/local` toolchain prefix was not a runtime dependency without treating those entire system prefixes as forbidden byte strings. Two same-state builds under different temporary paths produced byte-identical archives; later output-hardening rebuilds retained those bytes. |
| The unpublished artifact and checksum contracts are exact. | The observed archive had one versioned root containing only `bin/atl`, its `lib/` runtime, the four canonical `.atl` examples, `GETTING_STARTED.md`, `BUILD-MANIFEST.txt`, `THIRD_PARTY_NOTICES.md`, and `UNPUBLISHED-DEVELOPMENT-ARTIFACT.txt`; at that time it contained no approved repository `LICENSE`. The build manifest recorded the product/source/toolchain/target, exact file inventory, and observed dynamic libraries without a local path or timestamp. The final archive digest and filename lived in external `SHA256SUMS`, as explicitly approved on 2026-08-28. The provisional notice reproduced and hashed the exact Racket 9.3 top-level notice plus Apache, MIT, and LGPL texts while then reserving the final legal inventory for Phase 27. |
| A transferred archive runs without Racket or the checkout. | The Phase 24 revision of [`test-linux-distribution.sh`](../tooling/test-linux-distribution.sh) copied only the archive, checksum, and harness into a digest-pinned Ubuntu 24.04 container. The container had no `racket` or `raco`, ran as UID/GID 65534 with a read-only root and no capabilities, and had Docker networking disabled except loopback. It verified the checksum before extraction, exact layout and executable permissions, exact help/version bytes, a canonical source created after packaging, and proof that a conflicting external `alone_the_lambdas` reader could not displace the embedded language. |
| All approved real effects and relocation work from the payload. | The same container checks exact stdout bytes, file replacement/readback in an isolated writable directory, and one HTTP request to the program's ephemeral loopback listener with exact status/body and clean stderr. It then moves the entire extracted tree between two paths containing spaces and reruns version plus the post-package source. Neither the checkout, a package registry, a system Racket, nor an external network service is mounted or available. |
| The unoptimized Linux baseline is measured without becoming a release claim. | The disposable validation archive was `13,679,991` compressed bytes and `59,299,555` unpacked regular-file bytes. Its runtime tree was exactly `bin/atl` (`7,853,237` bytes) plus `lib/plt/racketcs-9.3` (`51,412,696` bytes); the full payload had 10 files. Final pinned-container runs observed 290–344 ms for the first `atl --version` process and 294–302 ms after relocation. Both ELF files resolved the loader, `libc`, `libdl`, `libm`, `libpthread`, `librt`, and `libz`. Every recorded internal dirty-tree build had SHA-256 `a5e43c54467fa4afe0bb74aeeda962ae617de26b35c6cf50d65891de81b64cf0`; this is reproducibility evidence for those disposable artifacts, not a public or final-commit checksum. No demodularizer or new dependency was added. |
| Packaging changed no language or host boundary. | The Phase 24 revision of [`distribution-test.rkt`](../tests/distribution-test.rkt) contributed 43 focused shell/asset/contract assertions. The final suite passed 4,492 assertions across 32 test files, the unchanged 16-module expanded core-purity proof, and a zero-finding inventory of all 80 Racket and `.atl` sources. No production Racket source changed; shell tooling remained nonproduction and could not enter the structural dependency graph. |

## Phase 25 native macOS distribution evidence

| Requirement | Evidence |
| --- | --- |
| Both macOS architectures used pinned native builds. | The Phase 25 [test workflow](../.github/workflows/tests.yml) mapped `macos-x86_64` to `macos-15-intel` plus Racket `x64`, and `macos-arm64` to `macos-15` plus Racket `arm64`. The Phase 25 revision of [`build-macos-distribution.sh`](../tooling/build-macos-distribution.sh) independently required Darwin, the matching native `uname -m`, full Racket CS 9.3, the closed version projection, clean nonsymlink inputs, an isolated `PLTUSERHOME`, and `--deps fail` before invoking `raco exe ++lang alone_the_lambdas` and `raco distribute`. |
| The archives had exact portable structure and native dependencies. | Each predictably named `.tar.gz` had one versioned root, canonical `bin/atl`, stable `lib/` directory, the four examples, guide, build manifest, provisional notices, and unpublished warning; final SHA-256 and filename lived only in sibling `SHA256SUMS`. The build rejected symlinks and unexpected native architectures, recorded every Mach-O file, permitted only relative or `/usr/lib`/`/System/Library` dependencies, scanned for private build paths, and normalized timestamps, ownership, ordering, and gzip metadata. Racket CS 9.3 emitted no separate support files on either demonstrated target, so the build safely normalized an empty `lib/`; each archive's only Mach-O runtime file was `bin/atl`. |
| Each artifact crosses into an independent clean native consumer. | The build matrix uploads only one archive, `SHA256SUMS`, and a self-contained copy of [`test-macos-distribution.sh`](../tooling/test-macos-distribution.sh). Separate same-architecture jobs perform no checkout and install no Racket. Both consumers reported absent `racket`, absent `raco`, and absent checkout, then verified the checksum before extraction, exact layout/manifest/permissions, native Mach-O inventory, clean stderr, exact help/version bytes, a canonical source created after packaging, and hostile collection-path precedence. |
| All approved effects and relocation worked on both targets. | Both consumers reproduced exact stdout, isolated file replacement/readback, and one ephemeral-loopback HTTP response from the transferred payload. Each extracted into a path containing spaces, then moved to a second such path and reran both version and the post-package source. Validation commit `ed0db7df9ca17d4e7b2ea458069f7861c1207a2d` passed all jobs in [run 33181962284](https://github.com/kserrec/alone_the_lambdas/actions/runs/33181962284). |
| Measurements remain observations rather than compatibility or release claims. | The macOS 15.7.7 arm64 consumer validated a 9-file, `13,698,161`-byte compressed, `62,117,801`-byte unpacked payload with SHA-256 `8f428ff16be4acbf4a8ad41ce7241a40a623931ef9b5451c81b83e2fd2aad63f`; startup observations were 194 ms initially and 121 ms after relocation. The macOS 15.7.9 x86_64 consumer validated a 9-file, `13,669,470`-byte compressed, `59,412,300`-byte unpacked payload with SHA-256 `7ac92ca6aa49ce2882e43ab0d318d034932cc06cfe88e9554048b018ec0742ab`; startup observations were 1,170 ms and 319 ms. Both observed CoreFoundation, `libSystem`, `libiconv`, and `libncurses`. These exact versions are the oldest and only macOS versions demonstrated; no lower compatibility floor, signing state, performance guarantee, public checksum, or release is claimed. |
| The narrowly approved public transfer leaves no artifact behind. | Kyle explicitly approved only temporary GitHub Actions transfer of the two unpublished archives and their consumer harnesses. Upload and download use exact commit-pinned official GitHub actions, with one-day retention only as a cleanup-failure fallback. An `always()` cleanup job has `actions: write` and `contents: none`, deletes both exact artifact names, and fails if either remains. The successful validation run's artifact API returned `total_count: 0` immediately afterward. |
| Packaging changed no production behavior. | The Phase 25 revision of [`distribution-test.rkt`](../tests/distribution-test.rkt) contributed 92 focused shell/asset/workflow assertions. The completion suite passed 4,541 assertions across 32 test files, the unchanged 16-module expanded core-purity proof, and a zero-finding inventory of all 80 Racket and `.atl` sources. Phase 25 changed CI, shell tooling, tests, and documentation only; it changed no production Racket source, operation, representation, or host authority. |

## Phase 26 native Windows distribution evidence

| Requirement | Evidence |
| --- | --- |
| Windows used a pinned native build. | The Phase 26 [test workflow](../.github/workflows/tests.yml) ran on `windows-2025` and installed full x86-64 Racket CS 9.3 with the setup action pinned by full commit. The Phase 26 revision of [`build-windows-distribution.ps1`](../tooling/build-windows-distribution.ps1) independently required the native target and exact toolchain, verified the version projection and clean nonsymlink inputs, installed an approved source copy under an isolated `PLTUSERHOME` with `--deps fail`, then invoked `raco exe --embed-dlls ++lang alone_the_lambdas` and `raco distribute`. |
| The ZIP had exact portable structure and native evidence. | The predictable `.zip` had one versioned root, canonical `bin/atl.exe`, stable empty `lib/`, four examples, guide, manifest, provisional notices, and unpublished warning; it had exactly nine regular files and no then-approved `LICENSE`. The builder fixed ZIP timestamps and ordering, kept SHA-256 only in external `SHA256SUMS`, required PE x86-64 machine value `0x8664`, matched the native `dumpbin` inventory, recorded Authenticode state, and rejected complete known checkout, package-registry, temporary-build, package-source, and nonstandard-toolchain paths. |
| The artifact crosses into an independent clean consumer. | The build uploads only one archive, `SHA256SUMS`, and a self-contained copy of [`test-windows-distribution.ps1`](../tooling/test-windows-distribution.ps1). The separate consumer performs no checkout and installs no Racket. It reported absent `racket`, absent `raco`, and absent checkout; verified the checksum before extraction; rejected unsafe ZIP paths; matched the exact layout, manifest, PE architecture, DLL assumptions, Authenticode status, exit codes, stderr, help/version bytes, generated-after-packaging source, and hostile collection-path behavior. |
| All approved effects and cross-drive relocation worked. | The consumer reproduced exact stdout, isolated file replacement/readback, and one ephemeral-loopback HTTP response. It extracted under a path containing spaces on the runner's `D:` drive, copied the tree to a path containing spaces on `C:`, deleted the first tree, and reran version plus the generated source. Validation commit `a9f2bdc7d07a0283871ede548aa0c33cee0a3b78` passed these jobs in [run 33193791101](https://github.com/kserrec/alone_the_lambdas/actions/runs/33193791101). |
| Measurements and platform claims stay exact. | The demonstrated consumer was Microsoft Windows Server 2025 Datacenter 10.0.26100, build 26100, x86-64. Builder and consumer agreed on 9 files, `15,251,225` compressed bytes, `23,875,480` unpacked regular-file bytes, and SHA-256 `32323a72bb4dad11690f5189cdc543fcc49bb6138d1e1abe19e4694c0595b397`. The one PE/runtime file was `bin/atl.exe`; it observed `KERNEL32.dll`, `msvcrt.dll`, and `USER32.dll`, was exactly `NotSigned`, and started in 282 ms initially and 360 ms after relocation. These values describe only the disposable artifact; no older/client Windows, performance, signing, installer, release-checksum, or download claim follows. |
| The narrowly approved public transfer leaves no artifact behind. | Kyle explicitly approved only temporary transfer of the unpublished Windows archive, checksum, and consumer harness. The workflow reuses full-commit-pinned official upload/download actions, with one-day retention only as a cleanup-failure fallback. Its `always()` cleanup has `actions: write` and `contents: none`, deletes the exact artifact, and fails if it remains. The completed validation run's artifact API returned `total_count: 0`. The cost is one transient CI artifact and no new package or runtime dependency. |
| Packaging changed no production behavior. | The Phase 26 revision of [`distribution-test.rkt`](../tests/distribution-test.rkt) contributed 140 focused shell/PowerShell/asset/workflow assertions. The completion suite passed 4,589 assertions across 32 test files, the unchanged 16-module expanded core-purity proof, and a zero-finding inventory of all 80 Racket and `.atl` sources. Phase 26 changed CI, PowerShell tooling, tests, and documentation only; it changed no production Racket source, operation, representation, or host authority. |

## Phase 27 AttaLambda rename evidence

| Requirement | Evidence |
| --- | --- |
| Every current public identity has one spelling. | [`info.rkt`](../info.rkt) declares collection `attalambda`; [`reader.rkt`](../lang/reader.rkt) selects `attalambda/lang/expander`; the four applications use `.attl` and exact `#lang attalambda`; [`attalambda.rkt`](../runner/attalambda.rkt) owns the direct `attalambda FILE.attl` grammar and AttaLambda diagnostics. The build scripts, consumer harnesses, workflow artifact names, specifications, architecture, and current guides use the same role-specific spellings. |
| Retired public spellings are not compatibility aliases. | The 181-check [`runner-test.rkt`](../tests/runner-test.rkt) proves `run FILE.attl` is command misuse, bare `run` is treated as a supplied filename, `.atl` is rejected, and `#lang alone_the_lambdas` is rejected before module loading. It also distinguishes unknown options from an explicit `./-example.attl` filename. The 78-check [`language-test.rkt`](../tests/language-test.rkt) installs only package `attalambda` under a fresh isolated Racket user home and separately proves the old collection declaration cannot resolve. Exact application and packaged-binary inventories exclude old filenames. |
| The renamed collection is independent of the private checkout directory name. | [`check-boundaries.rkt`](../tooling/check-boundaries.rkt) supplies an in-memory Racket collection link from `attalambda` to the already validated project root while reading applications. It neither changes the user's package registry nor relies on the enclosing directory spelling. Its 113 adversarial checks and the direct project scan both pass. |
| Renamed cross-platform packaging contracts agree and execute independently. | The 144-check [`distribution-test.rkt`](../tests/distribution-test.rkt) pins `attalambda` archive roots and executables, `.attl` examples, direct command syntax, reader embedding, Linux/macOS/Windows consumer expectations, workflow artifact names, and immediate-cleanup selectors. Validation commit `a048550e619499e0fbb3f944ba959ef84c4cc586` passed the full source suite and every native job in [run 33204885605](https://github.com/kserrec/attalambda/actions/runs/33204885605). The digest-pinned Ubuntu 24.04, macOS 15.7.7 arm64, macOS 15.7.9 x86-64, and Microsoft Windows Server 2025 Datacenter 10.0.26100 x86-64 consumers each reported no Racket command or checkout and passed relocation. Exact sizes, hashes, dependencies, and timings are recorded in the [Phase 27 distribution record](design/standalone-distribution.md#phase-27-implementation-record). |
| The approved Phase 27 transfer left no artifact behind. | Linux remained inside one job. Only the two renamed unpublished macOS archives and one renamed unpublished Windows archive, their external checksums, and their self-contained harnesses crossed jobs. Both macOS consumers, the Windows consumer, and both `always()` cleanup jobs passed; the completed run's artifact API returned `total_count: 0`. One-day retention was only a cleanup-failure fallback. |
| The rename does not alter object-language computation or authority. | No `core/`, `effects/`, `runtime/`, macro, or expander executable changed; the reader's only executable edit is its collection-target spelling. The same 16 core modules pass the expanded purity proof, the boundary inventory retains the sole `host` and one non-exporting loader, and all three real-effect applications pass from a fresh copied package. The intended executable changes are confined to public launch names, source filenames/declarations, reader resolution, and example-visible branding. Product version remains `0.2.0-dev`; no release candidate, tag, signature, release, or public download exists. |

## Phase 28 release-candidate and novice-workflow evidence

| Requirement | Evidence |
| --- | --- |
| Exact approved legal payloads replace the transitional marker. | All three builders package root [`LICENSE`](../LICENSE), whose SHA-256 is `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`, plus the reviewed 100,029-byte [`THIRD_PARTY_NOTICES.md.in`](../distribution/THIRD_PARTY_NOTICES.md.in), whose SHA-256 is `1343f218ba484a79fbef498d4e8fb02e202763a19e46c5e610a8bfe900bcbefd`. They pin and verify the notice digest before packaging, record both hashes in the manifest, and exclude the historical development-warning input. Consumers independently hash the extracted bytes and reject the old marker. |
| End-user setup is independent of contributor setup. | [`GETTING_STARTED.md.in`](../distribution/GETTING_STARTED.md.in) and the primary README path begin with choosing an archive, filtering its entry from `SHA256SUMS`, extracting it, entering the versioned root, and running the packaged executable. They require no Racket installation, `raco`, or package registry. Contributor installation and source-checkout execution remain separate labeled sections. |
| The novice contract is complete and literal. | The guide documents the lowercase `.attl` extension, exact `#lang attalambda` declaration, native executable path, four supported candidate targets, statuses 0/64/65/66/70, diagnostics, archive verification, release notes, exact current limitations, and the unsandboxed stdout/file/TCP authority. The 197-check [`distribution-test.rkt`](../tests/distribution-test.rkt) pins the required guide sections, license/notice contract, candidate status, builders, consumers, and workflow cleanup selectors. |
| All four downloaded-artifact workflows execute independently. | Candidate commit `91ba3a9a8d57f0f19f4e8620317a85cb781148df` passed [run 33258685537](https://github.com/kserrec/attalambda/actions/runs/33258685537). The digest-pinned Ubuntu 24.04, macOS 15.7.7 arm64, macOS 15.7.9 x86-64, and Microsoft Windows Server 2025 Datacenter 10.0.26100 x86-64 consumers each reported no Racket, no `raco`, no checkout where applicable, `guide_workflow=passed`, relocation success, and final consumer acceptance. Each executed the printed checksum, extraction, directory-entry, version, hello, and custom-program workflow before the broader effects and embedded-reader checks. |
| Exact unpublished candidate evidence is preserved without a release claim. | The four names, compressed and unpacked byte counts, SHA-256 values, runtime/dependency inventories, signing state, and startup observations are recorded in the [Phase 28 implementation record](design/standalone-distribution.md#phase-28-implementation-record). The four same-run hashes form one staging `SHA256SUMS` record. They describe disposable validation candidates, not downloads, compatibility floors, performance guarantees, or Phase 29 release hashes. |
| The approved transfer leaves nothing downloadable. | Linux remained in one job. Only the two macOS archives and one Windows archive, their one-entry checksums, and self-contained consumer harnesses crossed the separately approved temporary boundary. One-day retention was only a cleanup-failure fallback. Both cleanup jobs passed, and the completed run's artifact API returned `total_count: 0`. No tag, GitHub Release, signing operation, public download, or publication exists. |
| Promotion changes delivery state, not language authority. | Root [`VERSION`](../VERSION) is now exactly `0.2.0-rc.1` and projects to `info.rkt` `0.1.901`; the CLI intentionally reports `AttaLambda 0.2.0-rc.1`. No core, effect, runtime, reader, macro, expander, or runner source changed. The complete suite passed 4,745 assertions across 32 files, the unchanged 16-module purity proof, and the zero-finding 80-source inventory. Object-language computation and the sole host boundary are unchanged. |

## Explicit one-bridge evidence map

| Boundary fact | Sole allowed production location | Enforced evidence |
| --- | --- | --- |
| Definition and direct producer export of `host` | [`runtime/host.rkt`](../runtime/host.rkt) | The project scan requires exactly one definition and exact sole export; it rejects every second definition/export and pins the host's complete source vocabulary. |
| Deterministic object/host conversion | [`runtime/codec.rkt`](../runtime/codec.rkt), imported in production only by `runtime/host.rkt` | Exact codec exports/imports and no-effect vocabulary are pinned; wrapped and direct second production imports are rejected. Exhaustive byte and representative Nat round trips prove canonical output without an effect. |
| Raw stdout, filesystem, TCP, registry, and external-failure operations | [`runtime/host.rkt`](../runtime/host.rkt) | Exact `racket/file` and `racket/tcp` imports, host-only primitive identifiers, closed dispatcher vocabulary, and sole-importer scans reject the same capabilities everywhere else in production. Real-host tests prove each approved operation. |
| Request construction, typing, Result control flow, HTTP parsing/rendering/routing/serving | [`effects/`](../effects) | The effect scanner admits only variables, unary lambdas, unary applications, mechanical forms, pure core/effect imports, and application of an injected unary host argument. Exact fake-host traces prove wrappers issue only canonical requests. |
| Public access to the same bridge and bound wrappers | [`lang/expander.rkt`](../lang/expander.rkt) | Exact facade imports/exports and nine fixed injection definitions permit only this module to import and re-export the runtime binding; the facade has no direct OS capability. |
| Process launch and one requested module load | [`runner/attalambda.rkt`](../runner/attalambda.rkt) | The separately trusted, non-exporting runner validates host command/path/header/encoding metadata, emits only fixed sanitized diagnostics, and instantiates one source through the existing language. It imports neither `runtime/host.rkt` nor the codec, observes no lambda value, and is unreachable from every object-language module, so it does not add a language-visible bridge. |
| Host-enabled observation and verification | [`readers/`](../readers), [`tests/`](../tests), and [`tooling/`](../tooling) | These are explicitly nonproduction classes. Reader imports/effects are constrained, every source is inventoried, and every production dependency on any support class is rejected. |

## What this milestone does not claim

The completed phases deliberately do not claim sandboxing or per-program
permission prompts: a real-host program inherits the launching process's
relevant authority. Phases 24 through 27 prove unpublished development
archives, and Phase 28 proves unpublished self-contained `0.2.0-rc.1`
candidates with the exact approved notices, for Linux x86-64, macOS x86_64,
macOS arm64, and Windows x86-64. They do not establish a public download, a
compatibility floor below the exact demonstrated consumers, Windows client-
edition support, a signed artifact, installer behavior, support policy, or
release authority. The language has no
program-argument API, general parser, optimizer, compiler, records, JSON,
environment or process access, directory operations, atomic file replacement,
TLS, UDP, timeouts, asynchronous server, production concurrency, or general
HTTP framework. The minimal HTTP parser/server supports only the documented
blocking HTTP/1.1 subset and one sequential connection at a time. These are
explicit current limits, not new object-language capabilities implied by the
runner.
