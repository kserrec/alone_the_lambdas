# Acceptance evidence

This is the compact evidence map for the implemented language. The three
[language specifications](specifications/README.md) define the contract; tests
and structural checkers show how the repository enforces it. Historical phase
completion is recorded in [`PLAN-ARCHIVE.md`](../PLAN-ARCHIVE.md), and binary
release facts are in the
[standalone-distribution ledger](design/standalone-distribution.md).

Run [`run-all-tests.sh`](../run-all-tests.sh) for the source acceptance gate.
It runs every test suite, the expanded purity proof, and the repository-wide
boundary inventory. The released 0.3.0 source passed 38 suites with 12,298
assertions, all 29 pure production modules, and the complete boundary scan.

## Language criteria

| Criterion | Executable evidence |
| --- | --- |
| Production computation expands to variables, unary lambdas, and unary application. | [`check-purity.rkt`](../tooling/check-purity.rkt) expands and inspects every `core/` and `effects/` module; [`purity-test.rkt`](../tests/purity-test.rkt) proves forbidden host forms and non-unary lambdas are rejected. |
| Public syntax is `lambda`, `def`, `let`, `if`, and the specified `cons`; literals expand mechanically. | [`macros-test.rkt`](../tests/macros-test.rkt) covers hygiene and generated terms; [`language-test.rkt`](../tests/language-test.rkt) covers the installed `#lang attalambda` surface, shadowing, and rejected names/literals. |
| Values carry closed Church type tags, and one arbitrary-arity checker owns strict runtime typing. | [`tags-test.rkt`](../tests/tags-test.rkt), [`objects-test.rkt`](../tests/objects-test.rkt), [`typecheck-test.rkt`](../tests/typecheck-test.rkt), and [`errors-test.rkt`](../tests/errors-test.rkt) cover tags, positions, partial application, laziness, and early Error absorption. |
| Bool and strict `if` preserve typed, lazy branch choice. | [`logic-test.rkt`](../tests/logic-test.rkt) and [`typed-logic-test.rkt`](../tests/typed-logic-test.rkt) prove canonical values, wrong-type Errors, chosen-branch forcing, and unchosen-branch laziness. |
| List uses the Michaelson representation; `NIL` is distinct from false and zero, and every tail is a List. | [`lists-test.rkt`](../tests/lists-test.rkt) and [`errors-test.rkt`](../tests/errors-test.rkt) cover proper construction, operations, contracts, and malformed tails. |
| Rat is the only public number; private Nat/Int representations remain canonical. | [`binary-nat-test.rkt`](../tests/binary-nat-test.rkt), [`int-test.rkt`](../tests/int-test.rkt), [`rat-test.rkt`](../tests/rat-test.rkt), and [`typed-rat-test.rkt`](../tests/typed-rat-test.rkt) cover normalized binary magnitude, one signed zero, reduced fractions, exact arithmetic, comparison, division, powers, and strict wrappers. [`language-test.rkt`](../tests/language-test.rkt) proves retired public Nat/Int names do not resolve. |
| Exact integer and fraction literals become canonical Rats; inexact and complex numbers are rejected. | [`language-test.rkt`](../tests/language-test.rkt) round-trips representative positive, negative, fractional, zero, and large literals through the codec and rejects floating-point, infinity, NaN, and complex forms. |
| Error represents contract/invariant failure; Result Err represents expected computational failure. | [`errors-test.rkt`](../tests/errors-test.rkt) pins distinct kinds and argument positions; arithmetic, file, TCP, and HTTP suites prove the Error/Result boundary. |
| Char is a byte-valued character, Byte has exactly 256 values, String is `List Char`, and binary payloads are `List Byte`. | [`chars-test.rkt`](../tests/chars-test.rkt), [`byte-test.rkt`](../tests/byte-test.rkt), [`strings-test.rkt`](../tests/strings-test.rkt), [`codec-test.rkt`](../tests/codec-test.rkt), and real file/TCP host tests cover canonical conversion and byte-exact round trips. |
| Unit carries successful no-value results; Option represents expected absence; Map is persistent and pure. | [`unit-test.rkt`](../tests/unit-test.rkt), [`option-test.rkt`](../tests/option-test.rkt), and [`map-test.rkt`](../tests/map-test.rkt) cover tags, operations, contracts, laziness, persistence, and custom equality. |
| Effects construct typed requests and invoke only the injected unary host. | [`stdout-test.rkt`](../tests/stdout-test.rkt), [`files-test.rkt`](../tests/files-test.rkt), and [`tcp-test.rkt`](../tests/tcp-test.rkt) use fake-host traces to pin request shape, order, validation precedence, and one invocation. |
| The host implements exactly stdout, whole-file I/O, and blocking TCP operations. | [`host-test.rkt`](../tests/host-test.rkt), [`file-host-test.rkt`](../tests/file-host-test.rkt), and [`tcp-host-test.rkt`](../tests/tcp-host-test.rkt) exercise all nine routes, native failures, binary data, partial writes, bounds, handles, and cleanup. |
| Pure HTTP values, parsing/rendering, routing, and the sequential server stay lambda-built. | [`http-test.rkt`](../tests/http-test.rkt) and [`http-server-test.rkt`](../tests/http-server-test.rkt) cover the documented HTTP/1.1 subset, limits, routing, byte conversion, host traces, and real loopback behavior. |
| A source file runs through the public language without exposing loader machinery. | [`runner-test.rkt`](../tests/runner-test.rkt), [`language-test.rkt`](../tests/language-test.rkt), and [`milestone-two-acceptance-test.rkt`](../tests/milestone-two-acceptance-test.rkt) cover paths, diagnostics, one load, public examples, effects, Error/Err completion, and the foundational values together. |

## One privileged bridge

| Boundary fact | Sole production location | Enforcement |
| --- | --- | --- |
| Definition and producer export of `host` | [`runtime/host.rkt`](../runtime/host.rkt) | The boundary checker requires exactly one definition and sole export, locks its imports and vocabulary, and rejects another producer. |
| Deterministic lambda/host conversion | [`runtime/codec.rkt`](../runtime/codec.rkt), imported in production only by the host | Exact exports and imports are checked; the codec has no effects or registry. Codec tests prove canonical conversion, malformed-value rejection, and cycle handling. |
| Native stdout, filesystem, DNS, TCP, handle registry, and failure mapping | [`runtime/host.rkt`](../runtime/host.rkt) | Closed imports, host-only primitives, dispatcher vocabulary, and production-wide scans reject the capabilities elsewhere. Real-host suites exercise each route. |
| Request construction and all higher computation | [`effects/`](../effects) | The expanded purity scanner permits only pure core/effect dependencies and application of the injected unary host argument. Fake-host tests pin canonical requests. |
| Public binding of that host to the nine wrappers | [`lang/expander.rkt`](../lang/expander.rkt) | Exact facade imports/exports and fixed injection definitions allow this module to import and re-export the host without direct operating-system capability. |
| Process launch and one requested module load | [`runner/attalambda.rkt`](../runner/attalambda.rkt) | The non-exporting runner validates only its requested source, emits fixed diagnostics, imports neither host nor codec, observes no lambda value, and is unreachable from production computation. |
| Observation, tests, and repository checks | [`readers/`](../readers), [`tests/`](../tests), and [`tooling/`](../tooling) | These nonproduction classes are inventoried separately. Reader capability is constrained, unknown source locations fail closed, and production dependencies on support code are rejected. |

[`check-boundaries.rkt`](../tooling/check-boundaries.rkt) owns this complete
inventory. It also pins public exports, allowed dependency directions,
privileged imports, reader limits, runner limits, and the exact source classes.

## Standalone acceptance

The [standalone contract](design/standalone-distribution.md) fixes the command,
source validation, diagnostic statuses/text, version projection, Racket CS 9.3
build, archive layout, legal bytes, and supported platform. The distribution
suite checks all build/consumer scripts and the CI workflow. The Linux consumer
then verifies a real archive in digest-pinned Ubuntu 24.04 without Racket or a
checkout, including checksum, guide commands, relocation, stdout, file/TCP/HTTP
behavior, and fixed launcher failures.

The 0.3.0 publication used release commit `1b51603` and annotated tag
`v0.3.0`. Its sole binary archive is 13,938,743 bytes with SHA-256
`7adc7343720b0a1d6ed86af47059f031f571ab93649a314303c56d6b8a3d7870`.
It passed the independent no-Racket consumer before upload and matched a fresh
public download afterward. Building or testing a future archive grants no
publication authority.

## Limits and deferred finding

The project does not claim sandboxing or per-program permission prompts. A
real-host program inherits the launching process's relevant authority. It has
no program-argument API, general parser, optimizer, compiler, records, JSON,
environment or process access, directory operations, atomic file replacement,
TLS, UDP, timeouts, asynchronous server, production concurrency, or general
HTTP framework. The HTTP server implements only its documented blocking
HTTP/1.1 subset and serves one connection at a time. Linux x86-64 is the sole
supported public binary; no compatibility floor below the exact Ubuntu 24.04
consumer, signature, installer, or broader support policy is claimed.

AttaLambda is an interpreted lazy-lambda tower. Rat arithmetic reduces through
binary gcd and is orders of magnitude slower than host arithmetic. Map lookup
walks linearly and calls a lambda-encoded equality at each entry.

**Deferred finding:** request buffering is capped at 8,192 bytes, preventing
unbounded memory growth, but the pure HTTP parser re-parses the accumulated
request after each received chunk. One connection can therefore consume
O(cap²) interpreter work before rejection. Correcting the complexity requires
an incremental parser redesign rather than a local hardening patch. The fixed
cap makes the cost bounded; this remains a documented performance limitation.

## Material corrections before 0.3.0

The Milestone 4 branch received an adversarial review before release. All ten
confirmed findings were fixed in commit `3254354` and independently reviewed.
The lasting corrections were:

- new Error kinds moved to 14, 15, and 16 after collision with the existing
  HTTP kind 13, and all kinds are pairwise pinned;
- `MAKE-STRING` and `DROP` restore canonical `NIL` on empty results;
- codec List decoding uses linear Floyd cycle detection and canonical cached
  Byte/Char objects;
- the expanded purity proof includes the entire effects layer;
- TCP tests use a raw peer where crossing a lazy promise between threads would
  violate Racket's re-entrant-promise rule.

The earlier HTTP security pass added the 8,192-byte request cap after proving
that hostile peers could otherwise cause unbounded buffering. These corrections
are part of the current implementation, not open work.
