# Session handoff

Active work is the approved non-core simplification on branch
`refactor/non-core-simplification`, based on
`578f1acc00566c17c18786a393cfa0b496c531ba`. Kyle authorized unattended
execution on 2026-09-05. [`PLAN.md`](PLAN.md) is the exact remaining procedure;
[`docs/design/non-core-refactor.md`](docs/design/non-core-refactor.md) defines
the preserved behavior and reduction goal.

Phases 1 through 3 are committed and pushed:

- `1f08b78` — simplify the codec and native host dispatch;
- `2ee5205` — simplify runner call sites, readers, and shared test helpers;
- `b0081ab` — reduce redundant checker/test locks and historical documentation.

Phase 3 passed 12,297 assertions, the 29-module purity proof, and the complete
boundary inventory before its commit. Phase 4's independent review found no
production correctness or authority regression and identified four bounded
test/documentation repairs now in progress. After independent review of those
repairs, the remaining work is final Racket CS 9.3 Linux build/consumer
acceptance, comparison with the recorded baseline, a clean commit and push,
and a permanent stop. Do not open a pull request, merge, release, tag, or start
later work without Kyle's separate explicit request.

The current public release remains AttaLambda 0.3.0 at commit `1b51603` and tag
`v0.3.0`. Linux x86-64 is the sole supported binary target. Exact release and
withdrawal evidence is in the
[standalone-distribution ledger](docs/design/standalone-distribution.md).

Two post-release CI-only fixes on `main` do not affect published bytes:
`a1a81bc` accepts 0.3.x version forms in the Windows harness, and `cb3e226`
raises the suite workflow cap to 20 minutes. Main-tip run
[33674071955](https://github.com/kserrec/attalambda/actions/runs/33674071955)
was fully green.
