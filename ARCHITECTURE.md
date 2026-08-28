# Architecture

This document records both the target architecture and the verified current
state. Phase 1 implements the lazy host shell, mechanical syntax, lambda pairs,
and raw Boolean logic. Phase 2 adds the seven Church tags, the generic
lambda-encoded typed-object shape, external observation, and a structural
purity gate that rejects host computation and host data. Phase 3 adds explicit
Michaelson-style Lists, strict bootstrap primitives, and raw recursive List
algorithms. Phase 4 adds normalized binary Nat values, direct raw binary
arithmetic and comparison, and the Nat-dependent List operations. Phase 5
replaces provisional failures with structured Error roots and propagation
frames. Phase 6 adds the single generalized curried runtime checker, its
signature-driven Error absorbers and return policies, and migrates every
eligible bootstrap List operation onto it. Phase 7 adds tagged Bool values,
strict checker-backed Boolean operations, and the canonical lazy typed
conditional. Phase 8 adds the strict checker-backed Nat API without changing
the raw binary algorithms. Phase 9 adds lambda-encoded Result values, strict
Result operations, raw binary long division, and safe typed `DIV`. Phase 10
adds bounded binary Char values, strict construction, lambda-built constants,
and a one-way host reader. Phase 11 adds Char-List-backed String values,
recursive invariant validation, the initial strict String algorithms, and a
one-way String reader. Phase 12 adds pure canonical String names to every
strict Error boundary, renders structured diagnostics at the one-way reader
boundary, hardens the production purity gate, and closes the milestone with
criterion-level acceptance coverage. Phase 13 fixes the approved host request
protocol, trust boundary, module split, and future purity classifications in a
design document. Phase 14 implements the first approved slice: deterministic
String-byte conversion, pure stdout request construction, one unary `host`,
raw stdout output, and structural enforcement of the new boundary classes.
Phase 15 extends that same closed boundary with pure `read-file` and
`write-file` wrappers, UTF-8 path interpretation inside the host, byte-exact
whole-file reads and replacement writes, and closed external-failure mapping.
Phase 16 adds pure blocking TCP request wrappers, canonical Nat/host-integer
conversion, a private monotonic listener/connection registry, complete writes,
bounded reads, explicit close, and loopback-only integration coverage. Phase
17 adds a pure minimal HTTP/1.1 request parser, lambda-computed response
rendering, byte-accurate decimal content lengths, and focused protocol/purity
coverage without extending the host. Phase 18 composes those message functions
with the injected-host TCP wrappers into one-connection serving and a blocking
sequential loop, with routing and status/body selection performed by an
ordinary unary lambda handler.
Phase 19 adds the single-collection `#lang alone_the_lambdas` reader and
facade, canonical public syntax, one-time real-host injection for the nine
effect wrappers, mechanical currying of multi-operand source applications,
and canonical Nat/String literal expansion. Phase 20 adds three exact runnable
applications, executes all four specified effect families from a copied fresh
installation, inventories every Racket source class, strengthens reader and
support-code dependency rules, and closes the milestone evidence map without
changing production semantics or host authority. Phase 21 fixes and approves
the independent-distribution contract and proves Racket 9.3 can embed the
dynamic language closure. Phase 22 adds one exact development runner, the
canonical `.atl` application names, and a single `0.2.0-dev` version source;
the runner delegates to the existing reader/expander and remains outside every
object-language dependency path.

## Computational boundary

The object language is pure untyped lambda calculus:

1. variables;
2. exactly unary `lambda`;
3. application.

Every ordinary computationally meaningful production term must contain only
those forms after mechanical macro expansion. Multi-argument functions are
nested unary lambdas, and partial application is ordinary application. The
single deliberate exception is the explicit unary `host` value in
`runtime/host.rkt`; no other host-computation escape hatch exists.

Racket supplies the enclosing module system, lazy evaluation, syntactic sugar,
readers, tests, development tooling, deterministic private conversion in
`runtime/codec.rkt`, the approved effects in `runtime/host.rkt`, and the
separately classified command/path/module-loading scaffolding in
`runner/atl.rkt`. It must not decide ordinary object-language results or
become an object-language representation.

> Alone the Lambdas does not merely avoid using host libraries for major
> algorithms. Its production computational terms are built exclusively from
> unary lambda abstraction and application. Every multi-argument function is
> represented by nested one-argument lambdas. Racket is used only to
> host/evaluate the terms, provide mechanical syntactic sugar and module
> tooling, test them, and observe completed values for humans. The explicitly
> introduced unary `host` is the sole privileged boundary; no other
> computational escape hatch exists.

## Layers

| Layer | Responsibility |
| --- | --- |
| Host shell | Racket modules, `#lang lazy`, exports, test and reader plumbing |
| Mechanical syntax | `def`, lambda-based `let`, and other expansion-only sugar |
| Raw calculus | Pairs, raw Boolean selectors, tags, and untyped algorithms |
| Typed objects | Uniform tag/payload representation and strict validation |
| Public data | List, Nat, Error, Result, Char, and String |
| Pure effects | Lambda request validation, protocol computation, and wrappers over an injected unary host |
| Boundary codec | Exact private representation conversion; no operating-system effects |
| Privileged host | Sole `host` export and operations approved through the current phase |
| Public language | Canonical exports such as `lambda`, `def`, `let`, `if`, and `cons` |
| Runner scaffolding | Exact command, path/header validation, version display, and one existing-language module instantiation; no exports or object values |
| Runnable applications | Public-language hello/stdout, isolated file round trip, and one-request ephemeral-loopback HTTP server |
| Human boundary | Readers and test diagnostics; never object-language computation |

Dependencies point downward only. Typed operations may use raw operations; raw
operations must not depend on typed wrappers. Readers may inspect values but
production code must never depend on readers.

## Implemented foundation

The implemented dependency path is deliberately short. The lazy module shell
sits under the mechanical macro layer. Pair and logic depend on that
foundation; tags depend on raw logic; typed objects depend on pairs and tags.
Fixed-point recursion ties canonical `NIL` and its canonical empty-List Error
inside `core/errors.rkt`; Lists then depend on that lower representation knot.
Readers are test-only, and no production module depends on them. Binary Nat
depends on the raw List representation; `core/list-nat.rkt` sits above both
modules so Nat-dependent List operations do not create a dependency cycle.
The checker reads its List signatures through the lower object and pair
representation instead of importing `core/lists.rkt`; this lets the ordinary
typed List operations depend on the checker without a cycle. Typed logic sits
above raw logic, objects, Lists, and the checker; this keeps its List-encoded
signatures and strict wrappers out of the raw Boolean layer.
`core/typed-nat.rkt` similarly sits above binary Nat, Lists, tags, and the
checker. It owns the public strict Nat surface while leaving every binary
algorithm in `core/binary-nat.rkt` raw and reusable.
`core/result.rkt` sits above Errors, Lists, objects, and the checker. Typed Nat
depends on Result only for safe `DIV`, so Result itself remains independent of
Nat and available to later data types.
`core/chars.rkt` sits above raw binary Nat, Errors, Lists, objects, and the
checker. Its reader depends on Char and Nat observation, while no production
module depends on that reader. `core/strings.rkt` sits above Char, List, raw
List length, Errors, objects, and the checker. It reuses those raw layers
directly, while `readers/string.rkt` remains outside the production dependency
graph.

`effects/protocol.rkt`, `effects/stdout.rkt`, `effects/files.rkt`,
`effects/tcp.rkt`, `effects/http.rkt`, `effects/http-response.rkt`, and
`effects/http-server.rkt` remain ordinary lambda computation. The host
protocol validates
canonical flat requests, exact arity, types, and TCP bounds before invoking
its injected strict dispatcher; the wrapper modules construct only the closed
stdout, whole-file, and six-operation blocking TCP request algebra. The HTTP
message modules instead parse and render lambda Strings directly: the strict
parser returns the origin-form target for exact GET/HTTP/1.1 requests with one
Host field, while the separately analyzable renderer owns the four supported
status phrases,
`Content-Length`, `Connection: close`, CRLF framing, and body concatenation.
These line and framing choices follow
[RFC 9112](https://www.rfc-editor.org/rfc/rfc9112.html); methods, target forms,
versions, bodies, pipelining, and statuses outside the deliberately stated
subset return Result Err rather than expanding into a general HTTP framework.
The server accepts a caller-owned listener handle, accumulates bounded TCP
reads until the parser resolves a request, passes the target String to a unary
handler, writes only a validated Ok response String, and closes every accepted
connection. Its single-path handler factory compares targets and selects the
explicit status/body branch in the lambda layer; `make-http-serve-one` handles
one connection and `make-http-server` repeats successful connections
sequentially until a Result Err or Error. The listener remains caller-owned so
ephemeral bound-port discovery and explicit lifetime management stay visible.
None imports `runtime/`. The trusted `runtime/codec.rkt` converts exact
List/Char/String/Nat shapes to private immutable bytes and integers and
constructs canonical response values without effects or mutation.
`runtime/host.rkt` alone imports that codec and alone defines the privileged
`host`; it is the direct producer export, and the standalone facade re-exports
that same binding once. Its Phase 16 dispatcher writes and flushes raw bytes to the current
stdout port, interprets path and network-name bytes as UTF-8, performs complete
file reads and truncating replacement writes, and owns blocking TCP resources
behind monotonically increasing Nat handles. Expected external failures become
Result Err HostFailure values with closed codes, while malformed direct
requests remain bare InvalidHostRequest Error values.

Named Error frames would create a cycle if Errors depended on the full String
module. `core/errors.rkt` therefore owns the raw List cell constructor
`raw-cons` alongside `NIL`; `core/lists.rkt` re-exports it, and
`core/function-names.rkt` builds its String constants from that constructor
plus the lower object, tag, and raw-logic layers. The `define-function-name`
macro translates an identifier spelling to UTF-8 bytes and generates one Char
per byte using those pure constructors. Racket computes syntax during
mechanical expansion; every generated runtime value is still a tagged String
containing a proper List of tagged Chars limited to 0 through 255. Strict
modules depend on these name constants, while Errors remain below String
algorithms.

`def` mechanically builds any requested arity as nested unary lambdas.
`lambda-let` expands one binding into one unary-lambda application; the
standalone facade exports that binding as canonical `let`. `raw-if` is an
ordinary curried selector function, not a host conditional. The reader forces
and formats raw Booleans only from outside production computation. The strict
conditional remains internally named `typed-if`; `core/typed-logic.rkt` also
exports that binding under canonical `if` without changing internal raw names.

`lang/reader.rkt` delegates ordinary Lisp reading to
`syntax/module-reader` and selects `lang/expander.rkt`; there is no separate
parser. The expander exposes only canonical language syntax, strict typed data
operations, the pure HTTP API, the nine host-bound effect names, and the one
explicit `host`. Its public `#%app` mechanically rewrites every multi-operand
source call into nested unary applications, while public `lambda` accepts
exactly one formal. Its `#%datum` consumes only exact nonnegative integers and
source Strings at expansion time, generating canonical binary Nat or
List-of-Char String construction with one Char per UTF-8 byte. No host number
or host String becomes an object-language value. A custom module wrapper
forces top-level effects but discards their lambda-encoded Results so Racket
does not print host procedure representations. `info.rkt` supplies the
single-collection package metadata used by fresh installs. Root `VERSION` is
the sole product-version source; the current `0.2.0-dev` state projects
mechanically to Racket package version `0.1.900`.

`runner/atl.rkt` is host launch scaffolding, not an effect primitive. It
accepts only `run`, `--help`, and `--version`; validates the one supplied path,
exact `.atl` suffix, dotenv exclusions, final-entry symlink rule, resolved
parent, regular-file metadata, and exact declaration; then invokes
`dynamic-require` once on that source. It exports nothing, imports no project
module, observes no completed lambda value, and has no environment, process,
directory-scan, network, namespace, evaluator, codec, or reader import.

The four files under `examples/` import nothing and run only through that
public language. `hello.atl` and `stdout.atl` each emit one String.
`file-round-trip.atl` makes
write-before-read sequencing explicit by inspecting the first Result; tests
run it only in an empty temporary directory because `write-file` deliberately
truncates its target. `http-server.atl` listens on loopback port zero, formats
the returned bound Nat as decimal using public lambda operations, announces
the exact URL, serves one request through `make-http-serve-one`, explicitly
closes the caller-owned listener, and exits. No example adds a production
module, primitive, wrapper, or authority.

`core/tags.rkt` defines Church zero through six for Error, Bool, List, Nat,
Result, Char, and String. The same tiny Church values may serve in separate
metadata namespaces such as Error kinds and argument positions. Its private
predecessor and subtraction terms exist only to implement `raw-tag-equal`;
they are not a public arithmetic system. `core/objects.rkt` represents a typed
object as a lambda pair of tag and payload. `raw-object-type`,
`raw-object-value`, and `raw-is-type` operate only on canonical project
objects, not arbitrary untyped lambda terms.

## Representation contracts

### Tiny discriminants

The seven runtime type tags use Church numerals:

| Tag | Type |
| ---: | --- |
| 0 | Error |
| 1 | Bool |
| 2 | List |
| 3 | Nat |
| 4 | Result |
| 5 | Char |
| 6 | String |

Tags are closed discriminants, not public arithmetic values. Structured Error
kinds and argument positions also reuse tiny Church values as explicitly
permitted metadata. Ordinary numeric computation always uses binary Nat.

### Objects

A runtime-typed object carries a tag and payload using lambda-encoded
structure. The representation must remain entirely inside the calculus.

### Booleans and conditional

`TRUE` and `FALSE` are Bool-tagged objects containing `raw-true` and
`raw-false`. `typed-not`, `typed-and`, `typed-or`, and `typed-xor` use the
generalized checker with List signatures, unwrap their Bool inputs, run the
existing raw operations, and wrap the raw result as Bool. The module also
exports the specified `NOT`, `AND`, `OR`, and `XOR` names.

`typed-if` validates only its tagged Bool condition because both branches are
intentionally polymorphic. A valid condition unwraps to the raw selector and
chooses without forcing the other branch. A wrong condition or incoming Error
returns two unary ignoring continuations before exposing the failure, so the
conditional retains its full curried application shape. The generalized
monomorphic checker remains unchanged, as the specification allows.

### Lists

Lists use an explicit Michaelson-style representation. A nonempty List is a
List-tagged object whose payload pairs a head with another List object. `NIL`
is itself List-tagged; its payload contains the canonical empty-List Error in
both positions, so it is neither false nor numeric zero. That Error's empty
frame List is the same `NIL`; `raw-fix` ties this finite lazy graph without a
host reference or module cycle. `typed-cons` is the only strict constructor
and accepts only a List tail; it validates that tail with the shared
`raw-check-argument` step described under Runtime typing. NIL recognition checks the tail's Error tag in
O(1), so an Error head does not make a nonempty List look empty.

`typed-head`, `typed-tail`, and `typed-is-nil` use the generalized checker with
a one-element List signature. Wrong concrete types create structured
TypeMismatch roots, while incoming Errors gain the current argument frame.
`typed-cons` is not built by the checker because its head is intentionally
polymorphic and therefore has no expected runtime tag for a signature entry.
Its polymorphic head preserves an incoming Error without inventing an expected
type; its List tail has ordinary framed propagation. `HEAD` and `TAIL` on
`NIL` return the canonical EmptyList Error with a result frame naming the
operation. Deciding that requires reading the tail's tag, which `cons` has
already validated for every public List; a raw-built List pays one extra cell
step, and the second cell's contents are never forced.
`typed-is-nil` now wraps its O(1) raw predicate result as a tagged Bool. The raw
layer currently provides a right fold, append, reverse, map, and filter; the
fold callback receives the head followed by the folded tail.

`core/list-nat.rkt` adds raw length, take, and drop after binary Nat is
available. Length returns canonical raw Nat bits. Take and drop accept raw Nat
bits first and a List second; taking beyond the end returns the complete List,
while dropping beyond the end returns `NIL`. The strict wrappers now use the
generalized checker. They accept tagged Nat and List values, bubble incoming
Errors, and preserve the one remaining application after a bad first argument.

### Natural numbers

Public Nat values are normalized binary digit lists in most-significant-bit
first order. Zero has exactly one representation, `[0]`; positive values have
no leading zeroes. Each digit is a raw lambda Boolean inside the same proper
List structure used elsewhere; the outer Nat object supplies the runtime type.

`core/binary-nat.rkt` normalizes empty or all-zero internal inputs to `[0]` and
removes every unnecessary leading zero. It implements raw zero testing,
successor, addition, saturating subtraction, multiplication, equality, and all
four order comparisons directly on MSB-first digit Lists. Addition and
subtraction reverse their operands for carry and borrow propagation;
multiplication scans one operand with binary shift-and-add. Division performs
MSB-first binary long division, maintaining a remainder and building quotient
bits without repeated host or Church arithmetic. Its raw contract requires a
nonzero divisor; the strict layer owns the zero policy. None of these
algorithms converts through Church numerals or host numbers. `ZERO` through
`TEN` are canonical typed constants.

`core/typed-nat.rkt` routes every public Nat operation through the generalized
checker. `SUCC`, `ADD`, `SUB`, and `MULT` return tagged Nat values; `EQ`, `LT`,
`LTE`, `GT`, `GTE`, and `IS-ZERO` return tagged Bool values. `DIV` uses the
same two-Nat signature but keeps its already-typed Result return. Valid
division by a nonzero value returns Ok containing a canonical Nat; valid
division by zero returns Err containing the canonical DivideByZero Error.
Unary operations use one Nat signature entry, and binary operations use two,
so partial application, wrong-type failures, incoming-Error bubbling, and
remaining-arity absorption all have the same behavior as other strict typed
functions. Every Nat boundary records its canonical function-name String,
argument position, and expected Nat type when it creates or propagates an
Error.

### Errors and results

Every Error is an Error-tagged object whose payload pairs one immutable root
with a proper List of propagation frames. Root kinds are the small Church
discriminants TypeMismatch, EmptyList, InvalidNat, DivideByZero, InvalidChar,
InvalidString for a List that violates the String element invariant, and
WrongResultVariant for unwrapping the variant a Result does not hold. A TypeMismatch root additionally stores its argument position,
expected runtime type, and actual runtime type. The other current roots need
no extra details.

A frame contains a canonical function-name String, argument position, and
expected runtime type for the current boundary. `raw-bubble-error` reuses the
exact root and prepends one frame, so the frame List is newest-first and root
metadata never changes. Fresh TypeMismatch roots receive the same named frame
as propagated Errors.

A strict operation whose valid arguments still make its algorithm fail —
`HEAD` or `TAIL` on `NIL`, `MAKE-CHAR` above 255, `MAKE-STRING` with a
non-Char element, `STRING-HEAD` or `STRING-TAIL` on the empty String, and
`unwrap-ok` or `unwrap-err` on the wrong variant — returns the canonical root
with one *result frame*: the function name, argument position `church-zero`
(argument positions start at one, so zero unambiguously means "at the
result"), and the Error type of the value produced. `raw-add-result-frame`
builds it, and each failing raw algorithm attaches it explicitly, so an Error
that a strict operation merely yields as ordinary data — a stored List element
or a `Result` payload — is returned unchanged. The polymorphic `typed-cons`
head and `make-ok` likewise preserve an incoming Error without adding a frame
because neither position has an expected runtime type to record.

`readers/error.rkt` reverses the stored frame List for causal display, renders
the oldest mismatch frame with its actual type, prints a result frame as
`NAME(result)`, and then prints each later boundary as an arrow. Function names remain structured String values inside
the Error; only the reader flattens them to diagnostic text. Language-level
failures never use host exceptions or strings.

`core/result.rkt` represents Result as a Result-tagged object whose payload
pairs a raw Boolean discriminator with a payload. True identifies Ok; false
identifies Err. `make-ok` accepts a polymorphic value but preserves an incoming
Error instead of hiding it. `make-err` is the intentional exception to normal
Error bubbling: it requires an Error and stores that Error as data. A wrong
non-Error argument remains a TypeMismatch Error.

`is-ok`, `is-err`, `unwrap-ok`, and `unwrap-err` strictly require Result via
the generalized checker. The predicates return tagged Bool values. `unwrap-ok`
returns the payload of an Ok and `unwrap-err` the payload of an Err, each
without automatically propagating it; asking for the variant a Result does not
hold is a contract failure and returns the WrongResultVariant Error with a
result frame. This is the semantic boundary: a Result Err is an ordinary valid
Result until a caller explicitly unwraps and uses its Error payload.

### Characters and strings

`core/chars.rkt` represents Char as a Char-tagged object containing normalized
raw Nat bits rather than a nested Nat object. Its pure upper bound is computed
as `(16 × 16) − 1` with raw binary operations. `MAKE-CHAR` uses the generalized
checker for its Nat argument, returns Char for values 0 through 255, and returns
the canonical InvalidChar Error above that range.

`CHAR-EQ`, `CHAR-LT`, `CHAR-LTE`, `CHAR-GT`, and `CHAR-GTE` use two-Char
signatures through the same checker. They reuse raw binary Nat comparisons on
unwrapped Char payloads and return tagged Bool values.

The module defines every required upper- and lowercase letter, decimal digit,
control constant, and named punctuation constant as a genuine lambda-built
Char. Constants are derived from binary Nat values and unary successor chains;
production code contains no host numbers or character literals.

`readers/char.rkt` converts a completed Char payload to a host integer or
display string. It renders TAB, LF, CR, and printable ASCII directly and uses
`char:<integer>` for unsupported values. This observation is one-way and never
feeds host characters back into production computation.

`core/strings.rkt` represents String as a String-tagged object whose payload is
the canonical List object containing typed Char elements. `EMPTY-STRING` uses
`NIL`. `MAKE-STRING` strictly requires a List and recursively checks every
element's Char tag using lambda computation; a well-typed List containing any
non-Char element returns the canonical InvalidString Error.

`STRING-EMPTY?`, `STRING-LENGTH`, `STRING-EQ`, `STRING-APPEND`,
`STRING-HEAD`, `STRING-TAIL`, `STRING-PREFIX?`, and `STRING-CONTAINS?` all use
the generalized checker. The raw algorithms traverse List structure and
compare Char binary payloads directly. Length reuses the canonical raw binary
List counter and returns Nat. Head returns Char; tail returns String; either
partial operation returns EmptyList Error on the empty String. Prefix and
contains take the searched String first and the candidate prefix or substring
second; an empty candidate succeeds.

`readers/string.rkt` traverses the completed Char List and joins the Char
reader's host output. No production module imports it, and no host string
operation participates in equality, append, prefix, or substring search.

## Runtime typing

`make-typed-function` accepts, in order, a raw curried function, a canonical
function-name String, an Alone the Lambdas List of expected type tags, and one
unary return policy. It constructs strict typed functions of arbitrary arity
by:

- validating one argument per application;
- bubbling an existing Error with the current function name, expected type,
  and Church-encoded argument position;
- creating and framing a structured Error for a wrong runtime type;
- unwrapping a valid argument and partially applying the raw function;
- preserving remaining arity with one unary absorbing continuation per
  unconsumed signature entry after an early failure; and
- applying `raw-wrap-return` for a raw result or `raw-keep-return` for a result
  that is already typed.

The empty signature also supports a zero-argument raw value. No host arity
counting or arity-specific checker variant exists. The purity gate explicitly
rejects numbered checker names.

One-argument validation lives in a single shared step, `raw-check-argument`:
given a function name, argument position, expected type, a failure
continuation, and a success continuation, it bubbles an incoming Error,
frames a fresh TypeMismatch, or passes a valid argument on. The checker uses
it with the remaining-arity absorber as its failure continuation; `typed-if`
(the specified custom polymorphic conditional) uses it with a two-branch
absorber and the raw selector as its success continuation; `typed-cons` uses
it for its List tail. The polymorphic positions — the `typed-cons` head, `typed-make-ok`, and
`typed-make-err`, which intentionally accepts Error as data — have no expected
tag and therefore test for the Error tag directly rather than through this
step.

## Naming

Internal names state their semantic layer:

- `raw-*` for raw representations and algorithms;
- `typed-*` for strict runtime-typed operations.

Public exports use canonical language vocabulary. Underscore prefixes must not
exist solely to avoid Racket bindings. Host collisions are handled at module
boundaries through renaming and selective export.

## Repository layout

```text
macros/
  lazy-with-macros.rkt
  macros.rkt
core/
  pair.rkt
  logic.rkt
  tags.rkt
  objects.rkt
  fix.rkt
  errors.rkt
  function-names.rkt
  lists.rkt
  binary-nat.rkt
  result.rkt
  chars.rkt
  typed-nat.rkt
  list-nat.rkt
  typecheck.rkt
  typed-logic.rkt
  strings.rkt
effects/
  protocol.rkt
  stdout.rkt
  files.rkt
  tcp.rkt
  http.rkt
  http-response.rkt
  http-server.rkt
runtime/
  codec.rkt
  host.rkt
lang/
  reader.rkt
  expander.rkt
runner/
  atl.rkt
readers/
  raw-boolean.rkt
  bool.rkt
  type-tag.rkt
  list.rkt
  nat.rkt
  char.rkt
  string.rkt
  error.rkt
examples/
  hello.atl
  stdout.atl
  file-round-trip.atl
  http-server.atl
tests/
tooling/
  check-purity.rkt
  check-boundaries.rkt
VERSION
info.rkt
run-all-tests.sh
```

Sixteen zero-exception production modules remain under `core/`. The completed
milestone has seven pure effect modules, two separately pinned mechanical
macro modules, two separately classified runtime boundary modules, the exact
reader/expander pair, pinned package metadata, eight one-way value readers,
one exact non-exporting runner, four public-language applications, and
separately classified tests/tooling. All 79 Racket and `.atl` sources are
inventoried. New abstraction layers require a concrete need.

## Verification boundary

The test suite checks macro currying and hygiene, pair selection, every raw
Boolean truth-table row, and lazy non-evaluation of rejected pair fields and
`raw-if` branches. It also proves all 49 pairwise tag comparisons, every tag
and payload round trip, object/accessor currying, and accessor laziness. The
List suite covers NIL identity, proper tails, nested traversal, strict
failures, Error bubbling, laziness, and every implemented raw helper. Binary
Nat tests cover normalization, the typed constants, carries, borrows,
saturating subtraction, multiplication, long division, quotient laws,
comparisons, larger bit widths, currying, and applicable laziness.
Nat-dependent List tests cover length, take, drop, boundary counts, proper
tails, strict failures, Error absorption, currying, and lazy base cases.
Structured Error tests cover every kind, root
metadata, the `NIL`/empty-Error knot, frame order, result frames, nested root
preservation, unframed Error-as-data pass-through, canonical function-name
Strings, List failures, currying, and lazy field access. The Error reader
suite exercises all 43 named strict boundaries, every raw-failure boundary's
result frame, all seven rendered type tags, every current root kind, and
nested causal output.
The generalized
checker suite covers lambda List signatures and zero-, one-, two-, three-, and
five-argument functions; valid partial application; every five-argument
mismatch position; incoming Error framing; raw and already-typed return
policies; exact remaining-arity absorption; and ignored-argument laziness. The
typed-logic suite covers both tagged Bool constants, every strict operation
truth-table row, mismatch and incoming-Error propagation at each applicable
position, curried shape, typed `IS-NIL`, polymorphic branch results, canonical
exports, and divergent unselected branches. The typed Nat suite covers all
constants and public operations, representative large values, arithmetic and
comparison semantics, every applicable mismatch and incoming-Error position,
root preservation, exact absorber arity, ignored-argument laziness, currying,
and canonical exports. The Result suite covers Ok and Err representation,
strict constructors and accessors, wrong-variant unwrap failures, Error
encapsulation, mismatch and incoming Error behavior, safe division results, quotient laws, exact absorber arity,
zero-divisor laziness, explicit post-unwrap propagation, currying, and public
exports. The Char suite covers every required constant, normalized raw-bit
payloads, 0 and 255 acceptance, 256 rejection, InvalidChar roots, mismatch and
incoming-Error behavior, reader output and fallbacks, currying, and reader
isolation. The String suite covers representation, recursive Char validation,
InvalidString roots, raw and strict operations, canonical binary length,
empty partial-operation errors, List/Char interaction, prefix and substring
boundaries, mismatch and incoming-Error propagation, exact binary-operation
absorbers, laziness, currying, and reader output. The milestone acceptance
suite composes Bool, List, Nat, Result, Char, String, and Error behavior in one
strict typed flow and runs the same structural scan over the complete core.

The structural purity tool judges what Racket compiles. It reads each of the
16 production modules with its source intact, expands it in a fresh namespace
exactly as `raco make` would, and walks the fully expanded module. A reference
term, `(lambda (f) (lambda (x) (f x)))`, is expanded under the same trusted
shell so that Lazy Racket's own encodings of a unary `lambda` and a unary
application become the only two admissible expression templates; every
production lambda and application must be alpha-equivalent to one of them,
and every identifier must be lambda-bound, defined in the module, or imported
from a project module that passes the same scan. The tool pins the shell file
itself, restricts imports to phase-0 project modules, restricts exports to
plain or renamed project bindings, and rejects host forms, host literals,
multi-argument or zero-argument applications, strict kernel lambdas,
compile-time definitions, submodules, module-level expressions, and the
reserved and arity-specific names. Because the scan sees the same expansion
the compiler produces, a macro cannot hand the checker a different term than
the compiler by inspecting its input. The two files under `macros/` and the
Racket installation are the trusted base: `macros.rkt` is judged only through
what its macros expand to, and, like `raco make`, the scan runs the read-time
and compile-time code of the modules it examines rather than sandboxing them.
The purity gate therefore trusts macro semantics. The separate boundary gate
pins both macro paths, their languages, imports, exports, and source
vocabulary; rejects operating-system, process, environment, dynamic-loading,
FFI, and mutation capabilities there; rejects additional macro modules; and
admits only the exact reader, expander, and package metadata. The
expander's imports, exports, runtime wrapper definitions, transformer/helper
set, and source vocabulary are closed; only it may import and re-export the
production `host`. A contributor who can edit both a
trusted file and its checker remains outside this accidental-impurity model.
Focused tests pin each boundary. The
complete evidence map is
[docs/ACCEPTANCE.md](docs/ACCEPTANCE.md).

The separate boundary gate allowlists every effect import and identifier,
rejects non-unary effect source forms, admits no codec I/O, mutation, registry,
reader, or runtime dependency, pins the host's imports and sole export, sees
through classified require wrappers, fails closed on unclassified wrappers,
authorizes imports before discovering their exports, validates every component
of the project root and each production path before discovery, rejects
symlinks without traversing their targets, and rejects every second codec
importer, host importer, filesystem/TCP importer, or `host` definition/export.
It also inventories every Racket or `.atl` source, rejects unknown locations,
pins the root/package/CLI version projection and the one exact runner, rejects
runner exports, extra loader modules, altered loader targets, and
process/environment/evaluator capabilities, constrains readers to an exact
effect-free observation vocabulary with core/reader imports, rejects every
production import of readers/tests/tooling/applications/runner, admits normal
host authority only in the test/tooling support classes, and requires the
exact four `.atl` examples to use the public standalone language. Dedicated
rejection fixtures prove each new direction and the host-exclusive primitive
vocabulary.
Codec tests cover all 256 byte values, canonical and malformed String and Nat
representations, private copying, acknowledgements, and Err encoding. Stdout
tests prove exact fake-host
requests, strict argument rejection, Result propagation, and force-once
laziness. Real-host tests prove byte-exact output and flushing completion,
malformed request rejection before effects, canonical success, stable failure
mapping, unselected-branch laziness, and cached forcing. File-wrapper tests
prove exact request shapes, strict curried contracts, early-Error absorption,
fake-host isolation, and force-once dispatch. Isolated real-file tests prove
empty and arbitrary-byte round trips, relative and absolute UTF-8 paths,
truncating replacement, symlink preservation without delete authority,
cleanup, cached writes, and the approved missing, permission, invalid-text,
invalid-path, resource, timeout, and fallback codes.
TCP wrapper tests prove all six exact requests, strict curried contracts,
early-Error absorption, fake-host isolation, branch laziness, unchanged Result
propagation, and force-once dispatch. Loopback-only real-host tests prove
ephemeral listen-port discovery; monotonic nonreused listener and connection
handles; blocking, bounded, and fragmented reads; complete full-duplex binary
writes; valid empty writes; EOF; wrong, fabricated, and stale handles; closed
failure codes; Racket custodian closure; and explicit cleanup. Production TCP
remains blocking and contains no thread or async surface; concurrency appears
only in the test harness where a peer must act during a blocking call.
HTTP message tests prove incremental incomplete Results across split CRLF
boundaries; exact GET, origin-form, HTTP/1.1, header, and case-insensitive Host
validation; distinct malformed and unsupported Results; strict contract Error
behavior; four fixed status lines; empty, text, and arbitrary-byte bodies;
single- and multi-digit decimal content lengths; connection-close framing; and
deterministic byte output. The separate boundary suite proves that host String,
regex, arithmetic, and HTTP-library helpers remain unavailable to this pure
module class. HTTP server tests add exact TCP-only fake traces across success,
fragmentation, failures, cleanup, and two serial connections. A test-side
external HTTP client reaches the real loopback listener and receives the
lambda handler's selected response; production imports no HTTP client or
threading facility.
The standalone-language suite copies and installs the package under an
isolated Racket user home, then runs the specification's canonical shape,
curried definitions and applications, unary `lambda`, pure `let`, divergent
unselected branches, Nat/String literals, and exact UTF-8 stdout. Test-only
namespace observation sends literal values through the codec to prove
canonical representations. Unsupported Racket datum families, raw and typed
implementation names, underscore workarounds, and ordinary Racket forms are
all rejected during expansion.

The second-milestone acceptance suite reuses the same dotenv-excluding,
symlink-rejecting copied-package installer. It runs the exact three effect
applications outside the installed collection through the copied Phase 22
runner: exact stdout bytes; a
write/read byte round trip in an empty temporary directory; and a one-request
HTTP server on an ephemeral loopback port reached by a test-side external
client. The server test checks its announced URL, status, headers, body,
process exit, empty stderr, and listener cleanup. Together with the focused
TCP lifecycle suites and the zero-finding boundary inventory, this covers the
specified `stdout`, `read-file`, `write-file`, and TCP effect families while
retaining the one-bridge proof.

The runner suite uses that same copied-package installation for 126 focused
checks. It proves exact help/version output, command misuse, all three version
states, validation precedence, exact lowercase extension and declaration
terminators, supplied and resolved-parent dotenv rejection, final symlink
rejection, regular-file checks, paths with spaces and non-ASCII characters,
the checked-in hello program, existing-facade currying/UTF-8 behavior,
existing-expander rejection of a Racket identifier, and successful process
completion for ordinary lambda Error and Result Err values. The structural
suite independently proves the runner is one non-exporting loader rather than
a parser, evaluator, codec, effect bridge, or object-language dependency.

## Completed milestone boundary

The completed core still contains no `host` form. Phases 13 through 20 in
[PLAN.md](PLAN.md) approved and implemented exactly one explicit boundary plus
ordinary lambda wrappers for stdout, whole-file access, blocking TCP, and a
pure HTTP message and sequential-server layer, followed by the standalone
language surface and runnable applications. The final acceptance sweep changed
no production semantic, representation, operation, or authority. The approved
protocol and its full process-level filesystem/network authority are recorded
in [docs/design/host-boundary.md](docs/design/host-boundary.md); the complete
claim-to-test and one-bridge evidence maps are recorded in
[docs/ACCEPTANCE.md](docs/ACCEPTANCE.md).
