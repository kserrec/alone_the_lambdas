# AttaLambda

AttaLambda is a small programming language built around a big question:

> How much of a practical language can be made from pure lambda calculus?

Programs use familiar Lisp-shaped syntax, but ordinary computation expands to
only variables, one-argument lambdas, and function application. Racket supplies
lazy evaluation and module machinery; effects cross one explicit `host`
boundary.

This is a complete AttaLambda program:

```racket
#lang attalambda

(stdout "Hello from AttaLambda.\n")
```

## Try it on Linux

AttaLambda 0.2.0 is available as a self-contained Linux x86-64 archive. It
includes its own runtime, so you do not need to install Racket.

Release page: <https://github.com/kserrec/attalambda/releases/tag/v0.2.0>

Download, verify, extract, and run it:

```sh
curl -LO https://github.com/kserrec/attalambda/releases/download/v0.2.0/attalambda-0.2.0-linux-x86_64.tar.gz
curl -LO https://github.com/kserrec/attalambda/releases/download/v0.2.0/SHA256SUMS
awk '$2 == "attalambda-0.2.0-linux-x86_64.tar.gz" { print }' SHA256SUMS | sha256sum -c -
tar -xzf attalambda-0.2.0-linux-x86_64.tar.gz
cd attalambda-0.2.0-linux-x86_64
./bin/attalambda --version
./bin/attalambda examples/hello.attl
```

You should see:

```text
AttaLambda 0.2.0
Hello from AttaLambda.
```

Linux x86-64 is currently the only supported binary target. The checksum file
also retains historical entries for withdrawn macOS and Windows builds; the
command above checks only the current Linux archive. Users should not have to
bypass operating-system security protections to try the language, so macOS
builds without Apple signing and notarization and Windows builds without
Authenticode signing are not distributed.

## Run it from source

You need Racket. The install command registers the checkout in your user-level
Racket package registry and does not require administrator access:

```sh
git clone https://github.com/kserrec/attalambda.git
cd attalambda
raco pkg install --auto --name attalambda .
racket runner/attalambda.rkt examples/hello.attl
```

AttaLambda has no third-party package dependencies. Its runtime dependencies
are Racket's `base` and `lazy` packages; tests also use `rackunit-lib` and
`net-lib`.

To run the complete test and structural-purity suite:

```sh
./run-all-tests.sh
```

## What makes AttaLambda unusual?

- Every ordinary function is built from nested one-argument lambdas. Partial
  application follows naturally from that representation.
- Bool, List, Rat, Error, Result, Char, and String are all lambda-encoded
  values. Operations check their type tags at runtime.
- The one public number type is Rat: exact rationals stored as a reduced
  signed numerator over a positive denominator, with normalized binary digit
  Lists underneath instead of Church numerals, so arithmetic is exact and
  does not grow with a unary encoding.
- Errors are ordinary structured values. Expected computational failures use
  `Result`; contract and representation failures use `Error`.
- Output, files, and blocking TCP are available through one explicit host
  boundary. Pure HTTP parsing, response rendering, and routing sit above that
  boundary as ordinary language computation.
- Automated structural checks reject host computation, hidden privileged
  imports, non-unary lambdas, and unknown source locations in production
  paths.

The goal is not to hide Racket behind a new syntax. It is to make the boundary
between lambda-calculus computation and host authority small, visible, and
testable.

## Examples

The repository includes four programs written entirely through the public
`#lang attalambda` surface:

| Example | What it does |
| --- | --- |
| [`hello.attl`](examples/hello.attl) | Prints a greeting. |
| [`stdout.attl`](examples/stdout.attl) | Exercises explicit standard output. |
| [`file-round-trip.attl`](examples/file-round-trip.attl) | Writes and reads back a file. |
| [`http-server.attl`](examples/http-server.attl) | Serves one request on an ephemeral loopback port, then exits. |

Run any example from a registered source checkout with:

```sh
racket runner/attalambda.rkt examples/hello.attl
```

AttaLambda does not sandbox programs. A program can use the same relevant
standard-output, filesystem, and network permissions as the Racket or
AttaLambda process that launched it. Inspect unfamiliar `.attl` files before
running them. In particular, `file-round-trip.attl` creates or truncates
`attalambda-round-trip.txt` in its current directory.

## Project status

Version 0.2.0 is the first independently runnable release. The pure core,
explicit effects boundary, standalone language, examples, and Linux x86-64
distribution are implemented and tested. [`PLAN.md`](PLAN.md) holds the full
phase history and current roadmap; this README intentionally does not repeat
it.

## Repository guide

| Path | Purpose |
| --- | --- |
| [`core/`](core) | Pure representations, raw algorithms, and strict typed operations. |
| [`effects/`](effects) | Pure requests and wrappers for output, files, TCP, and HTTP. |
| [`runtime/`](runtime) | Deterministic boundary conversion and the sole privileged `host`. |
| [`lang/`](lang) | The `#lang attalambda` reader and public language surface. |
| [`runner/`](runner) | The standalone command-line entry point. |
| [`readers/`](readers) | One-way human-readable observation used outside production computation. |
| [`tests/`](tests) | Behavioral, representation, error, laziness, and boundary tests. |
| [`tooling/`](tooling) | Purity, boundary, and distribution checks. |

For more detail:

- [`ARCHITECTURE.md`](ARCHITECTURE.md) explains the layers and dependency
  direction.
- [`docs/specifications/`](docs/specifications/README.md) contains the three
  documents that define the language.
- [`docs/ACCEPTANCE.md`](docs/ACCEPTANCE.md) maps requirements to executable
  and structural evidence.
- [`AGENTS.md`](AGENTS.md) contains the implementation rules for contributors
  and coding agents.

## License

Copyright 2026 Kyle Serrecchia.

AttaLambda is available under the [Apache License 2.0](LICENSE). Self-contained
release archives include the applicable Racket runtime notices and license
texts.
