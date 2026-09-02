# Session handoff

Status recorded: 2026-09-02, during pre-release preparation for AttaLambda
0.3.0 on branch `milestone-4-rationals`.

This handoff becomes stale when `milestone-4-rationals` merges to `main` or
a 0.3.0 tag/Release is created.

## Current state

- The public release remains **0.2.0** (Linux x86-64 only). Its complete
  publication and withdrawal history — tag and Release identity, asset
  hashes, the withdrawn macOS/Windows assets, and the outsider verification —
  is recorded durably in
  [docs/design/standalone-distribution.md](docs/design/standalone-distribution.md),
  [docs/ACCEPTANCE.md](docs/ACCEPTANCE.md), and [PLAN.md](PLAN.md). Do not
  re-upload a withdrawn asset, replace the immutable `SHA256SUMS`, or alter
  `v0.2.0` without new explicit authorization.
- **Milestone 4** (Rat as the sole public number type, plus Unit, Byte,
  Option, and Map) is complete and closed on `milestone-4-rationals`; every
  step in [PLAN.md](PLAN.md) is checked off with evidence, and version is
  `0.3.0-dev`.
- After the milestone closed, a full-branch adversarial review ran; all ten
  confirmed findings were fixed and independently cold-review-verified
  (see the pre-release addendum in [docs/ACCEPTANCE.md](docs/ACCEPTANCE.md)).
  In the same pass the error-kind space was renumbered collision-free
  (14/15/16 for the new kinds) and the expanded purity proof was extended to
  the effects layer.
- Current verification on the branch: `./run-all-tests.sh` passes all 38
  test files with 12,297 assertions, the expanded purity proof over all 29
  core and effects modules, and the zero-finding boundary inventory.

## Work remaining before 0.3.0

Kyle approved this sequence (Linux x86-64 remains the only binary target —
no Windows machine, no paid macOS signing):

1. Documentation currency pass and repository prune (in progress in the
   session recording this handoff).
2. Merge `milestone-4-rationals` to `main`.
3. Finalize version `0.3.0` in its five pinned locations (`VERSION`,
   `info.rkt`, the runner's accepted-version pattern, the boundary gate's
   version table, the build scripts).
4. Fresh Docker build of the Linux archive from the final commit, consumer
   acceptance on the new archive, new SHA-256 recorded.
5. Tag `v0.3.0` and publish the GitHub Release, Linux x86-64 only.

Merging, tagging, and publishing require Kyle's explicit go at each
irreversible step.
