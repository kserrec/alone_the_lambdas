# Session handoff

Status recorded: 2026-08-29 during Phase 29 final-but-unpublished release
preparation.

This handoff becomes stale when the exact release-preparation commit finishes
GitHub Actions validation, any native artifact is downloaded or deleted, the
ordinary workflow cleanup contract is restored, or publication is approved.

## Exact stop point

- Kyle separately approved the exact Phase 29 implementation scope and the
  one-time temporary transfer of two macOS and one Windows final-but-
  unpublished archives, their one-entry checksums, and their self-contained
  consumers. The literal approvals are recorded in
  `docs/design/standalone-distribution.md`.
- Root `VERSION` is exactly `0.2.0`; `info.rkt` projects it to `0.2`. Runner
  source is unchanged, so its sole intended
  executable-visible change is `AttaLambda 0.2.0` from the existing version
  derivation.
- `distribution/THIRD_PARTY_NOTICES.md.in` changes only its AttaLambda version
  heading. The exact final file is 100,024 bytes with SHA-256
  `516b3a08454709bf111494c92ed260a5c4afb47c91d06efca924b500c89e17ad`;
  every bundled legal term is unchanged. Root `LICENSE` remains 11,358 bytes
  with SHA-256
  `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`.
- The final archive names are `attalambda-0.2.0-linux-x86_64.tar.gz`,
  `attalambda-0.2.0-macos-x86_64.tar.gz`,
  `attalambda-0.2.0-macos-arm64.tar.gz`, and
  `attalambda-0.2.0-windows-x86_64.zip`, accompanied by one combined
  `SHA256SUMS`.
- No tag, GitHub Release, signing operation, release-asset upload, public
  download, publication, purchase, or paid GitHub usage is authorized.
- Local Racket CS 9.3 verification passed 4,751 assertions across all 32 test
  files, the unchanged expanded purity proof over 16 `core/` modules, and the
  complete zero-finding repository boundary and source inventory.

## Approved one-time staging boundary

- Linux build and no-Racket consumption remain within one job. The exact Linux
  release archive will be reproduced from the tested commit in isolated local
  staging.
- Only the two macOS archives and one Windows archive, each with its one-entry
  checksum and consumer harness, may cross GitHub Actions jobs.
- After all consumers pass, Codex must download and verify the exact tested
  bytes locally, then delete the three exact GitHub artifact identifiers and
  verify none remain. One-day retention is only the automatic fallback.
- Tag pushes are excluded so later publication cannot repeat the transfer.
  After local staging, ordinary immediate cleanup must be restored on `main`
  before publication.

## Behavior boundary

- No `core/`, `effects/`, `runtime/`, reader, macro, expander, or runner source
  changes in Phase 29 preparation.
- Object-language syntax, computation, representations, effect order, error
  behavior, and the sole language-visible `host` authority remain unchanged.
- Package/version metadata, archive and guide wording, build manifests,
  distribution tests and tooling, CI staging, and current documentation are
  the only intended changed classes.

## Work remaining before publication can be proposed

1. Commit and push the exact locally verified final-but-unpublished source
   commit to public `main`.
2. Require the complete source suite, expanded 16-module purity proof,
   repository boundary inventory, all four native builds, and all four clean
   no-Racket consumers to pass for that exact commit.
3. Download and verify the three approved temporary native artifacts, build
   the Linux archive from the same commit, assemble one four-entry checksum
   manifest, and delete the GitHub artifacts.
4. Restore ordinary automatic cleanup, persist the exact evidence, and leave
   `main` clean and synchronized.
5. Present the literal tag, Release title, five asset names, exact checksums,
   observed platforms, signing state, warnings, account use, cost, and public
   consequence. Only a new exact approval may authorize publication.
