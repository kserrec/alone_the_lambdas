# Acceptance evidence

This document maps every completed core and effects requirement to observed
evidence in the repository. The authoritative requirements remain the three
[specifications](specifications/README.md) and the approved
[host-boundary design](design/host-boundary.md); this is their verification
index, not a replacement.

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

| Requirement | Evidence |
| --- | --- |
| `#lang alone_the_lambdas` resolves from a fresh package installation. | [`language-test.rkt`](../tests/language-test.rkt) creates an isolated Racket user home, explicitly stages only package/production files while excluding every dotenv spelling, VCS state, and compiled artifacts and rejecting symlinks, installs that source using [`info.rkt`](../info.rkt), then runs programs outside the installed collection. The install uses declared dependencies only and does not rely on a source-tree collection path or package link. |
| Canonical syntax remains unary lambda computation. | The specification's exact `def`/`if`/`cons` sample shape runs and returns the selected List element. Separate programs prove multi-operand source calls and multi-argument `def` lower to nested unary applications, `let` is immediate unary-lambda application, public `lambda` rejects multiple formals, and a divergent unselected branch is never forced. The existing macro suite retains direct curried-expansion coverage. |
| Nat and String literals are canonical lambda values. | The language suite lowers 0, 1, 255, 256, and 65536, then test-only module-namespace observation passes them through the strict codec and recovers the exact integers. A `λ🙂` source String decodes as exactly six UTF-8 bytes and is emitted byte-for-byte through public `stdout`. Booleans, negative/rational/flonum/complex numbers, characters, byte strings, keywords, vectors, and quoted symbols are rejected during expansion; no additional literal family or parser exists. |
| The facade is canonical and isolated from Racket/internal namespaces. | Runnable programs use only `lambda`, `def`, `let`, `if`, `cons`, strict data operations, bound `stdout`, and explicit `host`. Direct probes prove `define`, `require`, `+`, `display`, `raw-cons`, `typed-if`, `_if`, and quote are unavailable. [`check-boundaries.rkt`](../tooling/check-boundaries.rkt) pins exact facade imports, exports, transformer/helper sets, nine host-injection definitions, source vocabulary, sole host path, the exact reader target, and package metadata; 70 boundary checks prove representative import, export, runtime-definition, syntax-helper, reader, metadata, extra-module, and second-host failures. |

## What this milestone does not claim

The repository now contains the verified core plus the explicit stdout,
whole-file, and blocking-TCP slices of the approved host boundary, plus pure
HTTP request parsing, response rendering, routing, and a blocking sequential
server, plus the fresh-installable standalone language and its Nat/String
literals. It does not yet provide the Phase 20 terse stdout/file/HTTP example
set, final whole-milestone evidence sweep, synchronized setup guide, or a
separate command-line runner. Those remain ordered work and must preserve both
the core purity proof and the boundary classifications.
