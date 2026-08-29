# Session handoff

Status recorded: 2026-08-29 after correcting the Phase 28 approval sequence.

This handoff becomes stale when the Phase 28 notice-inventory preparation
begins, `PLAN.md` changes the next approved phase, or executable work moves
beyond the security-audit commit named below.

## Exact stop point

- Phase 27 and the post-Phase-27 maintenance are complete. A full
  ship-readiness **security audit is also complete** and its one confirmed
  finding is fixed, committed, and pushed.
- Security audit result: one confirmed finding (F1) — the pure-lambda HTTP
  server buffered a connection's bytes with no size limit, so a hostile peer
  streaming bytes that never complete a request header (and never closing)
  could exhaust process memory and force quadratic re-parsing. Fixed by capping
  the accumulated request at 8192 bytes and checking size before each parse in
  `effects/http-server.rkt`; regression tests added in
  `tests/http-server-test.rkt`. Everything else audited (runner, host boundary,
  codec, lang/macros/readers, HTTP protocol, tooling/distribution, CI, repo
  hygiene, and the purity/boundary gates themselves) was examined and cleared.
- One residual is **deliberately deferred** with a named reason and recorded in
  `PLAN.md` under "Post-Phase 27 security audit": within the 8192-byte cap the
  whole buffer is still re-parsed after every partial read, so a peer dribbling
  tiny chunks pays O(cap^2) interpreter work on its one connection before
  rejection. Memory and termination are now bounded and this grants no
  capability beyond the deliberately blocking single-connection server's
  already-documented "one client can tie it up" property. Fully closing it needs
  an incremental HTTP parser (a redesign of the read/parse loop), which is
  beyond a spot fix and beyond this minimal server's contract.
- The project is still version `0.2.0-dev` (`info.rkt` projection `0.1.900`)
  with no Git tag, GitHub Release, release-candidate file, signature, binary
  release, or public download.
- Final local verification passed all 32 test files, the 16-module expanded
  purity scan, and the complete boundary/source-inventory gate. The audit fix
  received a fresh-agent cold review with no findings.
- The audit fix is commit
  `be1fd1a` ("fix: bound HTTP request buffering against hostile peers") on
  `main`, pushed to the verified `origin` destination
  `git@github.com:kserrec/attalambda.git`. The tree is clean.

## Next work and pending rulings

Phase 28 ("Downloadable release candidate and novice documentation") is next.
Its implementation is approval-gated, but the exact runtime notices cannot be
approved before they exist and Kyle has seen them. The current
`distribution/THIRD_PARTY_NOTICES.md.in` is explicitly provisional and is not
the legal text to approve.

The next unblocked action is a narrow preparation pass: inspect the pinned
Racket CS 9.3 toolchain, assemble the complete proposed notice text in
disposable review material, and present the exact terms to Kyle. That pass may
not modify the repository, change `VERSION`, build or stage a release-candidate
archive, transfer an artifact through GitHub Actions, create a tag or GitHub
Release, upload a file, sign anything, or publish anything.

Only after the exact notice text has been presented does Phase 28 need the
three decisions only Kyle can make, in this order:

1. **Approve the exact bundled Racket runtime notices shown for review.** Ask
   only after presenting their complete terms. Approval reply:
   `Approve the exact bundled Racket CS 9.3 runtime notices presented for Phase 28.`

2. **Approve the Phase 28 implementation scope** — authorizes, in one pass:
   restructuring the getting-started docs so the primary path is
   download → extract → run `attalambda hello.attl` (not "install Racket"), and
   documenting `.attl` syntax, the `#lang attalambda` line, exit statuses,
   `SHA256SUMS` verification, and the unsandboxed stdout/filesystem/network
   authority; promoting `VERSION` `0.2.0-dev` → `0.2.0-rc.1` (and `info.rkt`
   `0.1.900` → `0.1.901`); and building/staging the four **unpublished** RC
   archives (linux-x86_64, macos-x86_64, macos-arm64, windows-x86_64) with the
   license, approved notices, one `SHA256SUMS`, build manifest, and known
   limitations. This is not a public release — nothing is tagged, uploaded, or
   downloadable; Phase 29 remains the publication gate. Building the
   macOS/Windows RC archives in CI crosses the temporary artifact-transfer
   boundary and needs its own one-line approval (as in Phases 25–27); the Linux
   archive can be built locally without a transfer. Approval reply:
   `Approve the Phase 28 implementation scope (docs restructure, VERSION → 0.2.0-rc.1, build/stage the four unpublished RC archives). This does not authorize a tag, GitHub Release, upload, or public download.`

3. **Approve the CI transfer needed to build and independently test the two
   macOS archives and the Windows archive.** This temporarily uploads those
   three unpublished archives, their checksums, and the consumer harnesses
   through the `kserrec/attalambda` GitHub Actions account. Retention is one
   day only as a cleanup-failure fallback, and the cleanup job deletes them
   immediately after testing. Approval reply:
   `Approve the temporary Phase 28 GitHub Actions transfer of the two unpublished macOS RC archives and one unpublished Windows RC archive, their checksums, and their consumer harnesses, with one-day fallback retention and immediate deletion after testing.`

Phase 29 remains blocked on Phase 28. None of these approvals authorizes a Git
tag, GitHub Release, signature, public download, or publication.
