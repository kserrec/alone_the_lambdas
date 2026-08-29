# Session handoff

Status recorded: 2026-08-29 after Phase 28 completion.

This handoff becomes stale when Phase 29 begins, `PLAN.md` changes the next
phase, or a later candidate-validation commit supersedes the evidence below.

## Exact stop point

- Phase 28 (downloadable release candidate and novice documentation) is
  complete. `PLAN.md` marks every Phase 28 item done; Phase 29 is next and
  approval-gated.
- Root `VERSION` is exactly `0.2.0-rc.1`; `info.rkt` carries the approved
  package projection `0.1.901`. The CLI intentionally reports
  `AttaLambda 0.2.0-rc.1`.
- The repository and every candidate package the approved Apache License 2.0
  bytes with SHA-256
  `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`.
- Every candidate packages the exact approved 100,029-byte bundled Racket CS
  9.3 notice payload with SHA-256
  `1343f218ba484a79fbef498d4e8fb02e202763a19e46c5e610a8bfe900bcbefd`.
  Builders pin that digest; clean consumers hash the extracted bytes.
- Candidate source commit
  `91ba3a9a8d57f0f19f4e8620317a85cb781148df` passed 4,745 assertions
  across all 32 test files, the unchanged 16-module purity proof, the complete
  boundary inventory, all four native builders, and all four independent
  no-Racket consumers in GitHub Actions run 33258685537:
  <https://github.com/kserrec/attalambda/actions/runs/33258685537>
- Every consumer executed the novice checksum, extraction, directory-entry,
  version, hello, and custom-program workflow and reported
  `guide_workflow=passed`, relocation success, and final acceptance.
- Linux stayed within one CI job. Only the separately approved two macOS and
  one Windows candidates, their one-entry checksums, and their harnesses
  crossed workflow jobs. The Windows and macOS cleanup jobs passed, and the
  completed run's artifact API reported `total_count: 0`.
- The exact four hashes, byte counts, runtime/dependency inventories, platform
  versions, Authenticode state, and timings are durable in
  `docs/design/standalone-distribution.md` and summarized in
  `docs/ACCEPTANCE.md`.
- Phase 28 created no Git tag, GitHub Release, signature, public download, or
  publication. It changed no object-language computation or host authority;
  the intended executable-visible change is the product-version output.

## Disposable local evidence

- One clean independently rebuilt Linux candidate remains at
  `/tmp/attalambda-phase28-final-Bu2CGu/attalambda-0.2.0-rc.1-linux-x86_64.tar.gz`
  with its matching sibling `SHA256SUMS`. Its SHA-256 is
  `5ecb95dd9465b5d6fb046796de6f2dea6990e20cee5931f1491c99bb0628d1fc`;
  its pinned no-Racket Ubuntu consumer passed.
- The exact same-run four-target CI checksum record remains at
  `/tmp/attalambda-phase28-ci-91ba3a9/SHA256SUMS`; that file's SHA-256 is
  `e4d036ef50b8a309ffbdc2120cc50fa0b306b81f0a20229cb0a54c1fe16764e8`.
- These `/tmp` files are convenience staging evidence only and may disappear
  on reboot. The repository docs contain all durable measurements. The three
  native CI archives were intentionally deleted and cannot be recovered from
  the completed workflow.

## Repository state

- Phase 28 implementation was committed as `9058889`; the Windows guide
  placeholder regression fix as `3256f33`; and literal guide-workflow consumer
  coverage as `91ba3a9`.
- The final documentation commit follows those candidate-source commits with
  `[skip ci]`, so it does not rebuild or transfer another candidate after the
  authoritative run. `main` and the verified `origin`
  `git@github.com:kserrec/attalambda.git` should be clean and synchronized.
- No generated Racket artifacts or release archives belong in Git.

## Next work and authority boundary

Phase 29 (first independent release) is the next plan item. The Phase 28
approvals do not authorize Phase 29 version changes, artifact transfer,
signing, a tag, a GitHub Release, an upload, a public download, or publication.

Before Phase 29 implementation, establish and present the verified starting
state and the exact proposed changes: `VERSION` `0.2.0-rc.1` to `0.2.0`, the
`info.rkt` projection, final archive names/docs, four native builds, and any
temporary macOS/Windows transfer. State separately what new files would be
created and that object-language computation and host authority stay
unchanged. Obtain explicit scope and temporary-transfer authorization rather
than carrying Phase 28 permission forward.

After an exact final commit and all four consumers pass, present the literal
tag, GitHub Release title, four filenames, one checksum manifest, platform
claims, unsigned/signing state, known limitations, and public consequences.
Only Kyle's explicit approval of that exact proposal may authorize the tag,
GitHub Release, artifact upload, or public download.
