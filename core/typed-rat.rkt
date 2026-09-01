#lang s-exp "../macros/lazy-with-macros.rkt"

;; Strict tagged Rat layer over the private canonical rationals. Every
;; operation uses the existing generalized exact-tag checker unchanged: no
;; numeric hierarchy, promotion, dispatcher, or new checker form. Expected
;; arithmetic failures (division by zero, reciprocal of zero, non-whole or
;; zero-base-negative exponents) are already-tagged Result values from the
;; raw layer and keep their return; wrong argument types produce Error.
;; This layer stays out of the #lang attalambda exports until the single
;; public switch in Step 35.5.

(require "../macros/macros.rkt"
         "function-names.rkt"
         "lists.rkt"
         "logic.rkt"
         "objects.rkt"
         "rat.rkt"
         (only-in "result.rkt"
                  raw-make-ok
                  raw-result-is-ok
                  raw-result-value)
         "tags.rkt"
         "typecheck.rkt")

(provide typed-rat-succ
         typed-rat-add
         typed-rat-sub
         typed-rat-mult
         typed-rat-div
         typed-rat-exp
         typed-rat-recip
         typed-rat-negate
         typed-rat-abs
         typed-rat-floor
         typed-rat-equal
         typed-rat-less
         typed-rat-less-equal
         typed-rat-greater
         typed-rat-greater-equal
         typed-rat-is-zero
         typed-rat-is-whole
         typed-rat-is-nonnegative-whole)

(def rat-unary-signature =
  ((raw-cons rat-type) NIL))

(def rat-binary-signature =
  ((raw-cons rat-type)
   ((raw-cons rat-type) NIL)))

(def rat-return-policy =
  (raw-wrap-return rat-type))

(def rat-bool-return-policy =
  (raw-wrap-return bool-type))

;; The raw Result payload for a successful division, reciprocal, or power
;; is a raw canonical rational; the strict layer re-wraps it as a tagged
;; Rat so unwrap-ok yields an ordinary public value, exactly as safe Nat
;; division wraps its quotient.
(def raw-tag-ok-rat result =
  (lambda-let payload = (raw-object-value result)
    (((raw-if
       (raw-result-is-ok payload))
      (raw-make-ok
       ((raw-make-object rat-type)
        (raw-result-value payload))))
     result)))

(def raw-safe-rat-div left right =
  (raw-tag-ok-rat
   ((raw-rat-div left) right)))

(def raw-safe-rat-exp base exponent =
  (raw-tag-ok-rat
   ((raw-rat-exp base) exponent)))

(def raw-safe-rat-recip rat =
  (raw-tag-ok-rat
   (raw-rat-recip rat)))

(def typed-rat-succ =
  ((((make-typed-function raw-rat-succ)
     succ-function-name)
    rat-unary-signature)
   rat-return-policy))

(def typed-rat-add =
  ((((make-typed-function raw-rat-add)
     add-function-name)
    rat-binary-signature)
   rat-return-policy))

(def typed-rat-sub =
  ((((make-typed-function raw-rat-sub)
     sub-function-name)
    rat-binary-signature)
   rat-return-policy))

(def typed-rat-mult =
  ((((make-typed-function raw-rat-mult)
     mult-function-name)
    rat-binary-signature)
   rat-return-policy))

(def typed-rat-div =
  ((((make-typed-function raw-safe-rat-div)
     div-function-name)
    rat-binary-signature)
   raw-keep-return))

(def typed-rat-exp =
  ((((make-typed-function raw-safe-rat-exp)
     exp-function-name)
    rat-binary-signature)
   raw-keep-return))

(def typed-rat-recip =
  ((((make-typed-function raw-safe-rat-recip)
     recip-function-name)
    rat-unary-signature)
   raw-keep-return))

(def typed-rat-negate =
  ((((make-typed-function raw-rat-negate)
     neg-function-name)
    rat-unary-signature)
   rat-return-policy))

(def typed-rat-abs =
  ((((make-typed-function raw-rat-abs)
     abs-function-name)
    rat-unary-signature)
   rat-return-policy))

(def typed-rat-floor =
  ((((make-typed-function raw-rat-floor)
     floor-function-name)
    rat-unary-signature)
   rat-return-policy))

(def typed-rat-equal =
  ((((make-typed-function raw-rat-equal)
     eq-function-name)
    rat-binary-signature)
   rat-bool-return-policy))

(def typed-rat-less =
  ((((make-typed-function raw-rat-less)
     lt-function-name)
    rat-binary-signature)
   rat-bool-return-policy))

(def typed-rat-less-equal =
  ((((make-typed-function raw-rat-less-equal)
     lte-function-name)
    rat-binary-signature)
   rat-bool-return-policy))

(def typed-rat-greater =
  ((((make-typed-function raw-rat-greater)
     gt-function-name)
    rat-binary-signature)
   rat-bool-return-policy))

(def typed-rat-greater-equal =
  ((((make-typed-function raw-rat-greater-equal)
     gte-function-name)
    rat-binary-signature)
   rat-bool-return-policy))

(def typed-rat-is-zero =
  ((((make-typed-function raw-rat-is-zero)
     is-zero-function-name)
    rat-unary-signature)
   rat-bool-return-policy))

(def typed-rat-is-whole =
  ((((make-typed-function raw-rat-is-whole)
     is-whole-function-name)
    rat-unary-signature)
   rat-bool-return-policy))

(def typed-rat-is-nonnegative-whole =
  ((((make-typed-function raw-rat-is-nonnegative-whole)
     is-nonnegative-whole-function-name)
    rat-unary-signature)
   rat-bool-return-policy))
