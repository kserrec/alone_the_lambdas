# Session handoff

Status recorded: 2026-09-02, immediately after the AttaLambda 0.3.0 public
release.

This handoff becomes stale if `main`, tag `v0.3.0`, or the `v0.3.0` GitHub
Release changes.

## Exact current public state

- The released source is commit `1b51603671e87bcc524e2413491c94ad1ea7d763`
  on `main`, carrying root `VERSION` `0.3.0`, `info.rkt` version `0.3`, and
  runner output `AttaLambda 0.3.0`. The annotated tag `v0.3.0` peels to that
  commit.
- The public Release `AttaLambda 0.3.0` at
  <https://github.com/kserrec/attalambda/releases/tag/v0.3.0> carries two
  assets: `attalambda-0.3.0-linux-x86_64.tar.gz` (13,938,743 bytes, SHA-256
  `7adc7343720b0a1d6ed86af47059f031f571ab93649a314303c56d6b8a3d7870`) and its
  single-entry `SHA256SUMS` (103 bytes). Both URLs were re-downloaded fresh
  after publication and checksum-verified.
- Linux x86-64 is the sole supported binary target, per Kyle's standing
  decision (no Windows machine; no paid Apple signing). The 0.2.0 Release
  and its withdrawal history remain untouched; do not re-upload a withdrawn
  0.2.0 asset or alter `v0.2.0` without new explicit authorization.
- Verification at the release commit: 12,298 assertions across all 38 test
  files, the expanded purity proof over all 29 core and effects modules, the
  zero-finding boundary inventory, and an independent no-Racket Ubuntu 24.04
  consumer acceptance of the exact published archive
  (`consumer_acceptance=passed`, 362 ms first startup).

## Work remaining

- Nothing is in flight. The plan's release phase is complete; a future
  milestone needs a new plan before any code work starts.
- `VERSION` stays `0.3.0` on `main` until the next milestone begins (the
  0.2.0 precedent: the dev version arrives with the next milestone's
  branch).
