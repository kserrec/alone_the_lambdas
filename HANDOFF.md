# Session handoff

Status recorded: 2026-08-29 after the supported-platform correction to the
public AttaLambda 0.2.0 Release. Repository documentation changes are verified
and included in the Phase 30 closeout on `main`.

This handoff becomes stale if `main`, tag `v0.2.0`, GitHub Release `v0.2.0`,
or either of its two remaining manually uploaded assets changes.

## Exact current public state

- The final executable source remains commit
  `42ff0a7810ebeced445ab23561433a2dc423e433`, with root `VERSION` `0.2.0`,
  `info.rkt` version `0.2`, and runner output `AttaLambda 0.2.0`.
- The unsigned annotated tag `v0.2.0` is unchanged. Its tag-object SHA is
  `5537cf8b4dc1db31f8855e10118729ac78bc0dd0`; it peels to the source commit
  above.
- Public GitHub Release ID `379061612` remains the latest non-prerelease
  Release titled `AttaLambda 0.2.0` at
  <https://github.com/kserrec/attalambda/releases/tag/v0.2.0>.
- Its Release body now presents Linux x86-64 as the only supported public
  binary distribution and contains a literal withdrawal explanation. The
  exact body bytes have SHA-256
  `c25dca80acc2d53564be8a88f211d925e0d5fb79ef67f1ea251fd8d7db204db5`.
- The only remaining manual assets are:

  | Asset | GitHub asset ID | Bytes | SHA-256 |
  | --- | ---: | ---: | --- |
  | `attalambda-0.2.0-linux-x86_64.tar.gz` | `535549598` | `13,728,716` | `86f980d696b45b42c251b78e6a66b9cd875f649217bfb09731cf6b47c66b00ac` |
  | `SHA256SUMS` | `535549605` | `410` | `7786bf553caac0087ab22f3636d546a1fe00f89a446611c1516cc58f411f6f7f` |

- Both retained public download URLs return HTTP `200`. GitHub's automatic
  source-code ZIP and tarball remain available and are not runnable binary
  distributions.

## Withdrawn assets

Kyle reported that launching a public AttaLambda macOS download produced
Gatekeeper's malware-verification block with only Trash or dismissal. The
macOS consumer harness had proved isolated execution after an Actions artifact
transfer, but had not applied browser quarantine metadata or assessed
Gatekeeper.

The final Windows executable was already verified Authenticode `NotSigned`.
Microsoft's current SmartScreen developer guidance says unsigned downloads
receive “Windows protected your PC,” require “Run anyway,” and may be blocked
without an override under enterprise policy. Windows 11 Smart App Control can
also block unsigned files when its cloud prediction cannot establish safety.
No downloaded-user Windows client test had been performed.

With Kyle's explicit authorization, these exact public assets were deleted:

| Withdrawn asset | GitHub asset ID | SHA-256 |
| --- | ---: | --- |
| `attalambda-0.2.0-macos-arm64.tar.gz` | `535549609` | `5791ca3c28717972409d0d3503e135f685bcb7011ec24e6e4f9e70c7e5426b2b` |
| `attalambda-0.2.0-macos-x86_64.tar.gz` | `535549602` | `72f56f4d95665a3ca802160175c4082ce42b08054a35b963a10b0597b9d91fdc` |
| `attalambda-0.2.0-windows-x86_64.zip` | `535549611` | `0ffcf7cd7218459efe1de1de87c7ff650328d01b16caa253deb6aa621188015a` |

All three exact withdrawn URLs now return HTTP `404`. The tag, Release, Linux
asset, manifest, and source archives were not deleted or replaced.

## Recovery and immutable publication history

Immediately before deletion, each withdrawn public digest still matched the
byte-identical recovery copy in
`/tmp/attalambda-phase29-release-1wXfDu/assets`. The exact original files are:

```text
86f980d696b45b42c251b78e6a66b9cd875f649217bfb09731cf6b47c66b00ac  attalambda-0.2.0-linux-x86_64.tar.gz
5791ca3c28717972409d0d3503e135f685bcb7011ec24e6e4f9e70c7e5426b2b  attalambda-0.2.0-macos-arm64.tar.gz
72f56f4d95665a3ca802160175c4082ce42b08054a35b963a10b0597b9d91fdc  attalambda-0.2.0-macos-x86_64.tar.gz
0ffcf7cd7218459efe1de1de87c7ff650328d01b16caa253deb6aa621188015a  attalambda-0.2.0-windows-x86_64.zip
```

The original `SHA256SUMS` remains exactly 410 bytes and intentionally retains
all four lines. Replacing it under the same filename would rewrite an existing
release asset. Its three withdrawn-platform entries are now documented as
historical integrity evidence, not availability or support claims.

The retained Linux archive is also unchanged. Its embedded
`GETTING_STARTED.md` therefore still contains the original four-target
release-note paragraph. The current README and GitHub Release page explicitly
supersede only that availability statement; its Linux verification and run
commands remain valid. Re-uploading any withdrawn asset requires a new
explicit decision.

The complete original publication and native-build evidence remains literal
in `docs/design/standalone-distribution.md`, `docs/ACCEPTANCE.md`, and
`PLAN.md`; it was not rewritten as though the other artifacts had never
existed.

## Retained Linux outsider proof

Kyle started a fresh Ubuntu 24.04 Docker userspace on x86-64, installed only
`curl` and CA certificates, and downloaded the public Linux archive and
manifest from GitHub. The archive had the exact expected `13,728,716` bytes,
the manifest had `410` bytes, and checksum verification printed:

```text
attalambda-0.2.0-linux-x86_64.tar.gz: OK
```

After extraction, the clean environment printed:

```text
Racket is not installed.
AttaLambda 0.2.0
Hello from AttaLambda.
```

This proves the current public Linux x86-64 workflow on fresh Ubuntu 24.04,
not other distributions, architectures, compatibility floors, or long-term
support.

## Repository change and verification boundary

Current changes affect only `README.md`, the future generated getting-started
guide, documentation assertions, `docs/ACCEPTANCE.md`, the standalone
distribution history, `PLAN.md`, and this handoff. No `core/`, `effects/`,
`runtime/`, reader, macro, expander, runner, builder, workflow, legal-notice,
version, or executable file changed.

The focused distribution suite passes 207 assertions. The complete suite
passes 4,755 assertions across all 32 test files, the unchanged expanded
purity proof over 16 `core/` modules, and the complete zero-finding
boundary/source inventory.

## Work remaining

- No Phase 30 work remains.
- Do not re-upload a withdrawn asset, replace the immutable manifest, sign or
  notarize an artifact, create a new version/tag/Release, or delete `v0.2.0`
  without new explicit authorization.
