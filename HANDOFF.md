# Session handoff

Status recorded: 2026-08-28 after the post-Phase-27 security audit.

This handoff becomes stale when Phase 28 work begins, `PLAN.md` changes the
next approved phase, or `main` moves beyond the security-audit commit named
below.

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

Phase 28 ("Downloadable release candidate and novice documentation") is next
and is **entirely approval-gated**. Nothing else on the roadmap is unblocked
(Phase 29 is the public release and depends on Phase 28). Do not start Phase 28
without the two approvals below; existing permission does not authorize a
version change, release-candidate artifact, Git tag, GitHub Release, signing
operation, or binary publication.

Phase 28 needs two decisions only Kyle can make:

1. **Approve the exact bundled Racket runtime notices** — the final third-party
   legal notices for the bundled Racket CS 9.3 runtime that ship in every RC
   archive, replacing the current provisional `THIRD_PARTY_NOTICES`. They are
   produced from the Racket 9.3 toolchain's own license files in the 9.3
   CI/build environment (this dev machine has 8.10), so they are finalized as
   part of executing the phase. Approval reply, once seen:
   `Approve the exact bundled Racket runtime notices for Phase 28.`

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
   plus, for CI-built macOS/Windows RC archives:
   `Approve the temporary Phase 28 GitHub Actions artifact transfer and immediate deletion.`

Alternatively, Kyle may ask for the docs-only slice to be drafted first for
review before the version bump and artifact build.
