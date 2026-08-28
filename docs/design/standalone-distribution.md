# Standalone distribution design

Status: original contract approved 2026-08-27; Phases 22 through 27
implemented; Phase 27 rename and native CI verification completed 2026-08-28

Date: 2026-08-27

This document fixes the current contract for distributing AttaLambda as an
independently runnable language. It is subordinate to the three canonical
[specifications](../specifications/README.md) and to the already approved
[host boundary](host-boundary.md). Approval authorized the implementation
work that began in Phase 22; it does not authorize a public release.

## Verified starting state

This section and the Phase 21 through 26 implementation records preserve the
literal pre-rename names because they describe what existed and what was
actually tested at those times. The Phase 27 record supersedes those names for
every current public surface.

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
attalambda FILE.attl
```

The archive carries the Racket runtime, reader, expander, compiler support,
all AttaLambda production modules, and every non-system runtime file
needed to load an external source file. At run time it must not require:

- a `racket` or `raco` command;
- an installed AttaLambda package;
- a Racket user package registry or collection tree;
- this repository or another source checkout;
- the build directory or its absolute paths;
- a network service.

This is a distribution promise, not a sandbox promise. A program run with the
real host has the launching process's already documented stdout, filesystem,
name-resolution, connection, and listening authority.

## `.attl` source contract

`.attl` is the canonical public source extension. It changes the public file
name, not the language grammar or evaluator.

A runnable source must satisfy all of these rules:

- The supplied final path component ends in the exact lowercase bytes `.attl`.
  The check is case-sensitive on every platform, including Windows. `.ATTL`,
  `.Attl`, and a missing suffix are invalid.
- The source is a regular file. Directories, devices, FIFOs, and other special
  inputs are not source files.
- The first logical line is exactly `#lang attalambda`, with no byte
  order mark, leading whitespace, trailing whitespace, shebang, alternate
  spelling, or version suffix. It may end with LF, CRLF, or end of file.
- The remaining source is read by the existing `lang/reader.rkt` and expanded
  by the existing `lang/expander.rkt`. The launcher does not contain a second
  AttaLambda tokenizer, parser, expander, evaluator, or literal implementation.
- Source text follows Racket's UTF-8 source convention. Invalid source bytes
  are a source-read failure. AttaLambda String literals continue to lower
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
`service.env.local`, `program.env.attl`, and equivalent spellings before file
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
3. reject a non-lowercase `.attl` extension without content access;
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
attalambda FILE.attl
attalambda --help
attalambda --version
```

On Windows, `attalambda` in this grammar names `attalambda.exe`. There are no
aliases, combined flags, short flags, retired `run` subcommand, program arguments, REPL mode,
stdin-source mode, compiler mode, or package-manager mode in this milestone.
A path beginning with `-` is supplied with an explicit directory component,
such as `./-example.attl`.

`attalambda --help` writes exactly this text to stdout and exits successfully:

```text
Usage:
  attalambda FILE.attl
  attalambda --help
  attalambda --version
```

`attalambda --version` writes `AttaLambda VERSION` followed by one newline,
where `VERSION` is the exact canonical product version described below. The
initial development output is therefore:

```text
AttaLambda 0.2.0-dev
```

Help and version write nothing to stderr and do not inspect a user source
path. Successful source execution reserves stdout for effects explicitly requested by
the AttaLambda program. Launcher diagnostics use stderr only.

## Completion and exit statuses

Launcher-controlled completion uses this closed status table on every target:

| Status | Meaning | Conditions |
| --- | --- | --- |
| `0` | successful command | help/version completed, or the source module instantiated without an uncaught host-level failure |
| `64` | command misuse | missing command, unknown command/flag, missing source argument, or extra argument |
| `65` | invalid AttaLambda source | wrong extension, malformed language declaration, invalid source encoding, reader failure, syntax failure, or expansion failure |
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

- a lambda-encoded Error is a completed AttaLambda value, not a Racket exception;
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

Normal diagnostics name AttaLambda, the user's source spelling, and an
actionable reason. They do not expose raw host procedures, exception object
renderings, Racket stack traces, package registry paths, source-checkout
paths, or build paths. Phase 23 freezes the exact templates below without
changing the status classifications above.

The three output shapes are:

```text
AttaLambda: REASON
AttaLambda: "SOURCE": REASON
AttaLambda: "SOURCE":LINE:COLUMN: REASON
```

`SOURCE` is the original command-line spelling. It is quoted, with control
characters, quotes, and backslashes escaped, so one diagnostic remains one
line. The canonical reader supplies one-based lines and zero-based columns.
No resolved source location is used. The exact reasons are:

| Class | Status | Exact reason |
| --- | ---: | --- |
| command misuse | 64 | `expected attalambda FILE.attl, attalambda --help, or attalambda --version` |
| supplied or resolved dotenv path | 66 | `refused source path because dotenv files are never read` |
| wrong extension | 65 | `source file name must end in lowercase .attl` |
| source-entry symlink | 66 | `refused symbolic-link source; choose a regular .attl file` |
| uninspectable path metadata | 66 | `source path could not be inspected` |
| missing source | 66 | `source file was not found` |
| nonregular source | 66 | `source path is not a regular file` |
| unreadable source | 66 | `source file could not be read` |
| malformed declaration | 65 | `line 1 must be exactly #lang attalambda` |
| invalid byte encoding | 65 | `source is not valid UTF-8` |
| reader failure | 65 | `source could not be read; check delimiters and UTF-8 encoding` |
| unavailable identifier | 65 | `unknown AttaLambda name: IDENTIFIER` |
| unsupported datum | 65 | `unsupported literal; only nonnegative Nat and String literals are supported` |
| other expansion failure | 65 | `source has invalid syntax` |
| unexpected launcher failure | 70 | `unexpected launcher failure; verify the AttaLambda installation` |

`IDENTIFIER` is written as a safely escaped source symbol. A missing internal
language module is an unexpected launcher failure; a missing requested source
remains unavailable input. No exception message is copied into a diagnostic.

## Trusted launcher boundary

The launcher is module-loading scaffolding, which the specifications permit
separately from object-language computation. Loading a language necessarily
reads and expands the one source file the user asked to run. That launch-time
read is not a second effect function callable by AttaLambda code.

The `runner/` class may use host facilities only for these closed
purposes:

- observe its own command-line argument vector;
- emit the fixed help/version text and fixed stderr diagnostics;
- set its process exit status;
- perform lexical path, suffix, and dotenv-name checks;
- resolve and inspect metadata for the one supplied source path;
- read the exact language declaration and validate the remaining source bytes
  only as strict UTF-8, without tokenizing or interpreting them;
- dynamically load that same source path once;
- categorize reader, syntax, expansion, input, and unexpected implementation
  exceptions for the exit table;
- access the canonical product version as build/module metadata.

This allows the narrowly required Racket command-line, path, file-metadata,
byte/header, exception, and `dynamic-require` machinery. Host Strings,
Booleans, lists, regex matching, conditionals, and exit codes used inside this
class decide only whether and how the host process loads a requested module.
They never become object-language values and never determine an AttaLambda
computational result.

The class must satisfy all of these isolation rules:

- it exports no object-language binding, host callback, loader, namespace,
  source port, parsed syntax, or conversion function;
- no `core/`, `effects/`, `runtime/`, `codec`, macro, reader, expander, or
  language-facade module may import it;
- AttaLambda source cannot name, require, or invoke it;
- it cannot import a reader, test, tooling, application, or object-value codec
  to interpret a completed value;
- it cannot implement AttaLambda parsing, type checks, arithmetic, routing, Result
  control flow, or another effect operation;
- it cannot enumerate environment variables, run a process, invoke a shell,
  use FFI, contact a network service, scan a directory, or discover another
  source file;
- it cannot broaden the real host operation set or bypass `host` for an
  effect requested by AttaLambda code.

Phase 22 added an exact structural classification for this path and fails
closed on unknown files or capabilities. The existing production ban on
dynamic loading remains in every other class. The sole-language-visible-host
proof therefore stays literally true.

## Version authority

Phase 22 created a root `VERSION` text file as the only manually edited product
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
   embedded flag and adding `++lang attalambda` explicitly;
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
attalambda-VERSION-TARGET.EXTENSION
```

It contains one root directory named `attalambda-VERSION-TARGET` and
this logical layout:

```text
attalambda-VERSION-TARGET/
  bin/
    attalambda                 Unix
    attalambda.exe             Windows instead of attalambda
  lib/                  runtime support files, empty when none are required
  examples/
    hello.attl
    stdout.attl
    file-round-trip.attl
    http-server.attl
  GETTING_STARTED.md
  BUILD-MANIFEST.txt
  LICENSE
  THIRD_PARTY_NOTICES.md
```

The finished archive is accompanied by one external `SHA256SUMS` file. Keeping
the archive digest outside the bytes it authenticates avoids an impossible
self-referential checksum and lets a user verify the download before
extraction. Kyle approved this correction on 2026-08-28.

Only the platform's one executable spelling is present. The internal `lib/`
contents may differ by platform because `raco distribute` is authoritative;
the directory remains present for a stable archive shape and is empty when
Racket emits no separate support files. The executable must resolve any
support files relative to the relocated archive root.

The repository now has an approved Apache License 2.0. Internal development
artifacts still substitute `UNPUBLISHED-DEVELOPMENT-ARTIFACT.txt` for
`LICENSE` and carry provisional bundled-Racket notices until Phase 28 approves
the exact runtime notice set and release-candidate contents. Such an artifact
is not a public download, and repository-license approval does not authorize
its publication.

`BUILD-MANIFEST.txt` records at least the product version, source commit,
target identifier, Racket version/variant, artifact file inventory, and
dynamic system-library assumptions. The sibling `SHA256SUMS` records the final
archive SHA-256 and filename. Neither file contains a secret, absolute checkout
path, temporary path, user name, package registry, or nondeterministic local
timestamp.

## Release authority

Building and testing development or release-candidate archives does not grant
permission to publish them. Publication remains blocked until all of these are
true:

- Kyle has explicitly approved the repository license, and later explicitly
  approves the bundled-runtime notices after seeing their exact terms;
- all four native build and no-Racket consumer jobs pass for one source
  commit;
- the complete source purity, boundary, behavior, and acceptance suites pass;
- the final artifact names, sizes, checksums, supported systems, known limits,
  and signed/unsigned status have been presented literally;
- Kyle explicitly authorizes the exact public tag, GitHub Release, and files.

Any cross-job GitHub Actions artifact transfer is itself a temporary public
upload and requires phase-specific explicit approval even when the cleanup job
deletes it immediately.

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

Phase 24 now supplies the Linux archive manifest, reproducible build, startup
measurement, canonical application/effect checks, hostile collection-path
probe, and relocation automation described below. Its consumer evidence is
limited to one digest-pinned Ubuntu 24.04 image; it establishes no older Linux
floor. Phase 25 supplies native macOS x86_64 and arm64 artifacts plus clean
same-architecture consumer proof on macOS 15.7.9 and 15.7.7 respectively; it
establishes no older macOS floor. Phase 26 supplies a native Windows x86-64
artifact plus clean cross-drive consumer proof on Microsoft Windows Server
2025 Datacenter 10.0.26100, build 26100; it establishes no older Windows floor
or Windows client-edition support. Lower compatibility floors, the final legal
inventory, a signed artifact, installer behavior, and publication remain
unproven.

## Phase 22 implementation record

Phase 22 implemented the approved development surface on 2026-08-27. Root
`VERSION` now owns `0.2.0-dev`; `info.rkt` carries the verified `0.1.900`
projection; `runner/atl.rkt` implements the exact three-command grammar and
embeds the root-derived CLI version during expansion/build, contains no copied
public version literal, and performs one validated module load; `examples/`
contains exactly the four canonical `.atl` files. The complete suite passed
4,412 assertions across 31 test files,
the unchanged 16-module expanded purity scan, and the 79-source boundary
inventory. At that historical boundary, Phase 23 still owned the final
user-facing templates and path/source-position sanitization. Phases 24 through
27 still own native artifacts, clean consumer proof, novice documentation,
license approval, and release-candidate work; nothing in Phase 22 authorizes
publication.

## Phase 23 implementation record

Phase 23 implemented the diagnostic contract on 2026-08-28. The runner now
emits only the exact ATL templates above, quotes the original source spelling,
uses canonical reader line/column metadata without printing its resolved
source path, distinguishes requested-source loss from a missing internal
language module, and never renders an exception object or message.

An implementation probe established that Racket's ordinary source port
replaces malformed UTF-8 bytes with `U+FFFD` instead of raising a read failure.
`source-preflight-result` therefore validates the bytes after the already
exact ASCII declaration with strict `bytes->string/utf-8` before the existing
reader runs. This is encoding validation, not a tokenizer, parser, expander,
or evaluator. It reads no path other than the one already supplied and does
not retain or expose the temporary host String. The implementation adds one
direct `racket/port` standard-library import for `port->bytes`, no third-party
package, and no package-metadata dependency. Phase 24 measured the resulting
complete runner/runtime closure; it does not attribute a marginal size to this
one transitive import.

Focused tests pin every diagnostic byte and status, preserve relative and
Unicode path spelling, reject invalid encoding, and keep contract Error, pure
Result Err, and real-host Result Err completion at status 0. A disposable
runner copy injects raw host detail at the sole loader call and proves the
status-70 handler emits none of it. The boundary gate separately pins the
formatter, strict encoding operation, imports, definitions, vocabulary, one
loader call, no exports, and every forbidden dependency direction. Phase 23
changes no core/effect/runtime/language executable, object representation,
effect order, or host authority.

Completion verification passed 4,449 assertions across all 31 test files, the
unchanged expanded purity scan over 16 `core/` modules, and the complete
79-source boundary inventory. The focused runner suite passed 161 assertions;
the adversarial boundary suite passed 112.

## Phase 24 implementation record

Phase 24 implemented `tooling/build-linux-distribution.sh` as the one Linux
x86-64 build entry point. It verifies the exact full Racket CS 9.3 toolchain,
the product/package version projection, architecture, clean-source state by
default, nonsymlink source inputs, and an output directory outside the
checkout. It copies only production package sources into disposable storage,
installs them under an isolated Racket user home with dependency downloads
forbidden, calls `raco exe ++lang alone_the_lambdas`, then calls
`raco distribute`. Normalized file metadata, sorted POSIX tar entries, and
gzip's timestamp-free mode make identical inputs byte reproducible. The build
refuses to replace output files and emits one external `SHA256SUMS` beside the
archive.

The development payload contains 10 files. Its runtime inventory is
`bin/atl` (`7,853,237` bytes) and `lib/plt/racketcs-9.3` (`51,412,696` bytes);
the other eight files are the four canonical examples plus the manifest,
guide, unpublished warning, and generated provisional Racket notices. The
unoptimized archive measured `13,679,991` compressed bytes and `59,299,555`
unpacked regular-file bytes. Both ELF files observed the same seven system
assumptions as the feasibility proof: the ELF loader, `libc`, `libdl`, `libm`,
`libpthread`, `librt`, and `libz`.

Two disposable builds from different temporary paths over the same approved
uncommitted Phase 24 source state based on commit
`ce55da42a06a4edc5ef37e2d1ca787b5bc1de8fc` were byte-identical. Later
rebuilds after output, permission, and dotenv-pruning hardening retained SHA-256
`a5e43c54467fa4afe0bb74aeeda962ae617de26b35c6cf50d65891de81b64cf0`.
That digest describes only those internal validation artifacts; it is not a
release checksum or a claim about a later clean commit.

`tooling/test-linux-distribution.sh` copied only the archive, checksum, and
consumer harness into
`ubuntu:24.04@sha256:561618e2c15bf2397621dd04f96926663a3b5616c189cf7e38db7e82f5c538ea`.
The container ran as an unprivileged user with a read-only root, no
capabilities, no `racket`/`raco`, and no external Docker network. It verified
the digest before extraction; exact layout, file inventory, permissions,
help/version bytes, and clean stderr; a source created after packaging;
embedded-language precedence over a conflicting collection path; stdout,
isolated file, and ephemeral-loopback HTTP behavior; and a second run after
moving the tree between paths containing spaces. Final runs observed
290–344 ms for the first process and 294–302 ms after relocation. These are
observations, not
startup guarantees or a Linux compatibility floor.

Phase 24 adds no Racket production source, object-language operation,
representation, host capability, package dependency, demodularization step,
license choice, public artifact, tag, upload, or release authority.

Completion verification passed 4,492 assertions across all 32 test files, the
unchanged expanded purity scan over 16 `core/` modules, and the complete
80-source boundary inventory. The focused distribution contract suite passed
43 assertions, and the no-Racket consumer harness passed independently.

## Phase 25 implementation record

Phase 25 implemented `tooling/build-macos-distribution.sh` for exact native
`macos-x86_64` and `macos-arm64` targets. It requires Darwin, matching native
hardware, and full Racket CS 9.3; verifies the same version projection,
clean-source, nonsymlink-input, isolated-registry, and no-dependency-download
contracts as the Linux builder; invokes the same `raco exe ++lang
alone_the_lambdas` and `raco distribute` path; and emits a predictably named
`.tar.gz` plus external `SHA256SUMS`. It additionally validates every Mach-O
file with `file`, `lipo`, and `otool`; rejects unexpected architecture and
non-system absolute dependencies; normalizes tar/gzip metadata; and scans all
payload bytes for checkout, temporary-build, package-home, and nonstandard
toolchain paths.

The first native run observed that Racket CS 9.3 returned success and produced
`bin/atl` on both architectures but no `lib/`. Racket documents that support
directories contain the separate files needed by the executable, and the
later clean consumers proved these executables needed none. The builder had
incorrectly required Racket itself to create that directory. The corrected
builder rejects an existing symlink or non-directory and otherwise creates an
empty mode-0755 `lib/`, preserving the approved stable archive layout without
inventing a runtime dependency. A focused regression assertion pins that
normalization.

`tooling/test-macos-distribution.sh` is self-contained so a consumer job needs
no checkout. It verifies no `racket` or `raco` command is present, validates
the external checksum before extraction, rejects unsafe paths and symlinks,
checks the exact layout/manifest/permissions and native dependency inventory,
and exercises exact help/version bytes with clean stderr. It then runs a source
created after packaging, proves a hostile external collection path cannot
replace the embedded language, performs the canonical stdout, isolated-file,
and ephemeral-loopback HTTP effects, moves the tree between paths containing
spaces, and repeats version plus generated-source runs.

Validation commit `ed0db7df9ca17d4e7b2ea458069f7861c1207a2d`
passed all jobs in [GitHub Actions run
33181962284](https://github.com/kserrec/alone_the_lambdas/actions/runs/33181962284):

| Observation | macOS Apple Silicon | macOS Intel |
| --- | --- | --- |
| Target | `macos-arm64` | `macos-x86_64` |
| Clean consumer | macOS 15.7.7 arm64 | macOS 15.7.9 x86_64 |
| Regular files | 9 | 9 |
| Mach-O runtime files | 1 (`bin/atl`) | 1 (`bin/atl`) |
| Compressed bytes | `13,698,161` | `13,669,470` |
| Unpacked regular-file bytes | `62,117,801` | `59,412,300` |
| SHA-256 | `8f428ff16be4acbf4a8ad41ce7241a40a623931ef9b5451c81b83e2fd2aad63f` | `7ac92ca6aa49ce2882e43ab0d318d034932cc06cfe88e9554048b018ec0742ab` |
| First startup | 194 ms | 1,170 ms |
| Relocated startup | 121 ms | 319 ms |

Both executables observed only CoreFoundation, `libSystem`, `libiconv`, and
`libncurses` as dynamic system-library assumptions. Both consumers reported no
`racket` command, no `raco` command, no checkout, passed relocation, and passed
all acceptance checks. These two exact operating-system versions are the oldest
and only macOS versions demonstrated. The sizes, hashes, libraries, and timings
describe only the disposable artifacts from the named validation commit; they
are not minimum-version claims, performance guarantees, signing claims,
release checksums, or public downloads.

The workflow uses the existing pinned setup/checkout actions plus two narrowly
justified CI-only transfer dependencies: official `actions/upload-artifact`
v7.0.1 and `actions/download-artifact` v8.0.1, each pinned by full commit. Their
cost is transient GitHub artifact storage and two action implementations in
the CI dependency surface; they add no package or runtime dependency. Kyle's
explicit approval permits only these temporary unpublished transfers. The
workflow sets one-day retention as a cleanup-failure fallback, then an
`always()` job with `actions: write` and `contents: none` deletes both exact
artifact names and verifies no matching artifact ID remains. The successful
run's artifact API reported zero artifacts immediately after cleanup.

Phase 25 changed CI, shell build/consumer tooling, focused tests, and
documentation. It changed no production Racket source, object-language
operation, representation, effect order, or host authority. Completion
verification passed 4,541 assertions across all 32 test files, the unchanged
expanded purity scan over 16 `core/` modules, and the complete 80-source
boundary inventory. The focused distribution contract suite passed 92
assertions, and both independent no-Racket macOS consumer jobs passed.

## Phase 26 implementation record

Phase 26 implemented `tooling/build-windows-distribution.ps1` for the exact
native `windows-x86_64` target. It requires x86-64 Windows and full Racket CS
9.3; verifies the closed version projection and clean nonsymlink inputs; copies
only the approved production package into a disposable tree; isolates
`PLTUSERHOME` and temporary directories; and installs with `--deps fail`.
The workflow installs Racket before checkout so setup-action residue cannot
make the checked-out source tree appear dirty. The builder invokes `raco exe
--embed-dlls ++lang alone_the_lambdas` followed by `raco distribute` and
accepts exactly one resulting runtime file, `bin/atl.exe`.

The builder creates a stable empty `lib/` because Racket CS 9.3 embedded the
required DLLs and emitted no loose support file on the demonstrated target. It
generates the approved guide, provisional notices, four examples, and build
manifest; fixes ZIP entry timestamps at 1980-01-01; orders entries
deterministically; and writes the archive digest only to external
`SHA256SUMS`. It parses the executable's PE header and requires machine value
`0x8664`, inventories DLL dependencies with native `dumpbin`, records the
exact Authenticode status, and scans every payload file for complete known
checkout, isolated-user-home, package-source, temporary-build, and
nonstandard-toolchain paths.

An observed Windows executable retained the isolated user home's directory
basename, `racket-user`, without retaining the complete disposable path. That
retained fragment is not an operational runtime dependency: the builder still
rejects the complete known path, and the clean consumer subsequently ran after
cross-drive relocation with neither Racket nor the registry available. The
consumer therefore retains precise checkout,
runner-temporary, runner-profile, build-root, and package-source byte scans,
while the exact builder-side scan plus independent relocation own the
package-registry dependency proof.

`tooling/test-windows-distribution.ps1` is self-contained and receives only
the archive, external checksum, and itself. It requires no source checkout or
Racket installation; validates the checksum before extraction; rejects unsafe
ZIP names; checks the exact layout, manifest, PE machine, DLL inventory, and
Authenticode status; and exercises exact help/version/status and clean-stderr
behavior. It runs a canonical source created after packaging, proves a hostile
external collection cannot replace the embedded language, performs stdout,
isolated file replacement/readback, and ephemeral-loopback HTTP effects, then
copies the extracted tree from the runner's `D:` drive to a path containing
spaces on `C:`, deletes the first tree, and repeats version and generated-source
runs.

Validation commit `a9f2bdc7d07a0283871ede548aa0c33cee0a3b78`
passed the Windows build, independent consumer, and cleanup jobs in [GitHub
Actions run
33193791101](https://github.com/kserrec/alone_the_lambdas/actions/runs/33193791101).
The clean consumer was Microsoft Windows Server 2025 Datacenter 10.0.26100,
build 26100, x86-64. It reported no `racket` command, no `raco` command, and no
checkout. Builder and consumer agreed on a 9-file payload, `15,251,225`
compressed bytes, `23,875,480` unpacked regular-file bytes, and SHA-256
`32323a72bb4dad11690f5189cdc543fcc49bb6138d1e1abe19e4694c0595b397`.
The payload had one PE/runtime file, `bin/atl.exe`, with observed system-DLL
assumptions `KERNEL32.dll`, `msvcrt.dll`, and `USER32.dll`; its Authenticode
status was exactly `NotSigned`. Startup observations were 282 ms initially and
360 ms after cross-drive relocation.

These operating-system, size, hash, dependency, signing, and timing values
describe only that disposable validation artifact. They are not a lower
Windows compatibility floor, client-Windows claim, performance guarantee,
signing promise, release checksum, installer, or public download.

The workflow reused the existing full-commit-pinned official
`actions/upload-artifact` v7.0.1 and `actions/download-artifact` v8.0.1
dependencies. Their Phase 26 cost is one transient workflow artifact and two
existing CI action implementations; they add no package or runtime dependency.
Kyle's narrow approval covered only this unpublished archive, checksum, and
harness. The upload used one-day retention solely as a cleanup-failure
fallback; an `always()` job with `actions: write` and `contents: none` deleted
the exact artifact immediately and verified it was absent. The completed run's
artifact API reported zero artifacts.

Phase 26 changed CI, PowerShell build/consumer tooling, focused tests, and
documentation. It changed no production Racket source, object-language
operation, representation, effect order, or host authority. Completion
verification passed 4,589 assertions across all 32 test files, the unchanged
expanded purity scan over 16 `core/` modules, and the complete 80-source
boundary inventory. The focused distribution contract suite passed 140
assertions, and the independent no-Racket Windows consumer passed.

## Phase 27 implementation record

Phase 27 adopts `AttaLambda` for the public project and language name;
`attalambda` for the repository, Racket package and collection, executable,
runner, artifact roots, and workflow artifacts; `.attl` for source files; and
exact `#lang attalambda` declarations. Execution is direct:
`attalambda FILE.attl`. The old `atl`, `.atl`, `#lang alone_the_lambdas`, and
`run` subcommand spellings are rejected rather than retained as aliases.

The implementation renames the runner and four examples; changes collection
resolution in `info.rkt` and `lang/reader.rkt`; synchronizes build and consumer
tooling for Linux, macOS, and Windows; updates workflow artifact and cleanup
names; and updates current specifications, architecture, acceptance evidence,
and guides. The structural scanner uses an in-memory collection link from
`attalambda` to its already validated project root, so source inspection does
not depend on the private checkout directory name or mutate a Racket package
registry. Historical Phase 21 through 26 artifact names, measurements, run
URLs, and verbatim approvals remain literal records of the pre-rename work.

Local completion verification passed 4,617 assertions across all 32 test
files, the unchanged expanded purity proof over 16 `core/` modules, and the
complete zero-finding 80-source boundary inventory. Focused runner,
fresh-language, boundary, distribution-contract, and real-application suites
passed 181, 78, 113, 144, and 22 assertions respectively. The public GitHub
repository has now been renamed to `kserrec/attalambda`, and the verified local
`origin` points to that destination. Validation commit
`a048550e619499e0fbb3f944ba959ef84c4cc586` repeated the complete suite and
passed every native build, clean-consumer, and cleanup job in [GitHub Actions
run 33204885605](https://github.com/kserrec/attalambda/actions/runs/33204885605).

That run produced and consumed these exact disposable renamed archives:

| Target | Exact consumer | Compressed bytes | Unpacked regular-file bytes | SHA-256 | Startup before / after relocation |
| --- | --- | ---: | ---: | --- | ---: |
| `linux-x86_64` | digest-pinned Ubuntu 24.04 container | `13,679,896` | `59,297,302` | `3708c56c8bcdf91d158b2d2c1e674a37d2b7bb61b4908805ad1c4a247e7c2ab7` | 176 ms / 172 ms |
| `macos-arm64` | macOS 15.7.7 arm64 | `13,697,971` | `62,117,764` | `1baa39170ba33233cbb1ff638bd713d2785957c6dcca3542523ed3c0262a1b4a` | 229 ms / 176 ms |
| `macos-x86_64` | macOS 15.7.9 x86-64 | `13,669,228` | `59,412,256` | `e779b2c5b6a069fa56c95f92daaf52b0c2517ba964472f05c57ee34472164f5b` | 311 ms / 312 ms |
| `windows-x86_64` | Microsoft Windows Server 2025 Datacenter 10.0.26100 x86-64 | `15,250,871` | `23,871,340` | `fdc4597628dbc1ba954c53700491cf9109c189f47129b78091dd62b05fbfe686` | 241 ms / 489 ms |

The Linux archive contained 10 regular files and two runtime files. Each
macOS archive contained nine regular files and one Mach-O runtime file,
`bin/attalambda`; both observed only CoreFoundation, `libSystem`, `libiconv`,
and `libncurses` as dynamic system-library assumptions. The Windows archive
contained nine regular files and one PE/runtime file, `bin/attalambda.exe`;
it observed `KERNEL32.dll`, `msvcrt.dll`, and `USER32.dll`, and its exact
Authenticode state was `NotSigned`. Every clean consumer reported no `racket`
command, no `raco` command, and no checkout, then passed the direct command,
effects, embedded-reader, and relocation checks.

Linux stayed within one job and did not use GitHub artifact storage. The two
macOS archives and one Windows archive crossed only the explicitly approved
temporary transfer boundary with one-day retention as a cleanup-failure
fallback. Their consumer and `always()` cleanup jobs all passed, and the
completed run's artifact API reported `total_count: 0`. These measurements
describe only deleted development artifacts; they are not release checksums,
performance guarantees, compatibility floors, or public downloads.

No core, effect, runtime, macro, or expander executable changed. The reader
changes only its collection target; the runner intentionally changes its
public launch contract; the examples intentionally change their declaration,
branding bytes, and round-trip filename. Product version remains
`0.2.0-dev`. This work creates no release candidate, binary release, tag,
GitHub Release, signature, or public download.

## Approval record

The original Phase 21 approval accepted the pre-rename `.atl`, `atl run`, and
`#lang alone_the_lambdas` spellings alongside the completion and exit-status
distinction, trusted-loader capability, version projection, native targets,
unsandboxed real-host authority, and release gates. Phase 27 supersedes only
those public names and the direct command shape; the other approved contracts
remain in force.

Kyle explicitly approved this design and authorized Phase 22 on 2026-08-27 by
replying:

```text
Approve the Phase 21 standalone-distribution design.
```

Kyle explicitly approved moving the archive checksum out of the internal
manifest on 2026-08-28 by replying:

```text
Approve the Phase 24 external checksum manifest correction.
```

Kyle explicitly approved the temporary Phase 25 GitHub Actions transfer on
2026-08-28 by replying:

```text
Approve temporary public GitHub Actions artifact transfer and immediate deletion for Phase 25.
```

That approval permits only the two unpublished macOS development archives and
their consumer harnesses to exist as workflow artifacts long enough for the
separate native consumer jobs to finish. The workflow must delete both
artifacts immediately afterward and set one-day retention only as a cleanup-
failure fallback.

Kyle explicitly approved the temporary Phase 26 GitHub Actions transfer on
2026-08-28 by replying:

```text
Approve temporary public GitHub Actions artifact transfer and immediate deletion for Phase 26.
```

That approval permits only the one unpublished Windows x86-64 development
archive, its external checksum, and its self-contained consumer harness to
exist as a workflow artifact long enough for the separate Windows consumer
job to finish. The workflow must delete that exact artifact immediately
afterward and set one-day retention only as a cleanup-failure fallback.

This approval does not authorize a public release, license selection, tag,
upload, signing operation, or publication claim. Those later gates remain in
force exactly as specified above; the one narrow CI-transfer upload is the
only added authority.

Kyle explicitly approved Apache License 2.0 for Alone the Lambdas and
confirmed Kyle Serrecchia as the 2026 copyright owner on 2026-08-28 by
replying:

```text
Approve Apache License 2.0 for Alone the Lambdas, with Kyle Serrecchia as the 2026 copyright owner. This authorizes adding and pushing the license for Phase 27, but does not authorize any binary release, Git tag, GitHub Release, artifact transfer, signing operation, or publication of release-candidate files.
```

That approval authorizes the root `LICENSE`, the `Apache-2.0` Racket package
metadata, the copyright and approval records, and pushing those source changes
to the existing repository. It does not approve the final bundled-runtime
notices or authorize any release-candidate build, workflow artifact, tag,
GitHub Release, signing operation, or binary publication. Those Phase 28 and
Phase 29 gates remain in force.

Kyle then selected `AttaLambda` as the public name, `attalambda` as the
machine-facing and command name, `.attl` as the source extension, and direct
`attalambda FILE.attl` execution without compatibility aliases. After that
teaching and naming discussion, Kyle explicitly authorized implementation on
2026-08-28 by replying:

```text
let's do the name change now
```

That authorization covers renaming the current source, package, collection,
runner, examples, tooling, documentation, workflow names, and GitHub
repository. It does not broaden the earlier license authorization into a
binary release, Git tag, GitHub Release, release-candidate publication,
signing operation, or cross-job artifact transfer. The temporary Phase 27
transfer was therefore approved separately below.

Kyle explicitly approved the temporary Phase 27 GitHub Actions transfer on
2026-08-28 by replying:

```text
Approve temporary public GitHub Actions artifact transfer and immediate deletion for Phase 27.
```

This approval permits only the two renamed unpublished macOS development
archives and one renamed unpublished Windows x86-64 development archive,
their external checksums, and their self-contained consumer harnesses to exist
as workflow artifacts long enough for the separate clean consumer jobs. The
workflow must delete all three artifacts immediately afterward; one-day
retention is only a cleanup-failure fallback. This approval does not authorize
a release candidate, binary release, Git tag, GitHub Release, signing
operation, or public download.
