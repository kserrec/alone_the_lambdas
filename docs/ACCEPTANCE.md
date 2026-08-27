# Core milestone acceptance

This document maps every first-milestone completion criterion to observed
evidence in the repository. The authoritative requirements remain the three
[specifications](specifications/README.md); this is their verification index,
not a replacement.

Verified on 2026-08-24 with:

```sh
raco make core/*.rkt readers/*.rkt
./run-all-tests.sh
```

The result was 2,914 passing assertions across 18 test files, followed by a
clean structural scan of all 16 production modules.

Phase 14 was verified on 2026-08-27 with `./run-all-tests.sh`: 3,026 passing
assertions across 22 test files, the same clean 16-module core scan, and a
clean effects/codec/host boundary scan.

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
| Errors preserve roots and accumulate structured frames. | [`errors-test.rkt`](../tests/errors-test.rkt) checks root identity and newest-first frame storage; [`error-reader-test.rkt`](../tests/error-reader-test.rkt) checks named causal rendering. |
| Result represents expected failure separately from Error. | [`result-test.rkt`](../tests/result-test.rkt) and [`acceptance-test.rkt`](../tests/acceptance-test.rkt) distinguish `DIV` by zero as Result Err from a wrong argument as contract Error. |
| Typed `if` consumes tagged Bool values. | [`typed-logic-test.rkt`](../tests/typed-logic-test.rkt) checks strict condition typing, polymorphic branches, absorber shape, and divergent unselected branches. |
| Char uses binary payloads from 0 through 255. | [`chars-test.rkt`](../tests/chars-test.rkt) checks normalized payloads, both bounds, rejection of 256, constants, comparisons, and observation. |
| String is a typed List of typed Char values. | [`strings-test.rkt`](../tests/strings-test.rkt) checks the representation, recursive Char invariant, proper tails, and invalid elements. |
| String operations are lambda computations. | [`strings-test.rkt`](../tests/strings-test.rkt) covers every raw and strict algorithm; the purity scan checks [`strings.rkt`](../core/strings.rkt) under the same host-form ban as the rest of production. |
| All core computation remains pure untyped lambda calculus. | [`check-purity.rkt`](../tooling/check-purity.rkt) scans every `core/*.rkt` file and its reachable project imports against the allowed production grammar, verifies the trusted language shell, resolves validated import selection/renaming plus explicit exports, and rejects non-unary application, host data/forms/definitions/re-exports, explicit `host`, syntax-shell rebinding, and arity-specific checkers. The command runs after every test file in [`run-all-tests.sh`](../run-all-tests.sh) and in CI. |

## Addenda and Phase 12 refinements

| Refined requirement | Evidence |
| --- | --- |
| Production computation reduces to variables, unary lambda, and application after mechanical expansion. | [`macros-test.rkt`](../tests/macros-test.rkt) checks curried expansion; [`purity-test.rkt`](../tests/purity-test.rkt) proves zero-/multi-argument applications, multi-formal and multi-body lambdas, alternate module languages, transformed host imports/exports, inherited host re-exports, direct host aliases, unapproved Lazy Racket bindings, and module syntax rebinding are rejected while local lexical shadowing remains valid. |
| Readers are a one-way observation boundary. | Structural check: reader modules may use host values and formatting, but no production module imports `readers/`; the dependency direction is recorded in [`ARCHITECTURE.md`](../ARCHITECTURE.md). |
| Error frames contain structured function-name Strings. | [`function-names.rkt`](../core/function-names.rkt) contains pure typed constants; [`error-reader-test.rkt`](../tests/error-reader-test.rkt) verifies all 43 names, every corresponding strict mismatch boundary, and nested propagation. |
| Diagnostics preserve structured data until observation. | [`error.rkt`](../readers/error.rkt) alone flattens roots and frames; its tests cover all root kinds, type names, raw fallback output, and causal order. |
| Internal names expose raw and typed layers without underscore collision workarounds. | Structural check: production APIs use `raw-*` and `typed-*`; canonical `if` is exported at its module boundary. The remaining standalone `lambda`/`let`/`cons` surface is explicitly next-milestone work, as permitted by the naming addendum. |
| No implicit host boundary exists in the core milestone. | `host` remains absent from `core/` and forbidden by its unchanged purity scan. Phase 14's later explicit bridge is isolated in `runtime/host.rkt` and checked separately rather than weakening this evidence. |

## Phase 14 effects-boundary evidence

| Requirement | Evidence |
| --- | --- |
| Exact byte conversion is isolated from effects. | [`codec-test.rkt`](../tests/codec-test.rkt) covers all 256 byte values, empty and embedded-zero Strings, immutable output, source-byte copying, canonical List/Char/String construction, malformed tags/tails/elements, leading-zero and out-of-range Char rejection, and canonical Ok/Err construction. [`check-boundaries.rkt`](../tooling/check-boundaries.rkt) rejects codec I/O, mutation, registries, readers, runtime dependencies, unknown strict-module identifiers, and unauthorized exports. |
| `host` is one unary, closed privileged bridge. | [`host-test.rkt`](../tests/host-test.rkt) checks unary arity, the strict outer List contract, every stdout schema failure, defensive codec rejection, canonical InvalidHostRequest/HostFailure details, incoming Error propagation, and cached force-once behavior. The boundary checker requires the sole `host` definition/export, its protocol and codec imports, and rejects every second codec importer or host surface. |
| `stdout` remains ordinary lambda computation. | [`stdout-test.rkt`](../tests/stdout-test.rkt) proves the exact `["stdout", bytes]` request, strict String rejection before dispatch, deterministic fake-host traces, unchanged Result propagation, unary shape, and lazy single dispatch. The boundary checker allowlists every effect identifier/import/export and rejects host data, non-unary forms, runtime imports, and unknown Lazy Racket bindings. |
| Real stdout is byte-exact and expected failure is Result Err. | [`host-test.rkt`](../tests/host-test.rkt) captures empty, embedded-zero, and byte-255 output with no newline, observes output only after forcing, proves repeat forcing does not write twice, proves an unselected host branch performs no effect, and maps a closed output port to `Err HostFailure("stdout", "io-failure")`. |
| The completed core boundary is unchanged. | [`check-purity.rkt`](../tooling/check-purity.rkt) still performs its zero-exception scan over exactly 16 `core/` modules. [`run-all-tests.sh`](../run-all-tests.sh) runs that gate and the new boundary-classification gate independently. |

## What this milestone does not claim

The repository now contains the verified core plus the explicit Phase 14
`stdout` boundary. It does not yet provide the standalone `#lang`, literal
syntax, command-line runner, file effects, networking, or later pure HTTP
layers. Those features remain ordered future phases and must preserve both the
core purity proof and the new boundary classifications.
