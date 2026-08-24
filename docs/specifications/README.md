# Specifications

These files are the canonical design inputs for Alone the Lambdas. They are
preserved verbatim from the project brief.

Read them in this precedence order:

1. [01-greenfield-core-language.md](01-greenfield-core-language.md) defines the
   base language and first milestone.
2. [02-type-tags-and-absolute-lambda-purity.md](02-type-tags-and-absolute-lambda-purity.md)
   strengthens the type-tag decision and object-language purity rules.
3. [03-canonical-public-naming-and-host-isolation.md](03-canonical-public-naming-and-host-isolation.md)
   overrides conflicting naming examples and isolates Racket-specific names
   from the public language.

Later documents override earlier documents only where they explicitly refine
or replace a decision.

## Provenance

| File | SHA-256 |
| --- | --- |
| `01-greenfield-core-language.md` | `6ca00dd7659cacf869242726b136db379e384c0bfe69786cea12329d7236b45b` |
| `02-type-tags-and-absolute-lambda-purity.md` | `50a18b3e7f8a40b9343ad6cb475b19d8431771d51f827d990219b27691fa419e` |
| `03-canonical-public-naming-and-host-isolation.md` | `2a179720d307eeee68f373b5cc56c6bc71a717765d73cd834639dd9b348cd0a1` |

If a specification copy changes intentionally, update its hash here in the
same commit and explain why.
