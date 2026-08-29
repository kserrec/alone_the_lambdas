# Session handoff

Status recorded: 2026-08-29 after the verified public AttaLambda 0.2.0
publication and repository closeout.

This handoff becomes stale if `main`, tag `v0.2.0`, GitHub Release `v0.2.0`,
or any of its five manually uploaded assets changes.

## Exact stop point

- Final release source commit
  `42ff0a7810ebeced445ab23561433a2dc423e433` is pushed to public `main`. It
  sets root `VERSION` to exactly `0.2.0` and `info.rkt` to `0.2`; unchanged
  runner source derives `AttaLambda 0.2.0`.
- The only notice edit is the AttaLambda heading version. The resulting
  `distribution/THIRD_PARTY_NOTICES.md.in` is 100,024 bytes with SHA-256
  `516b3a08454709bf111494c92ed260a5c4afb47c91d06efca924b500c89e17ad`;
  every bundled legal term is unchanged. Root `LICENSE` remains 11,358 bytes
  with SHA-256
  `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`.
- [GitHub Actions run
  33262922610](https://github.com/kserrec/attalambda/actions/runs/33262922610)
  validated that exact commit. All 32 source tests, all four native builders,
  and all four independent no-Racket consumers passed. Every consumer passed
  the printed guide workflow, relocation, and final acceptance.
- Local Racket CS 9.3 verification passed 4,751 assertions, the unchanged
  expanded purity proof over 16 `core/` modules, and the complete zero-finding
  boundary/source inventory.
- The one approved transfer is finished. GitHub artifact IDs `9717803836`,
  `9717807355`, and `9717796683` were downloaded, verified, deleted through
  the API, and a follow-up run-artifact query returned `total_count: 0`.
  Ordinary `always()` cleanup is restored for future macOS and Windows
  transfer jobs; tag pushes remain excluded.
- Kyle separately approved the exact publication. The unsigned annotated tag
  `v0.2.0` has tag-object SHA
  `5537cf8b4dc1db31f8855e10118729ac78bc0dd0`, annotation
  `AttaLambda 0.2.0`, and peels to the exact release source commit above. The
  public tag API reports it as `unsigned` with no signature or payload.
- Public GitHub Release ID `379061612` is the latest non-prerelease Release,
  is titled `AttaLambda 0.2.0`, and is available at
  <https://github.com/kserrec/attalambda/releases/tag/v0.2.0>. It has exactly
  the four approved native archives and `SHA256SUMS` as manual assets, plus
  GitHub's automatic source-code ZIP and tarball links.
- The authenticated draft downloads and all five later anonymous public
  downloads matched local staging byte-for-byte. The public API, public HTML,
  and anonymous latest-release redirect were also verified. The anonymously
  downloaded Linux archive passed the full digest-pinned no-Racket Ubuntu
  24.04 consumer again.
- Publication used no identity-backed or detached signing, notarization,
  paid GitHub feature, purchase, or GitHub Actions run. No invalid-draft or
  failed-publication rollback was needed, and the tag was not deleted.

## Exact release files and public verification

The five exact publication inputs remain in
`/tmp/attalambda-phase29-release-1wXfDu/assets`:

```text
86f980d696b45b42c251b78e6a66b9cd875f649217bfb09731cf6b47c66b00ac  attalambda-0.2.0-linux-x86_64.tar.gz
5791ca3c28717972409d0d3503e135f685bcb7011ec24e6e4f9e70c7e5426b2b  attalambda-0.2.0-macos-arm64.tar.gz
72f56f4d95665a3ca802160175c4082ce42b08054a35b963a10b0597b9d91fdc  attalambda-0.2.0-macos-x86_64.tar.gz
0ffcf7cd7218459efe1de1de87c7ff650328d01b16caa253deb6aa621188015a  attalambda-0.2.0-windows-x86_64.zip
```

The combined `SHA256SUMS` is exactly 410 bytes, has SHA-256
`7786bf553caac0087ab22f3636d546a1fe00f89a446611c1516cc58f411f6f7f`,
and all four entries pass `sha256sum -c`. The five anonymous public downloads
are in `/tmp/attalambda-phase29-public-download-o8dXoA`; their names and sizes
are exact, every manifest entry passes, the manifest's own hash matches, and
all five files compare byte-for-byte with staging.

Linux stayed within one CI job. A second unchanged local build proved the
nonstandard `/tmp` Racket installation deterministic, then an isolated Ubuntu
24.04 rebuild with Racket's CI `/usr` layout reproduced the CI-tested Linux
archive byte-for-byte. Only `bin/attalambda` had differed between installation
layouts, by 29 bytes. The exact CI hash above passed the pinned no-Racket
consumer again locally. The disposable Docker containers and image used for
that reproduction were deleted; the staged archive remains.

## Demonstrated native systems

- Linux: digest-pinned Ubuntu 24.04 consumer; 10 regular files, two runtime
  files; observed only the recorded glibc, loader, zlib, and related system
  libraries.
- macOS arm64: macOS 15.7.7 arm64; nine regular files, one runtime file.
- macOS x86-64: macOS 15.7.9 x86-64; nine regular files, one runtime file.
- Windows x86-64: Microsoft Windows Server 2025 Datacenter 10.0.26100;
  nine regular files; Authenticode status `NotSigned`.

These are demonstrated systems, not minimum compatibility claims. No
identity-backed signing, detached signing, or notarization operation was
performed. The macOS arm64 toolchain output contains its automatic ad-hoc
linker signature (`CS_ADHOC`, flags `0x00020002`, one CodeDirectory and no CMS
identity-signature blob); the macOS x86-64 executable has no
`LC_CODE_SIGNATURE`. Windows explicitly reported Authenticode `NotSigned`. No
detached cryptographic signature accompanies any archive or the combined
checksum manifest.

## Behavior boundary

Phase 29 changed no `core/`, `effects/`, `runtime/`, reader, macro, expander,
or runner source. Object-language syntax, computation, representations,
effect order, error behavior, and the sole language-visible `host` authority
are unchanged. The intended executable-visible change is only version output;
the other changes are package/version metadata, release wording, manifests,
distribution tooling and tests, CI staging, and documentation.

## Work remaining

No Phase 29 work remains. Any later replacement asset, Release edit, signing
or notarization operation, new tag, or deletion of `v0.2.0` is new work and
requires its own authority. In particular, never delete `v0.2.0` without new
approval.

The pre-existing ignored Racket 8.10 `compiled/` directories encountered
during verification were moved intact—not deleted—to
`/tmp/attalambda-compiled-8.10-He5aY0`.
