# Standalone distribution design

Status: approved 2026-08-27; feasibility proven; Phase 22 implemented

Date: 2026-08-27

This document fixes the contract for distributing Alone the Lambdas as an
independently runnable language. It is subordinate to the three canonical
[specifications](../specifications/README.md) and to the already approved
[host boundary](host-boundary.md). Approval authorizes the implementation
work in Phase 22; it does not authorize a public release.

## Verified starting state

The following facts were observed before this design was written:

- `lang/reader.rkt` already delegates `#lang alone_the_lambdas` to the one
  canonical expander in `lang/expander.rkt`.
- That expander already provides the complete public language and injects the
  sole real `host` into the nine pure effect wrappers once.
- The three runnable applications exist only as Racket-named source files in
  `examples/`. A repository search found no `runner/` directory, `atl`
  executable, or public `.atl` source.
- `info.rkt` is the single-collection package metadata and currently records
  package version `0.1`.
- The local development installation is Racket CS 8.10. The pinned CI
  toolchain is full Racket CS 9.3.
- Racket 9.3 has now demonstrated the required standalone-loading path in
  disposable space. The evidence and its limits are recorded below.

This phase creates this design document and updates `PLAN.md`. It creates no
production launcher, changes no language export, renames no application, and
changes no object-language or host behavior.

## Product contract

A supported release is a native archive that a user can download, extract,
and run without installing or knowing Racket. The primary workflow is:

```text
atl run FILE.atl
```

The archive carries the Racket runtime, reader, expander, compiler support,
all Alone the Lambdas production modules, and every non-system runtime file
needed to load an external source file. At run time it must not require:

- a `racket` or `raco` command;
- an installed Alone the Lambdas package;
- a Racket user package registry or collection tree;
- this repository or another source checkout;
- the build directory or its absolute paths;
- a network service.

This is a distribution promise, not a sandbox promise. A program run with the
real host has the launching process's already documented stdout, filesystem,
name-resolution, connection, and listening authority.

## `.atl` source contract

`.atl` is the canonical public source extension. It changes the public file
name, not the language grammar or evaluator.

A runnable source must satisfy all of these rules:

- The supplied final path component ends in the exact lowercase bytes `.atl`.
  The check is case-sensitive on every platform, including Windows. `.ATL`,
  `.Atl`, and a missing suffix are invalid.
- The source is a regular file. Directories, devices, FIFOs, and other special
  inputs are not source files.
- The first logical line is exactly `#lang alone_the_lambdas`, with no byte
  order mark, leading whitespace, trailing whitespace, shebang, alternate
  spelling, or version suffix. It may end with LF, CRLF, or end of file.
- The remaining source is read by the existing `lang/reader.rkt` and expanded
  by the existing `lang/expander.rkt`. The launcher does not contain a second
  ATL tokenizer, parser, expander, evaluator, or literal implementation.
- Source text follows Racket's UTF-8 source convention. Invalid source bytes
  are a source-read failure. ATL String literals continue to lower
  mechanically to their UTF-8 bytes exactly as the existing expander defines.
- Paths containing spaces and non-ASCII characters are supported. Relative
  source paths resolve from the caller's current working directory; absolute
  paths are supported. The launcher does not change that directory.
- The supplied source entry itself is not a symbolic link. A reported symlink
  is refused without inspecting its target. Normal operating-system resolution
  still applies to parent directories; the dotenv rule below is applied to
  both the supplied components and the resolved parent path before content.
- The launcher loads only the one explicitly supplied file. It performs no
  directory walk, project discovery, import discovery, package lookup, or
  network retrieval on the user's behalf.

The dotenv rule is intentionally stricter than the extension rule. A path
component is forbidden, case-insensitively, when its name matches
`(^|\.)env($|\.)`. This rejects `.env`, `service.env`, `.env.local`,
`service.env.local`, `program.env.atl`, and equivalent spellings before file
content is accessed. Metadata needed to reject or resolve the path may be
observed; content may not.

The original command-line spelling of the source path is the public diagnostic
name. Resolution may use a complete host path internally, but diagnostics must
not replace the user's spelling with a resolved parent path, checkout path,
package path, or temporary build path.

Validation precedence is fixed so overlapping failures behave identically on
every platform:

1. reject command misuse;
2. reject a dotenv spelling in the supplied path without content access;
3. reject a non-lowercase `.atl` extension without content access;
4. reject a symlinked source entry without target access;
5. resolve parent directories and reject a dotenv spelling in that resolved
   parent path;
6. reject a missing, non-regular, or unreadable source;
7. validate the declaration, then read, expand, and instantiate the source.

Relative paths used later by the program's `read-file` and `write-file`
operations continue to resolve from the caller's unchanged working directory,
as the approved host design already specifies.

## Command grammar

The complete initial command grammar is:

```text
atl run FILE.atl
atl --help
atl --version
```

On Windows, `atl` in this grammar names `atl.exe`. There are no aliases,
combined flags, short flags, implicit `run`, program arguments, REPL mode,
stdin-source mode, compiler mode, or package-manager mode in this milestone.
A path beginning with `-` is supplied with an explicit directory component,
such as `./-example.atl`.

`atl --help` writes exactly this text to stdout and exits successfully:

```text
Usage:
  atl run FILE.atl
  atl --help
  atl --version
```

`atl --version` writes `Alone the Lambdas VERSION` followed by one newline,
where `VERSION` is the exact canonical product version described below. The
initial development output is therefore:

```text
Alone the Lambdas 0.2.0-dev
```

Help and version write nothing to stderr and do not inspect a user source
path. A successful `run` reserves stdout for effects explicitly requested by
the ATL program. Launcher diagnostics use stderr only.

## Completion and exit statuses

Launcher-controlled completion uses this closed status table on every target:

| Status | Meaning | Conditions |
| --- | --- | --- |
| `0` | successful command | help/version completed, or the source module instantiated without an uncaught host-level failure |
| `64` | command misuse | missing command, unknown command/flag, missing source argument, or extra argument |
| `65` | invalid ATL source | wrong extension, malformed language declaration, invalid source encoding, reader failure, syntax failure, or expansion failure |
| `66` | unavailable or refused input | dotenv path, symlinked source, missing path, non-regular input, inaccessible path, or source-open/read permission failure |
| `70` | unexpected implementation failure | a catchable Racket failure outside the command, source-read, syntax, expansion, and approved host Result paths |

The launcher validates command shape and path metadata before source content.
For a syntactically valid source, it dynamically instantiates the module once.
It imposes no timeout: a deliberately nonterminating computation or blocking
host operation remains running until the user or operating system stops it.
External termination, signals, forced process kills, and failures too severe
for the runtime to catch may produce operating-system statuses outside this
table; the launcher does not disguise them.

The object-language distinction is exact:

- a lambda-encoded Error is a completed ATL value, not a Racket exception;
- `Result Err` is a completed expected-failure value, not a launcher failure;
- `Result Ok` is likewise ordinary completed data;
- the existing module wrapper forces each top-level expression for its
  requested effects and discards the resulting lambda value;
- the launcher never decodes, renders, branches on, or changes its exit status
  from any of those values.

Consequently, a module that completes with Error or Result Err exits `0`
unless it separately encounters a launcher-level failure. A schema-valid real
host request that the operating system rejects still returns Result Err under
the approved host contract; it does not become status `70`.

Normal diagnostics must name Alone the Lambdas, the user's source spelling,
and an actionable reason. They must not expose raw host procedures, exception
object renderings, Racket stack traces, package registry paths, source-checkout
paths, or build paths. Phase 23 will implement and freeze the exact message
templates without changing the status classifications above.

## Trusted launcher boundary

The launcher is module-loading scaffolding, which the specifications permit
separately from object-language computation. Loading a language necessarily
reads and expands the one source file the user asked to run. That launch-time
read is not a second effect function callable by ATL code.

The future `runner/` class may use host facilities only for these closed
purposes:

- observe its own command-line argument vector;
- emit the fixed help/version text and fixed stderr diagnostics;
- set its process exit status;
- perform lexical path, suffix, and dotenv-name checks;
- resolve and inspect metadata for the one supplied source path;
- read only enough of that source to validate the exact language declaration;
- dynamically load that same source path once;
- categorize reader, syntax, expansion, input, and unexpected implementation
  exceptions for the exit table;
- access the canonical product version as build/module metadata.

This allows the narrowly required Racket command-line, path, file-metadata,
byte/header, exception, and `dynamic-require` machinery. Host Strings,
Booleans, lists, regex matching, conditionals, and exit codes used inside this
class decide only whether and how the host process loads a requested module.
They never become object-language values and never determine an ATL
computational result.

The class must satisfy all of these isolation rules:

- it exports no object-language binding, host callback, loader, namespace,
  source port, parsed syntax, or conversion function;
- no `core/`, `effects/`, `runtime/`, `codec`, macro, reader, expander, or
  language-facade module may import it;
- ATL source cannot name, require, or invoke it;
- it cannot import a reader, test, tooling, application, or object-value codec
  to interpret a completed value;
- it cannot implement ATL parsing, type checks, arithmetic, routing, Result
  control flow, or another effect operation;
- it cannot enumerate environment variables, run a process, invoke a shell,
  use FFI, contact a network service, scan a directory, or discover another
  source file;
- it cannot broaden the real host operation set or bypass `host` for an
  effect requested by ATL code.

Phase 22 must add an exact structural classification for this path and fail
closed on unknown files or capabilities. The existing production ban on
dynamic loading remains in every other class. The sole-language-visible-host
proof therefore stays literally true.

## Version authority

Phase 22 creates a root `VERSION` text file as the only manually edited product
version source. It contains exactly one supported semantic version followed
by one LF and no whitespace or comment. This milestone has exactly three
planned states:

```text
0.2.0-dev
0.2.0-rc.1
0.2.0
```

The CLI text, archive names, getting-started guide, release notes, build
manifest, and tag derive from that file. Tests reject a duplicated or
mismatched public version literal.

Racket package metadata cannot use these strings directly. Under Racket 9.3,
its version predicate rejects hyphenated prereleases and a final zero patch
component. The build/tooling layer therefore owns this closed, mechanically
checked projection:

| Product `VERSION` | Racket `info.rkt` version |
| --- | --- |
| `0.2.0-dev` | `0.1.900` |
| `0.2.0-rc.1` | `0.1.901` |
| `0.2.0` | `0.2` |

The two prerelease metadata values satisfy Racket's alpha-version convention
and order before `0.2`. `info.rkt` is a generated/verified consumer, not a
second version authority. A build fails before compilation if `VERSION`,
package metadata, CLI output, or artifact naming disagrees. Adding another
version state requires an explicit plan change rather than an inferred
mapping.

## Build and runtime closure

Release builds use full Racket CS 9.3 on the target operating-system family.
The build must verify the exact version and variant before compiling. The
implementation path is:

1. install or expose a sanitized package-source copy in an isolated temporary
   Racket user home;
2. compile the trusted runner with `raco exe`, retaining the default `-U`
   embedded flag and adding `++lang alone_the_lambdas` explicitly;
3. assemble the native runtime with `raco distribute`;
4. inventory, archive, and test the resulting tree after a build-to-consumer
   transfer boundary.

`-U` prevents user-specific collection and package paths from participating.
The explicit `++lang` is mandatory because Racket does not automatically
embed reader and module dependencies reached only by a dynamically loaded
`#lang`. The build must prove that the embedded language wins even when an
external collection path tries to provide the same reader name.

No new third-party dependency is approved. `raco exe` and `raco distribute`
are part of the pinned Racket toolchain. Their cost is the embedded Racket CS
runtime and transitive reader/compiler support; the observed Linux baseline is
recorded below. Adding demodularization, an installer framework, archive
library, argument parser, or updater requires a measured need and a separate
dependency decision.

The distributed tree may depend on ordinary documented operating-system
libraries for its target. Every target phase must inventory those dynamic
links, demonstrate them on the claimed consumer systems, and avoid claiming a
minimum operating-system version that has not been tested.

## Artifact names and layouts

The four initial target identifiers and archive formats are fixed:

| Target identifier | Native target | Archive |
| --- | --- | --- |
| `linux-x86_64` | Linux x86-64 | `.tar.gz` |
| `macos-x86_64` | macOS Intel 64-bit | `.tar.gz` |
| `macos-arm64` | macOS Apple Silicon | `.tar.gz` |
| `windows-x86_64` | Windows x86-64 | `.zip` |

An archive is named:

```text
alone-the-lambdas-VERSION-TARGET.EXTENSION
```

It contains one root directory named `alone-the-lambdas-VERSION-TARGET` and
this logical layout:

```text
alone-the-lambdas-VERSION-TARGET/
  bin/
    atl                 Unix
    atl.exe             Windows instead of atl
  lib/                  files emitted by raco distribute
  examples/
    hello.atl
    stdout.atl
    file-round-trip.atl
    http-server.atl
  GETTING_STARTED.md
  BUILD-MANIFEST.txt
  LICENSE
  THIRD_PARTY_NOTICES.md
```

Only the platform's one executable spelling is present. The internal `lib/`
shape may differ by platform because `raco distribute` is authoritative, but
the executable must resolve it relative to the relocated archive root.

Before an Alone the Lambdas license is approved, an internal development
artifact substitutes `UNPUBLISHED-DEVELOPMENT-ARTIFACT.txt` for `LICENSE` and
must still carry the exact provisional notices required by the bundled Racket
runtime. Such an artifact is not a public download. The final license and
runtime notice text require the Phase 27 legal inventory and Kyle's explicit
approval.

`BUILD-MANIFEST.txt` records at least the product version, source commit,
target identifier, Racket version/variant, artifact file inventory, dynamic
system-library assumptions, and archive SHA-256. It contains no secret,
absolute checkout path, temporary path, user name, package registry, or
nondeterministic local timestamp.

## Release authority

Building and testing development or release-candidate archives does not grant
permission to publish them. Publication remains blocked until all of these are
true:

- Kyle has explicitly approved the repository license and bundled-runtime
  notices after seeing their exact terms;
- all four native build and no-Racket consumer jobs pass for one source
  commit;
- the complete source purity, boundary, behavior, and acceptance suites pass;
- the final artifact names, sizes, checksums, supported systems, known limits,
  and signed/unsigned status have been presented literally;
- Kyle explicitly authorizes the exact public tag, GitHub Release, and files.

Approval of this document authorizes only Phase 22 implementation. It does not
authorize a tag, release, upload, license choice, signing operation, account
use, purchase, or public claim.

## Racket 9.3 feasibility evidence

The disposable proof ran on 2026-08-27 on Linux x86-64. It used the official
full Racket CS 9.3 Linux installer, whose observed SHA-256 matched the published
value exactly:

```text
30dc59d9b5af083eacf793253d35782c5231e8bfb7a7331fe32ccd9a41fd792f
```

The proof used no production launcher file. Its temporary loader converted
one command-line source string to a complete path and called
`dynamic-require` once. The package-source staging walk rejected symlinks and
excluded all dotenv, VCS, and compiled entries before copying.

Observed sequence:

1. An isolated copied package installed successfully with full Racket CS 9.3
   and `--deps fail`.
2. Racket 9.3 dynamically loaded an external `hello.atl` through the existing
   reader and printed the expected host output.
3. `raco exe ++lang alone_the_lambdas` embedded the loader and dynamic
   language closure.
4. `raco distribute` produced a movable Linux tree.
5. A stock `ubuntu:24.04` container with no `racket` or `raco` command and no
   checkout mounted ran the external source successfully.
6. A second `.atl` program was created only after packaging. The unchanged
   distribution was mounted at a different path in another clean container,
   dynamically loaded that new source, printed its distinct expected output,
   and exited `0`.
7. A separate collection path containing a conflicting
   `alone_the_lambdas/lang/reader.rkt` could not replace the embedded reader;
   the packaged language still ran the canonical program.
8. A binary-string probe found no proof-directory or repository-checkout path
   in either distributed file.

The verbose executable build observed all 29 current ATL production modules
enter the embedded closure: both macros, all core modules, all effect modules,
the codec, the host, the reader, and the expander. The closure also included
the existing Lazy Racket implementation, its transitive stepper syntax support,
Racket base/command-line/path/file/TCP support, `syntax/module-reader`, and the
Racket reader/expansion support selected by `++lang`.

The baseline Linux distribution contained exactly two loose files:

| File | Bytes | Purpose |
| --- | ---: | --- |
| `bin/atl-proof` | `3,946,887` | executable with runner and embedded module closure |
| `lib/plt/racketcs-9.3` | `51,412,696` | Racket CS runtime image |
| total | `55,359,583` | installed proof tree |

A disposable gzip archive was `11,292,764` bytes. These are feasibility
measurements, not release-size promises or optimization targets.

Both distributed ELF files dynamically resolved the same ordinary Linux
system set in this environment: the ELF loader, `libc`, `libdl`, `libm`,
`libpthread`, `librt`, and `libz`. No claim about another Linux distribution
or minimum kernel follows from this one observation.

The proof is consistent with Racket's official documentation:

- [`raco exe`](https://docs.racket-lang.org/raco/exe.html) embeds statically
  required modules, requires explicit `++lang` for a dynamically loaded
  `#lang`, and does not automatically include arbitrary dynamic modules.
- [`raco distribute`](https://docs.racket-lang.org/raco/exe-dist.html) gathers
  the executable's shared libraries and runtime files into a movable
  same-platform directory.

## What remains unproven

The Phase 21 proof does not by itself claim that the product is downloadable
today. At that point it had not implemented or tested the approved command
parser, dotenv rejection, declaration preflight, stable diagnostics, version
derivation, canonical artifact layout, reproducible build, macOS artifacts,
Windows artifact, license notices, signing, or public download workflow. It
used a temporary proof executable named `atl-proof`, not the Phase 22 `atl`
runner recorded below.

Linux has only one Ubuntu 24.04 consumer observation so far. The system-library
floor, cold startup measurements, canonical application suite, filesystem and
loopback HTTP acceptance, relocation matrix, archive manifest, and clean
consumer automation belong to Phases 24 through 26.

## Phase 22 implementation record

Phase 22 implemented the approved development surface on 2026-08-27. Root
`VERSION` now owns `0.2.0-dev`; `info.rkt` carries the verified `0.1.900`
projection; `runner/atl.rkt` implements the exact three-command grammar and
embeds the root-derived CLI version during expansion/build, contains no copied
public version literal, and performs one validated module load; `examples/`
contains exactly the four canonical `.atl` files. The complete suite passed
4,412 assertions across 31 test files,
the unchanged 16-module expanded purity scan, and the 79-source boundary
inventory. Phase 23 still owns the final user-facing diagnostic templates and
path/source-position sanitization. Phases 24 through 27 still own native
artifacts, clean consumer proof, novice documentation, license approval, and
release-candidate work; nothing in Phase 22 authorizes publication.

## Approval record

Approval accepts the `.atl` source rules, exact command surface, completion and
exit-status distinction, separately classified trusted-loader capability,
single-version authority and Racket metadata projection, artifact names and
layouts, four native targets, unsandboxed real-host authority, and release
approval gates defined above.

Kyle explicitly approved this design and authorized Phase 22 on 2026-08-27 by
replying:

```text
Approve the Phase 21 standalone-distribution design.
```

This approval does not authorize a public release, license selection, tag,
upload, signing operation, or publication claim. Those later gates remain in
force exactly as specified above.
