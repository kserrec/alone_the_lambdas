# Specifications

These files are the canonical design inputs for AttaLambda. Phase 27 updated
only the superseded project identity from the original brief. Step 31.1
(2026-09-01) appended an explicitly dated Milestone 4 Amendment to each file
for the exact-rational-numbers-and-foundational-values milestone; each
amendment states that it wins over the earlier sections of its own file, and
the pre-amendment text remains the literal historical contract for the
completed milestones.

Read them in this precedence order:

1. [01-greenfield-core-language.md](01-greenfield-core-language.md) defines the
   base language and first milestone, and its Milestone 4 Amendment defines
   the final public type set, Rat, Unit, Byte, Option, and Map contracts.
2. [02-type-tags-and-absolute-lambda-purity.md](02-type-tags-and-absolute-lambda-purity.md)
   strengthens the type-tag decision and object-language purity rules, and
   its Milestone 4 Amendment fixes the amended tag table and extends the
   absolute purity rule to the new types.
3. [03-canonical-public-naming-and-host-isolation.md](03-canonical-public-naming-and-host-isolation.md)
   overrides conflicting naming examples and isolates Racket-specific names
   from the public language; its Milestone 4 Amendment fixes the exact new
   and retired public spellings.

Later documents override earlier documents only where they explicitly refine
or replace a decision. Within each document, its Milestone 4 Amendment
overrides that document's earlier sections wherever they conflict.

## Provenance

| File | SHA-256 |
| --- | --- |
| `01-greenfield-core-language.md` | `d4bdd84bb85f8ac0edba2bb993c5bdfb8efeeb33642f423ef3cfd1b66c6a5d20` |
| `02-type-tags-and-absolute-lambda-purity.md` | `34b7caf70674979421c794460a8b33d89bc16fe93f8da7c78632cd21814381f7` |
| `03-canonical-public-naming-and-host-isolation.md` | `d9830bfc16612ba88c1ab485720ea65ecafdb4c5c851f140be95452e2aaaf29d` |

If a specification copy changes intentionally, update its hash here in the
same commit and explain why.

Hash history: the pre-amendment copies preserved verbatim since Phase 0
(identity wording updated in Phase 27) had SHA-256
`6ca00dd7659cacf869242726b136db379e384c0bfe69786cea12329d7236b45b`,
`50a18b3e7f8a40b9343ad6cb475b19d8431771d51f827d990219b27691fa419e`, and
`2a179720d307eeee68f373b5cc56c6bc71a717765d73cd834639dd9b348cd0a1`
respectively. The 2026-09-01 change appended the three Milestone 4
Amendments authorized by the approved Milestone 4 plan (Step 31.1) and
changed nothing above the amendment markers.
