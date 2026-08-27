# Host boundary design

Status: proposed; host direction approved, detailed contract approval required
before implementation

Date: 2026-08-27

This document fixes the contract for the second milestone's single privileged
outside-world boundary. It is subordinate to the three canonical
[specifications](../specifications/README.md). Until approved, it authorizes no
production interop code and no relaxation of `AGENTS.md`.

Kyle approved using the single `host` boundary in Alone the Lambdas on
2026-08-27. That settles the high-level language direction. The concrete
request, codec, authority, and runtime contract below remains the separate
implementation approval gate.

## Decision summary

- The public boundary is exactly one unary function: `host`.
- Exact object-language-to-Racket and Racket-to-object-language conversion is
  isolated in `runtime/codec.rkt`; it is trusted conversion code but has no
  operating-system effects, registry, or language-visible export.
- `host` accepts one canonical proper List request.
- A non-List argument or incoming Error follows the existing strict Error
  rules. A malformed List request returns InvalidHostRequest Error. A valid
  request always returns Result.
- The operation set is closed to `stdout`, whole-file read and replacement,
  and blocking TCP connect/listen/accept/read/write/close.
- Every byte crossing the boundary is a Char payload from 0 through 255 inside
  a String. No host String, byte string, path, port, socket, exception, or
  collection becomes an object-language value.
- TCP resources stay in a runtime-owned registry. The language sees only
  nonzero Nat handles that are opaque by convention.
- The runtime inherits the launching process's filesystem and network
  authority. There is no hidden sandbox or permission prompt.
- Effects are synchronous and occur only when a lazy `host` application is
  forced. Sequencing requires an explicit data dependency on the preceding
  Result.

## Boundary type

Conceptually:

```text
host : List -> Error | Result
```

`host` has exactly one object-language argument. It first applies the existing
strict List contract:

- incoming Error: bubble it through `host(arg1 expected LIST)`;
- another typed value: return framed TypeMismatch Error;
- canonical List: validate the request schema in pure lambda computation.

Schema failure returns InvalidHostRequest Error and never enters the trusted
dispatcher. A schema-valid request crosses the privileged boundary and
returns one canonical Result. The dispatcher defensively validates the decoded
shape again, but it never broadens the public contract.

The trusted implementation is split by capability. `runtime/codec.rkt`
performs only exact representation conversion. `runtime/host.rkt` imports
that codec, performs the closed dispatch and approved effects, and exports
only the one `host` value. Neither module exposes a generic callback,
evaluator, namespace, port, dispatcher handle, or codec through the Alone the
Lambdas language surface.

## Request encoding

A request is a proper List with this exact flat shape:

```text
[operation argument ...]
```

`operation` is a typed String containing one canonical lowercase ASCII name.
Every schema has exact arity; trailing elements are invalid. Operation names
are pure String constants generated mechanically at expansion time, following
the established function-name pattern.

| Canonical request | Valid argument constraints | Ok payload |
| --- | --- | --- |
| `["stdout", bytes]` | `bytes : String` | `NIL` after all bytes are written and flushed |
| `["read-file", path]` | `path : String` | complete file contents as String bytes |
| `["write-file", path, bytes]` | `path : String`, `bytes : String` | `NIL` after replacement completes |
| `["tcp-connect", remote, port]` | nonempty `remote : String`; `port : Nat` in 1–65535 | nonzero connection-handle Nat |
| `["tcp-listen", local, port, backlog]` | `local : String`; `port : Nat` in 0–65535; `backlog : Nat` in 1–65535 | two-element List `[listener-handle, bound-port]` |
| `["tcp-accept", listener]` | nonzero handle Nat | nonzero connection-handle Nat |
| `["tcp-read", connection, maximum]` | nonzero handle Nat; `maximum : Nat` in 1–65536 | zero through `maximum` bytes as String |
| `["tcp-write", connection, bytes]` | nonzero handle Nat; `bytes : String` | `NIL` after the complete String is written |
| `["tcp-close", handle]` | nonzero handle Nat | `NIL` after removal and close |

The quotes in the table describe String values; they are not host strings in
the runtime representation.

For `tcp-listen`, `EMPTY-STRING` means all local interfaces. Port zero asks the
operating system for an ephemeral port, and the actual bound port is returned.
Any other local String is passed as the requested interface or hostname.

`tcp-read` blocks until at least one byte is available, EOF is known, or an
external failure occurs. `Ok EMPTY-STRING` means orderly peer EOF, never
failure. `tcp-write` has an all-bytes contract: platform-level partial writes
are completed inside the trusted bridge before Ok is returned. It always
validates the connection handle; with a valid connection, an empty String
succeeds without a platform write.

## Public wrappers

The ordinary effect layer provides strict, curried wrappers with these names:

```text
stdout
read-file
write-file
tcp-connect
tcp-listen
tcp-accept
tcp-read
tcp-write
tcp-close
```

Each wrapper validates its normal typed arguments through the generalized
checker, constructs one request with pure List/String/Nat computation, and
applies its injected unary `host`. The wrapper itself contains no Racket
effect. Internal wrapper builders accept a host function first so tests can
inject a deterministic fake; the standalone language binds them once to the
real production `host`.

This higher-order injection is ordinary lambda calculus. It does not create a
second privileged primitive.

## Result and Error contract

Every schema-valid request returns Result:

- Ok contains exactly the payload listed in the request table.
- Err contains a canonical HostFailure Error.

Two new Error kinds use the permitted tiny Church metadata namespace without
changing the closed type-tag table (kind 6 is the core's
WRONG-RESULT-VARIANT):

```text
7  INVALID-HOST-REQUEST
8  HOST-FAILURE
```

Both kinds use the existing Error-root shape. Their `details` field is exactly
one raw lambda pair; no record, host collection, or new object type is added:

```text
InvalidHostRequest details = raw-pair(operation String, reason String)
HostFailure details         = raw-pair(operation String, code String)
```

If an operation String cannot be recovered, `operation` is `EMPTY-STRING`.
The closed reasons are:

```text
unknown-operation
wrong-arity
wrong-type
out-of-range
```

The closed external failure codes are:

```text
not-found
permission-denied
invalid-path
invalid-text
invalid-handle
wrong-handle-kind
address-in-use
connection-refused
connection-reset
broken-pipe
network-unreachable
name-resolution-failed
resource-exhausted
timed-out
io-failure
```

The bridge maps the most specific stable Racket/OS category available and uses
`io-failure` as the fallback. It never places raw exception text, errno data,
paths, hostnames, or host values in an Error. Readers may render the two pure
String detail fields later.

Malformed direct `host` calls are contract failures and therefore bare Error,
not Result Err. A valid request rejected by the operating system is expected
external failure and therefore Result Err. This preserves the existing
Error-versus-Result distinction.

## Boundary codecs

Request construction is not boundary conversion. `effects/protocol.rkt` and
the public wrappers construct and validate lambda-encoded requests using pure
object-language computation. Only a schema-valid request reaches the trusted
runtime.

Here, codec means exact representation conversion, not compression or text
encoding. `runtime/codec.rkt` is the one deterministic bidirectional
conversion module. It may force already-validated lazy object-language
values, inspect their canonical lambda representations, and use Racket
control flow, exact nonnegative integers, immutable byte strings, and
temporary private collections solely to translate representations. Each
implementation phase may add only the conversions needed by the operations
implemented in that phase:

- object-language Char and String values to exact host bytes and exact host
  bytes back to canonical object-language Char and String values;
- object-language Nat values to exact host integers and exact nonnegative host
  integers back to normalized object-language Nat values when TCP handles and
  bounds are added;
- the proper Lists, typed acknowledgements, Result values, and Error values
  needed to return the closed response algebra.

Object-language-to-host decoding defensively checks the expected tag, proper
List shape, Char range, and normalized Nat representation even though pure
protocol validation has already run. A conversion failure returns the
applicable InvalidHostRequest reason without dispatching an effect.
Host-to-object-language encoding always constructs canonical values: zero is
`[0]`, positive Nats have no leading zeroes, every Char is 0 through 255, every
List has a List tail, and no Racket value is captured inside the returned
lambda term.

The codec does not interpret paths or hostnames, dispatch operations, perform
stdout/file/TCP access, normalize operating-system exceptions, mutate the
handle registry, implement object-language algorithms, or format values for
people. It does not import any reader. Raw stdout, file, and TCP content
remains bytes; only `runtime/host.rkt` applies the separately specified UTF-8
rule when a decoded byte sequence is used as a path or network name.

The codec is internal trusted infrastructure, not a second object-language
primitive. Only `runtime/host.rkt` may import it in production. Tests may
import it directly to prove exact round trips, canonical output,
malformed-value rejection, and absence of effects.

## Byte, path, and file semantics

All boundary content is bytes:

```text
one object Char  <->  one host byte
one object String  <->  one immutable host byte sequence at the bridge
```

No newline, character encoding, or text normalization is implicit for stdout,
file contents, or TCP payloads.

Path Strings and TCP host/interface Strings are the one exception: their byte
content must be valid UTF-8 and is decoded to a host text value at the bridge.
Invalid UTF-8 returns Result Err with `invalid-text`; a decoded path rejected
by the host returns `invalid-path`. Arbitrary non-UTF-8 filesystem names are
outside this milestone.

Relative paths resolve against the launching process's current directory.
Absolute paths are allowed. Host-default symlink traversal applies. The
runtime creates no parent directories and performs no path sandboxing.

`read-file` reads the complete regular file as bytes. `write-file` creates a
missing file or truncates and replaces an existing file's contents. It is not
an atomic replace operation. A failed write may therefore leave a partial
file, exactly as documented; later atomic-file APIs would require a separate
approved operation.

`stdout` writes raw bytes to the process's current standard-output port and
flushes before Ok. It does not append a newline and does not write stderr.

## TCP handles and lifecycle

The trusted runtime owns a registry whose entries are either listeners or
full-duplex connections. Handles:

- are canonical nonzero Nat values;
- begin at ONE within one runtime instance;
- increase monotonically and are never reused in that instance;
- have no arithmetic meaning despite their Nat representation;
- cannot be transferred to another process or runtime instance.

A fabricated, closed, or foreign handle is structurally valid but resolves to
Result Err `invalid-handle`. Using a listener where a connection is required,
or the reverse, returns `wrong-handle-kind`.

`tcp-connect`, `tcp-listen`, and `tcp-accept` register a resource only after
successful acquisition. `tcp-close` removes the entry and closes the complete
listener or both sides of a connection. A second close returns
`invalid-handle`. When the runtime shuts down, it closes every remaining
registry entry. Acquired handles must also be closed on every wrapper/server
path that has finished with them.

The initial TCP surface is deliberately blocking. It has no timeout argument,
half-close, readiness API, TLS, UDP, async, production threads, or
cancellation. Hostname resolution performed as part of `tcp-connect` is
inside that one requested effect.

## Laziness and effect order

Constructing a request has no effect. Applying `host` creates a lazy
computation; the effect occurs when its Result or Error is demanded. A forced
promise caches its result, so forcing the same bound host application again
does not repeat the effect. Evaluating a new host application performs a new
effect.

Effect order is expressed through a real data dependency:

1. force and inspect the first Result;
2. branch on Ok or Err with the strict lazy `if`;
3. construct the next host application only in the selected continuation.

Merely placing two calls beside one another or binding an unused first result
does not sequence them. No `begin`, mutation, hidden scheduler, or host control
flow is added to the object language.

## Authority and trust

Running an Alone the Lambdas program with the real host grants it the same
relevant authority as the launching Racket process:

- it can write arbitrary bytes to stdout;
- it can read any file the process may read;
- `write-file` can create, truncate, and overwrite any path the process may
  write, including a symlink target;
- it can resolve names, connect to remote TCP endpoints, and bind listening
  ports permitted by the operating system.

There is no Mirafold-style approval prompt, project-root jail, or automatic
backup. Users must trust a program before running it with the real host. Tests
use captured stdout, isolated temporary directories, and loopback networking.

The closed operation set does not expose environment enumeration, subprocesses,
shell commands, dynamic loading, `eval`, Racket namespaces, arbitrary FFI,
filesystem listing/deletion/rename, clocks, randomness, UDP, TLS, or HTTP host
libraries.

## Modules and dependency direction

The implementation, once approved, will add only demonstrated files within
these layers:

```text
core/                 unchanged pure data and computation
effects/protocol.rkt  pure request validation, constants, and Error data
effects/stdout.rkt    pure injected-host wrapper
effects/files.rkt     pure injected-host wrappers
effects/tcp.rkt       pure injected-host wrappers
runtime/codec.rkt     trusted exact conversion; no operating-system effects
runtime/host.rkt      sole language host binding, dispatcher, effects, registry
lang/                 future standalone reader, expander, and facade
```

Dependencies are one-way:

```text
core <- effects <- lang
core <- runtime/codec <- runtime/host <- lang
core <- effects/protocol <- runtime/host
```

`core/` never imports upward. `effects/` never imports `runtime/`; it receives
one host function as an ordinary lambda argument. `runtime/codec.rkt` imports
only the core representations and the narrowly allowed Racket facilities
needed for exact conversion. No production module except `runtime/host.rkt`
may import the codec. The host module imports the codec and protocol, performs
the approved effects, and constructs responses through the codec. Human-facing
readers remain outside the computational dependency graph and are not reused
as bidirectional codecs.

## Purity classifications

Phase 14 must update tooling and project rules to enforce these distinct
classes:

| Class | Allowed boundary | Required check |
| --- | --- | --- |
| `core/` | none | Existing absolute unary-lambda/application scan; `host` remains forbidden |
| `effects/` | invocation of its injected unary host argument only | Same pure-form scan plus no Racket effect imports or definitions |
| `runtime/codec.rkt` | deterministic canonical conversion between object-language values and private host bytes/integers/collections | Exact-path conversion scan, narrow import allowlist, no I/O or network imports, no mutation or registry, no reader imports, and no language-visible export |
| `runtime/host.rkt` | only the approved byte/file/TCP operations, UTF-8 interpretation, exception normalization, and private registry state | Exact-path effect scan, import allowlist, sole exported `host`, sole production codec importer, and forbidden eval/process/FFI/environment capabilities |
| `lang/` | mechanical expansion and import/export wiring | No OS operations; one import of production `host`; literal expansion produces pure terms |
| `macros/` | mechanical syntax translation | Existing macro classification |
| `readers/` | one-way human observation | Must not enter core/effect computation |
| `tests/` and `tooling/` | host facilities needed to verify the claim | Never imported by production computation |

Repository checks must prove:

- exactly one production module defines and exports `host`;
- no production module except `runtime/host.rkt` imports the codec or Racket
  filesystem/TCP facilities;
- the codec imports no effects, readers, filesystem, TCP, process, eval,
  dynamic-loading, environment, FFI, or mutation facilities;
- no production module imports process, eval, dynamic-loading, environment,
  or FFI facilities;
- every pure production lambda is unary after mechanical expansion;
- every wrapper's fake-host trace contains only its canonical request;
- every implemented codec direction has exact round-trip, canonicality, and
  malformed-value coverage;
- `core/` retains zero exceptions and all existing acceptance evidence.

Approval changes only the deliberate `host` exception. It does not authorize
host implementation of parsing, routing, arithmetic, String algorithms, type
checking, Result control flow, or other ordinary language behavior.

## Verification strategy

Each implementation phase must have both deterministic and real-boundary
coverage:

- codec: all 256 byte/Char values, empty and embedded-zero Strings,
  representative Nat boundaries when added, canonical output, malformed input,
  and proof that conversion itself performs no effect;
- fake host: exact request shape, no call after contract Error, result
  propagation, failure propagation, branch laziness, and call count;
- stdout: byte capture and flush-visible completion;
- files: isolated temporary directory, replacement warning, binary round trip,
  missing path, permission failure where the platform can prove it, and no
  unrelated path access;
- TCP: loopback only, ephemeral listen port, fragmented reads, EOF, complete
  writes, wrong/stale handles, and cleanup;
- HTTP: test-side external client, while parsing/routing/rendering remain under
  the pure scan;
- laziness: an unforced or unselected host application performs no effect, and
  repeated forcing of the same promise performs exactly one.

No test contacts an external network service or reads/writes outside its
temporary scope.

## Standalone surface decisions

The future language exports canonical `lambda`, `def`, `let`, typed `if`,
typed `cons`, the public data API, these effect wrappers, and the single
explicit `host`. Internal raw operations and Racket collision workarounds stay
hidden.

The standalone reader keeps Lisp syntax. Nonnegative integer literals lower
mechanically to canonical binary Nat. Source String literals lower
mechanically to their UTF-8 bytes, with one object Char per encoded byte. No
host number or String survives expansion, and no general parser, reader-time
effect, coercion, or additional literal family is introduced.

## Reuse from `all_the_lambdas`

The verified reusable pattern is narrow:

- its `macros/lazy-with-macros.rkt` demonstrates a small language shell that
  re-exports Lazy Racket application and datum machinery;
- its macro modules demonstrate mechanical lowering under `#lang s-exp`.

Alone the Lambdas already supersedes the old finite-arity `def`. The old
repository has no host dispatcher, filesystem/TCP layer, HTTP server, custom
language reader, or standalone runtime to borrow. Its `_if`, `_let`, `_cons`,
coercive layers, and older representations remain explicitly inapplicable.

## Feasibility references

The design relies only on documented host behavior:

- [Lazy Racket](https://docs.racket-lang.org/lazy/) delays applications,
  treats imported strict functions as strict, and exposes effects when their
  promises are forced.
- [Racket promises](https://docs.racket-lang.org/reference/Delayed_Evaluation.html)
  cache a forced result.
- [Racket TCP](https://docs.racket-lang.org/reference/tcp.html) provides the
  blocking listener/connection operations and supports port zero with bound
  port discovery.
- [Racket byte strings](https://docs.racket-lang.org/reference/bytestrings.html)
  represent exact byte values from 0 through 255.

These are implementation feasibility facts, not object-language semantics.

## Approval gate

Approval accepts the request schemas, Result/Error split, byte and path rules,
destructive replacement behavior of `write-file`, process-level authority,
blocking TCP lifecycle, separated codec/host trust boundary, purity
classifications, and standalone literal policy defined above.

Kyle approved the high-level use of `host` on 2026-08-27. That approval does
not by itself approve these detailed implementation boundaries.

Until Kyle explicitly replies:

```text
Approve the Phase 13 host-boundary design.
```

Phase 14 remains blocked. Questions or requested revisions do not authorize
implementation.
