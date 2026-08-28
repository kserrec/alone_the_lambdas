# AttaLambda — Greenfield Core Language Specification

## 1. Project

Create a completely new repository and project:

```text
attalambda
```

Human-facing name:

**AttaLambda**

This is not a refactor or compatibility rewrite of `all_the_lambdas`.

Treat the old project only as:

- a source of ideas;
- a source of algorithms that may be reimplemented;
- evidence about what worked and what became awkward.

Do **not** preserve an old representation merely because old code depends on it.

The purpose of this project is to build the cleanest version we now know how to build.

---

# 2. Long-term objective

AttaLambda should eventually become a small but genuine general-purpose programming language whose computational world is built as faithfully as practical from **pure untyped lambda calculus**.

The intended eventual architecture is:

```text
AttaLambda program
          ↓
strong runtime-typed lambda values
          ↓
pure untyped lambda-calculus encodings
          ↓
one eventual host boundary
          ↓
operating system
```

The first version covered by this specification stops **before `host`**.

This specification builds the foundation necessary for `host` to be added cleanly afterward.

---

# 3. Core design decisions

These decisions are settled for this project.

## Numbers

Normal language numbers use:

> **binary digit lists**

Do not use Church numerals as the practical representation of ordinary numeric values.

Binary representation is chosen because representation size grows with bit width rather than numeric magnitude.

Canonical naturals must be normalized.

Example conceptually:

```text
0 = [0]
1 = [1]
2 = [1,0]
3 = [1,1]
4 = [1,0,0]
5 = [1,0,1]
```

Use one consistent digit order. Prefer most-significant bit first unless a concrete implementation reason strongly favors otherwise.

---

## Type tags

Runtime type tags use:

> **Church numerals**

Church numerals are excellent here because type tags are tiny fixed discriminants.

They are **not** the public numeric representation.

This distinction must remain explicit:

```text
Church numerals
    → small internal tags/discriminants

binary digit lists
    → actual numeric values
```

---

## Lists

Lists follow **Greg Michaelson's general typed-list approach** from *An Introduction to Functional Programming Through Lambda Calculus* rather than the old project's convention of:

```text
pair ... pair ... false
```

Do not make raw `false`, Church zero, and the empty list the same value.

A list is an explicitly list-tagged object.

The tail of every non-empty list must itself be a list object.

The empty list must be an explicit list object with a distinguished internal empty representation.

Use the Michaelson model as the reference architecture, while adapting details where necessary to fit this project's improved Error system.

---

## Runtime typing

The canonical programming layer is:

> **strict strong runtime typing implemented entirely with lambda encodings**

The underlying calculus remains untyped.

Values carry runtime tags.

Functions validate tags.

Invalid use returns lambda-encoded Error values.

No static type checker is required.

---

## Function type checking

Do **not** implement:

```text
type-check1
type-check2
type-check3
type-check4
...
```

Implement one arbitrary-arity type wrapper.

Its arity comes from a lambda list of expected argument types.

Arguments arrive naturally one at a time through currying.

---

## Errors

Errors are ordinary lambda-encoded values.

They:

- propagate automatically through typed function boundaries;
- preserve the original cause;
- accumulate structured context as they propagate;
- do not rely on Racket exceptions for language-level failures;
- do not flatten their history into a host string.

---

## Result

Use `Result` for expected computational failure.

Keep this semantic distinction:

```text
Error
    programmer/runtime-contract failure

Result Err
    legitimate computation that failed
```

Examples:

```text
ADD String Nat
    → Error

DIV Nat zero
    → Result Err(DIVIDE_BY_ZERO)
```

Later:

```text
READ-FILE valid-path-that-does-not-exist
    → Result Err(FILE_NOT_FOUND)
```

---

## Strings

Strings are genuine lambda-built values.

A String is built from:

```text
Char values
    ↓
Michaelson-style List
    ↓
String runtime tag
```

Characters use binary values from 0–255.

---

## Host

Do **not** implement `host` yet.

After this specification is complete, the next project phase will add exactly one privileged external boundary:

```text
(host request)
```

Everything in this specification should be designed so that adding that boundary later is straightforward.

---

# 4. Purity rule

Production object-language computation must use only lambda-calculus machinery.

Allowed computational primitives are fundamentally:

```text
variables
lambda abstraction
function application
```

Readable macros may mechanically lower into those constructs.

Racket may be used only for:

- module hosting;
- Lazy Racket evaluation;
- macro implementation;
- tests;
- human-facing readers;
- tooling.

A reader may inspect a completed lambda value and render it.

A reader may **never** determine an object-language result.

---

# 5. Suggested repository structure

Prefer a clear dependency-oriented structure such as:

```text
attalambda/
├── README.md
├── ARCHITECTURE.md
├── ROADMAP.md
├── macros/
│   ├── lazy-with-macros.rkt
│   └── macros.rkt
├── core/
│   ├── pair.rkt
│   ├── logic.rkt
│   ├── tags.rkt
│   ├── objects.rkt
│   ├── lists.rkt
│   ├── binary-nat.rkt
│   ├── errors.rkt
│   ├── typecheck.rkt
│   ├── typed-logic.rkt
│   ├── result.rkt
│   ├── chars.rkt
│   └── strings.rkt
├── readers/
├── tests/
└── run-all-tests.sh
```

Exact paths may change if a cleaner dependency graph emerges.

Do not create unnecessary abstraction layers.

---

# 6. Macro layer

Provide only mechanical sugar.

At minimum:

```text
def
_let
_if
```

`def` should convert:

```text
(def foo x y = body)
```

to nested unary lambdas.

Conceptually:

```text
define foo =
    λx.λy.body
```

`_let` should mechanically lower to immediate lambda application.

`_if` is the **raw Boolean** conditional and lowers to Boolean selection.

The eventual strict public conditional will be:

```text
IF
```

and is defined later in this specification.

Do not add language features through macros that change the computational model.

---

# 7. Phase 1 — raw foundational calculus

Implement:

```text
pair
first
second
true
false
_not
_and
_or
xor
```

All must be pure lambda terms.

Readers for testing may exist separately.

Do not introduce typed objects yet beyond what is needed to bootstrap the next phase.

Acceptance:

- Boolean truth tables pass.
- Pair selection works.
- No host conditional determines Boolean results.

---

# 8. Phase 2 — Church numeral tags only

Implement enough Church numeral machinery to construct small tags:

```text
church-zero
church-succ
church-one
church-two
...
```

Do not build a large Church arithmetic library.

These numerals exist primarily for discriminants.

Create the initial canonical type-tag table:

```text
0  ERROR
1  BOOL
2  LIST
3  NAT
4  RESULT
5  CHAR
6  STRING
```

Names may be:

```text
error-type
bool-type
list-type
nat-type
result-type
char-type
string-type
```

Future types may continue upward.

Add pure Church equality sufficient for comparing tags.

---

# 9. Phase 3 — generic typed-object representation

Use the standard lambda object shape:

```text
object = {type-tag, value}
```

Implement pure:

```text
make-obj
type
val
is-type
```

`make-obj` constructs the lambda pair.

`type` retrieves its tag.

`val` retrieves its payload.

`is-type expected obj` compares Church tags.

Important architectural rule:

The strict typed layer is a **closed convention**.

Its functions assume arguments are canonical AttaLambda typed values or Error values.

Do not attempt to build a magical validator capable of safely classifying every arbitrary untyped lambda term.

Raw lambda values are internal implementation values.

---

# 10. Phase 4 — Michaelson-style lists

This is foundational and should be designed carefully before numeric code.

## Representation

A non-empty list is conceptually:

```text
{
    LIST-TYPE,
    {
        head,
        tail-list
    }
}
```

where `tail-list` must itself be a valid list object.

Do not terminate lists with raw `false`.

Do not identify NIL with Boolean false or any numeric zero.

---

## NIL

Create one canonical empty list object:

```text
NIL
```

Follow Michaelson's explicit typed-empty-list strategy.

Its payload should use distinguished Error/sentinel values so that it remains a genuine LIST object while still being recognizably empty.

The invariant must ensure that the representation used to identify NIL cannot occur as the tail of a legitimate non-empty cell.

A valid simple model is:

```text
NIL =
{
    LIST-TYPE,
    {
        LIST-EMPTY-SENTINEL,
        LIST-EMPTY-SENTINEL
    }
}
```

where `LIST-EMPTY-SENTINEL` is an Error-like value reserved for this structural role.

The exact internal encoding may follow Michaelson more literally if that proves cleaner.

---

## Core list operations

Implement:

```text
CONS
HEAD
TAIL
IS-NIL
```

Semantics:

### `CONS x xs`

- `xs` must be a LIST.
- valid tail → construct new LIST.
- invalid tail → Error.

### `HEAD xs`

- non-list → Error.
- NIL → empty-list Error.
- non-empty → return stored head.

### `TAIL xs`

- non-list → Error.
- NIL → empty-list Error.
- non-empty → return stored tail LIST.

### `IS-NIL xs`

- non-list → Error.
- NIL → typed TRUE eventually / raw Boolean during bootstrap.
- otherwise → FALSE.

`IS-NIL` must be O(1).

---

## Additional foundational list functions

Once the four primitives are correct, implement:

```text
LEN
APPEND
REVERSE
MAP
FILTER
FOLD
TAKE
DROP
```

Use Y/fixed-point recursion where needed.

Do not implement unnecessary algorithms yet.

---

# 11. Bootstrap allowance

Some early typed operations will necessarily perform their checks manually because the generalized typed-function wrapper does not exist yet.

This is allowed temporarily for:

- core List constructors;
- binary Nat bootstrap;
- Error bootstrap.

Once the generic checker exists, migrate ordinary public typed operations onto it where appropriate.

Do not preserve duplicated ad hoc checking merely because it was used during bootstrapping.

---

# 12. Phase 5 — binary natural numbers

Build the canonical practical numeric type.

## Representation

A typed natural is:

```text
{
    NAT-TYPE,
    binary-digit-list
}
```

The payload is a lambda-built list representation.

Digits should be the simplest pure lambda values practical for the implementation.

Prefer raw lambda Booleans as bits:

```text
false = 0
true  = 1
```

unless testing demonstrates that another raw 0/1 representation is materially cleaner.

Do not tag every individual bit unless that provides a concrete benefit.

The Nat wrapper supplies the runtime type.

---

## Canonical form

Require:

```text
zero = [0]
```

All non-zero values:

- begin with `1`;
- contain no unnecessary leading zeroes.

Never allow an empty bit-list to escape as a Nat.

---

## Required raw binary operations

Implement pure algorithms for:

```text
normalize
is-zero
succ
add
sub
mult
eq
lt
lte
gt
gte
```

`sub` may saturate at zero for naturals.

Add division/modulo later in this phase if straightforward; otherwise it may be Phase 6.

Do not optimize through host arithmetic.

Readers may convert the completed binary encoding into a Racket integer solely for tests/output.

---

## Initial constants

Define at least:

```text
ZERO
ONE
TWO
THREE
...
```

as typed binary Nat values.

A small useful range is sufficient.

Do not add numeric literal syntax.

---

# 13. Phase 6 — structured Error system

Replace the old project's string-oriented error idea with a structured lambda representation from the start.

## Error type

Every Error is:

```text
{
    ERROR-TYPE,
    error-payload
}
```

The payload must preserve:

1. the root failure;
2. propagation context.

Do not replace the root cause as an error moves upward.

---

## Error kinds

Use small Church numeral discriminants for error kinds.

At minimum:

```text
TYPE-MISMATCH
EMPTY-LIST
INVALID-NAT
DIVIDE-BY-ZERO
```

Add others only as required.

These are not public numbers.

They are tiny internal tags.

---

## Error frames

Represent propagation frames structurally as lambda data.

A frame should contain at least:

```text
argument-position
expected-type
```

For a root type mismatch also preserve:

```text
actual-type
```

Conceptually:

```text
Error {
    root:
        TypeMismatch {
            expected,
            actual,
            argument
        }

    frames:
        [
            { argument, expected },
            ...
        ]
}
```

The exact nested-pair representation is an implementation detail.

Use the project's List representation for the frame list.

---

## Bubbling rule

When an Error is supplied to another typed function:

- do not execute the underlying function;
- do not discard the existing Error;
- add a new frame describing the current function boundary;
- propagate the resulting Error.

Do not flatten the history into a string.

---

## Function names

Strings do not exist yet.

Therefore early error frames do not need textual function names.

They may initially contain:

```text
argument-position
expected-type
```

After String exists, extend frames to include:

```text
function-name : STRING
```

and update readers accordingly.

Do not introduce host strings into Error merely to solve this early.

---

# 14. Phase 7 — generalized arbitrary-arity typed functions

This replaces all arity-specific checking.

There must never be:

```text
type-check2
type-check3
type-check4
...
```

in the final architecture.

---

## Signature representation

Represent expected argument types as an AttaLambda LIST:

```text
[NAT-TYPE, NAT-TYPE]
```

or:

```text
[STRING-TYPE, NAT-TYPE, BOOL-TYPE, CHAR-TYPE]
```

The list itself defines the function's arity.

---

## Core mechanism

Create one generic constructor conceptually like:

```text
make-typed-function
    raw-function
    expected-types
    return-type
```

It processes arguments one at a time.

For each expected type, it returns one lambda awaiting one argument.

Example:

```text
expected = [Nat, Nat]

make-typed-function add expected Nat
```

behaves like:

```text
λarg1.
    check arg1
    λarg2.
        check arg2
        wrap result as Nat
```

No explicit arity number is needed.

---

# 15. Progressive application

When a valid argument arrives:

1. inspect expected type = HEAD(expected-types);
2. verify argument tag;
3. unwrap argument using `val`;
4. partially apply the raw function to that raw value;
5. recurse with:
   - partially applied raw function;
   - TAIL(expected-types);
   - next argument position.

Example:

```text
raw = add
types = [Nat, Nat]

receive TWO
    → validate
    → raw becomes (add two)
    → types becomes [Nat]

receive THREE
    → validate
    → raw becomes ((add two) three)
    → types becomes []

types empty
    → wrap raw result as Nat
```

---

# 16. Critical requirement — preserve remaining arity after an error

This is mandatory.

A naïve progressive checker has a serious problem.

Given:

```text
((ADD WRONG-VALUE) TWO)
```

if the first application immediately returns an Error object, the second application tries to invoke that Error as a function.

Do not do that.

When a failure occurs before all arguments have arrived:

1. create/bubble the Error immediately;
2. calculate how many expected arguments remain;
3. return one ignoring lambda for each remaining argument;
4. only after the final expected argument has been supplied return the Error.

Conceptually, for a two-argument function:

```text
ADD wrong
    → λignored. ERROR
```

therefore:

```text
((ADD wrong) TWO)
    → ERROR
```

For a five-argument function failing on argument two:

```text
((F a) bad)
    → λ_.λ_.λ_.ERROR
```

This preserves ordinary curried calling syntax and deterministic error behavior.

Implement this using the remaining expected-type list.

No host arity counting.

---

# 17. Error propagation during generic checking

At each argument:

### Argument is valid expected type

Continue partial application.

### Argument is another canonical typed value of the wrong type

Create a new root `TYPE-MISMATCH` Error.

Preserve:

```text
expected type
actual type
argument position
```

Then return an error-absorbing lambda chain for remaining arguments.

### Argument is already an Error

Do not replace it.

Append/prepend the current propagation frame.

Then return the same remaining-arity absorber chain.

---

# 18. Return handling

Support both categories of raw implementation:

## Raw-result function

Example:

```text
raw-add : bits -> bits -> bits
```

The generic typed wrapper should automatically package the final raw result:

```text
{NAT-TYPE, result}
```

## Already-typed-result function

Some operations may naturally return an already-tagged object such as:

```text
Result
Error
a polymorphic existing value
```

Do not create separate arity-specific systems for this.

Provide one small generic mechanism for selecting the finalization policy, such as:

```text
wrap-return
keep-return
```

or a finalizer function argument.

Keep this simple.

---

# 19. Phase 8 — canonical typed Boolean layer

Define:

```text
TRUE  = {BOOL-TYPE, true}
FALSE = {BOOL-TYPE, false}
```

Build strict typed operations:

```text
NOT
AND
OR
XOR
```

using the generalized function checker where possible.

Wrong types return/bubble Error.

---

# 20. Typed `IF`

Add a canonical strict conditional:

```text
IF
```

This is distinct from internal raw `_if`.

Contract conceptually:

```text
IF : BOOL -> A -> A -> A
```

Behavior:

1. condition Error → bubble Error;
2. condition not BOOL → type Error;
3. condition BOOL → unwrap raw Boolean selector;
4. select one branch;
5. do not evaluate the unselected branch.

Do not require the branches to have a hard-coded type.

Preserve laziness.

`IF` is allowed to use custom logic rather than the generic monomorphic function wrapper because its return is intentionally polymorphic.

The eventual public programming layer should prefer:

```text
IF
```

while internal raw code may use:

```text
_if
```

---

# 21. Phase 9 — migrate binary Nat operations to generic typing

Now replace bootstrap/manual typed wrappers for ordinary Nat operations.

Public Nat API should include at least:

```text
SUCC
ADD
SUB
MULT
EQ
LT
LTE
GT
GTE
IS-ZERO
```

All should:

- accept canonical typed Nat values;
- use the generalized checker;
- bubble Error correctly;
- return typed values.

Example:

```text
((ADD TWO) THREE)
    → typed Nat 5
```

Wrong type:

```text
((ADD TRUE) THREE)
    → structured Error
```

No arity-specific checking code.

---

# 22. Phase 10 — Result

Add:

```text
RESULT-TYPE
```

Representation:

```text
Result =
{
    RESULT-TYPE,
    {
        success-bool,
        payload
    }
}
```

where:

```text
success-bool = true
    → Ok

success-bool = false
    → Err
```

Implement:

```text
make-ok
make-err
is-ok
is-err
unwrap-ok
unwrap-err
```

`make-err` must accept an Error payload.

---

# 23. Error versus Result rule

Document this explicitly in code and architecture docs.

## Error

Use for:

- wrong runtime type;
- violated function contract;
- malformed internal value;
- using `HEAD` on NIL;
- similar programming/runtime contract errors.

These automatically propagate through typed function boundaries.

## Result Err

Use when failure is an expected part of a valid computation.

Examples:

```text
division by zero
future file not found
future socket bind failure
```

A function receiving valid argument types may return:

```text
Ok(value)
```

or:

```text
Err(error)
```

Do not automatically unwrap or propagate the Error inside a Result.

`Result` is an ordinary valid typed value.

---

# 24. Add safe division

Once Result exists, add binary Nat division if not already implemented.

Expose a strict operation conceptually:

```text
DIV : NAT -> NAT -> RESULT
```

Behavior:

```text
valid x / valid nonzero y
    → Ok(Nat)

valid x / ZERO
    → Err(DIVIDE-BY-ZERO Error)

wrong input type
    → Error
```

This is the canonical test proving the Error/Result distinction.

---

# 25. Phase 11 — Char

Add:

```text
CHAR-TYPE
```

A Char is:

```text
{
    CHAR-TYPE,
    binary-digit-list
}
```

Its binary payload must represent an integer:

```text
0..255
```

Do not use Racket characters as the object-language representation.

---

# 26. Char construction

Provide a strict constructor:

```text
MAKE-CHAR
```

that accepts a typed Nat.

Behavior:

```text
Nat 0..255
    → Char

Nat >255
    → Error INVALID-CHAR

wrong type
    → Error
```

The stored Char payload may reuse the Nat's normalized raw binary representation rather than nesting a full Nat object.

---

# 27. Character constants

Start with a practical subset rather than all 256 names.

At minimum define:

```text
A-Z
a-z
0-9

SPACE
TAB
CR
LF

.
,
:
;
/
\
-
_
?
=
&
%
#
(
)
[
]
{
}
```

Add any additional printable ASCII characters needed naturally.

Each constant is a genuine lambda-built Char.

No host character literals determine language computation.

---

# 28. Char reader

A host-level reader may:

1. inspect Char's binary payload;
2. convert it to an integer;
3. look up the corresponding character in a fixed reader table;
4. render it for tests/humans.

This reader is outside the object language.

It may not feed the host character back into computation.

For unsupported values, render something deterministic such as:

```text
char:173
```

until a broader table is added.

---

# 29. Phase 12 — String

Add:

```text
STRING-TYPE
```

Representation:

```text
{
    STRING-TYPE,
    char-list
}
```

where `char-list` is the canonical Michaelson-style LIST and every element must be a CHAR.

The empty String is:

```text
{
    STRING-TYPE,
    NIL
}
```

---

# 30. String construction

Provide:

```text
MAKE-STRING
```

Input:

```text
LIST
```

Validate recursively that every element is `CHAR`.

Valid:

```text
[Char('h'), Char('i')]
    → String("hi")
```

Invalid element:

```text
[Char('h'), Nat(5)]
    → Error
```

Validation must use lambda computation.

---

# 31. Initial String operations

Implement at least:

```text
STRING-EMPTY?
STRING-LENGTH
STRING-EQ
STRING-APPEND
STRING-HEAD
STRING-TAIL
STRING-PREFIX?
STRING-CONTAINS?
```

Prefer:

```text
STRING-HEAD
```

and similar partial operations to use either:

- Error for invalid contract use; or
- Result/Option if expected absence is part of the operation.

Do not introduce Option unless it clearly improves the design. Result is sufficient for this initial project.

---

# 32. String length result

`STRING-LENGTH` must return the canonical binary-backed `NAT`.

Do not return a Church numeral merely because list traversal naturally counts with one.

If an internal algorithm uses a Church counter temporarily, convert to binary before exposing the result—or preferably accumulate directly using binary Nat operations.

---

# 33. Function names in Error frames

Once String exists, upgrade structured Error frames.

Add:

```text
function-name : STRING
```

to propagation context.

The generalized typed-function constructor should now accept a lambda String function name.

Conceptually:

```text
make-typed-function
    raw-function
    function-name
    expected-types
    return-policy
```

An error can now structurally represent:

```text
root:
    TYPE-MISMATCH
    expected STRING
    actual NAT
    argument 2

frames:
    [
        function "FOO",
        function "BAR"
    ]
```

Do not flatten this into one String internally.

---

# 34. Error reader

The host reader may render the structured lambda Error into something pleasant:

```text
FOO(arg2 expected STRING got NAT)
  -> BAR(arg1 expected BOOL)
```

The exact presentation is secondary.

The data itself must remain structured.

---

# 35. String reader

A host reader may recursively render Char values into a human-readable host String.

Again:

```text
lambda String
    → host String
```

is one-way observation only.

Do not use host String operations to implement `STRING-EQ`, `STRING-APPEND`, parsing, searching, etc.

---

# 36. Purity validation

Create a simple repository purity check.

Production object-language modules should be scanned for accidental use of forbidden host computation such as:

```text
if
cond
case
+
-
*
/
=
equal?
list
map
foldl
string-append
substring
regexp
vector
hash
set!
```

except in explicitly marked:

```text
readers/
tests/
macros/
tooling/
```

The exact checker may be conservative.

The objective is to make accidental impurity difficult.

---

# 37. Tests

Every major representation needs direct tests.

## Lists

Test:

- NIL is a LIST.
- `IS-NIL NIL`.
- `CONS`.
- `HEAD`.
- `TAIL`.
- `HEAD NIL` Error.
- `TAIL NIL` Error.
- invalid tail to `CONS` Error.
- nested lists.

## Nat

Test:

- normalization.
- 0, 1, 2, powers of two.
- addition.
- subtraction.
- multiplication.
- comparisons.
- larger values demonstrating binary scalability.

## Errors

Test:

- wrong type creates root Error.
- Error passed into another typed function preserves root.
- new frame is added.
- root metadata does not change.

## Generic checker

Test functions of:

```text
0 args if supported
1 arg
2 args
3 args
5 args
```

Prove no arity-specific code exists.

Critically test:

```text
failure on arg1 of a 5-arg function
failure on arg3 of a 5-arg function
```

and prove remaining arguments are safely absorbed before final Error appears.

## IF

Test:

- TRUE selects first branch.
- FALSE selects second.
- wrong condition type → Error.
- incoming Error bubbles.
- unselected divergent/error-producing branch is not forced.

## Result

Test:

- Ok.
- Err.
- divide by zero.
- wrong type remains Error rather than Result Err.

## Char/String

Test:

- valid chars.
- boundary 0.
- boundary 255.
- 256 rejected.
- String validation.
- append.
- equality.
- prefix.
- length.
- empty String.

---

# 38. Documentation requirements

Create `ARCHITECTURE.md` early.

It should explain:

## Underlying truth

Everything computationally meaningful is ultimately untyped lambda calculus.

## Raw versus runtime-typed values

The calculus is untyped, but the language constructs tagged values and enforces runtime contracts.

## Why Church numerals still exist

Only for tiny tags/discriminants.

## Why public numbers are binary

Performance/scalability.

## Why lists follow Michaelson

Explicit list identity and clean NIL semantics.

## Why generic function checking is curried

Expected-type list determines arity and each application validates one argument.

## Error versus Result

Make the distinction explicit.

## Future host boundary

Explain that external effects will later enter through one primitive, but `host` is not part of this phase.

---

# 39. Things explicitly not to build yet

Do not implement:

- `host`;
- filesystem I/O;
- networking;
- HTTP;
- standalone `#lang`;
- CLI;
- numeric literal syntax;
- String literal syntax;
- static typing;
- coercive typing;
- mutation;
- threads;
- async;
- classes;
- records;
- JSON;
- parser beyond Lisp syntax;
- optimizer;
- compiler.

This phase exists to make the **computational universe correct first**.

---

# 40. Implementation sequence

Execute in these passes.

## Pass 1

Repository scaffold, macros, pair, raw Boolean logic.

## Pass 2

Church numeral tags and typed object representation.

## Pass 3

Michaelson-style LIST representation and core operations.

## Pass 4

Binary Nat raw representation and arithmetic.

## Pass 5

Structured Error representation and bubbling primitives.

## Pass 6

Generalized arbitrary-arity curried function type checker, including remaining-arity error absorption.

## Pass 7

Strict typed Bool operations and typed `IF`.

## Pass 8

Migrate Nat API to generalized typing.

## Pass 9

Result and safe binary division.

## Pass 10

Char representation, constants, and reader.

## Pass 11

String representation and basic String algorithms.

## Pass 12

Add String function names to structured error frames; documentation/purity hardening.

Every pass must have focused tests and leave the entire suite green.

---

# 41. Completion criteria for this specification

This first project milestone is complete when a programmer can work entirely with values such as:

```text
TRUE
FALSE

ZERO
ONE
TWO

NIL
CONS

Char
String

Result
Error
```

and write lambda-built computations using strict runtime-checked operations.

The following must all be true:

- lists are explicit Michaelson-style LIST objects;
- empty list is not raw false;
- numbers are scalable binary digit lists;
- Church numerals are used only for tiny tags/discriminants;
- arbitrary-arity functions use one generalized curried runtime checker;
- no `type-check2`, `type-check3`, etc. exist;
- early type failures preserve the remaining curried arity safely;
- Errors preserve root causes and accumulate structured frames;
- Result represents expected failure separately from Error;
- typed `IF` consumes tagged Bool values;
- Char values use 0–255 binary payloads;
- String values are typed lists of typed Char values;
- String operations are themselves lambda computations;
- all core computation remains pure untyped lambda calculus.

---

# 42. Next milestone after this one

Only after the above foundation is stable, begin the next project:

> **AttaLambda: effects and standalone language**

That milestone should add exactly one privileged outside-world primitive:

```text
host
```

Then build ordinary lambda wrappers for:

```text
stdout
read-file
write-file
TCP
```

followed by a minimal lambda-built HTTP server and finally surface the system as its own runnable language.

Do not begin that work until this core milestone is coherent and tested.

---

# 43. Guiding principle

When making a design decision, prefer the option that makes the following sentence most literally true:

> **AttaLambda builds recognizable programming-language behavior out of pure untyped lambda calculus, adding structure through lambda encodings rather than borrowing computation from the host.**

This is a toy language.

It should still be engineered as though its internal rules matter.