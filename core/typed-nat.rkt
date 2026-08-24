#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "binary-nat.rkt"
         "errors.rkt"
         "lists.rkt"
         "logic.rkt"
         "result.rkt"
         "tags.rkt"
         "typecheck.rkt")

(provide ZERO
         ONE
         TWO
         THREE
         FOUR
         FIVE
         SIX
         SEVEN
         EIGHT
         NINE
         TEN
         typed-nat-succ
         typed-nat-add
         typed-nat-sub
         typed-nat-mult
         typed-nat-div
         typed-nat-equal
         typed-nat-less
         typed-nat-less-equal
         typed-nat-greater
         typed-nat-greater-equal
         typed-nat-is-zero
         (rename-out [typed-nat-succ SUCC]
                     [typed-nat-add ADD]
                     [typed-nat-sub SUB]
                     [typed-nat-mult MULT]
                     [typed-nat-div DIV]
                     [typed-nat-equal EQ]
                     [typed-nat-less LT]
                     [typed-nat-less-equal LTE]
                     [typed-nat-greater GT]
                     [typed-nat-greater-equal GTE]
                     [typed-nat-is-zero IS-ZERO]))

(def nat-unary-signature =
  ((raw-cons nat-type) NIL))

(def nat-binary-signature =
  ((raw-cons nat-type)
   ((raw-cons nat-type) NIL)))

(def nat-return-policy =
  (raw-wrap-return nat-type))

(def bool-return-policy =
  (raw-wrap-return bool-type))

(def typed-nat-succ =
  (((make-typed-function raw-nat-succ)
    nat-unary-signature)
   nat-return-policy))

(def typed-nat-add =
  (((make-typed-function raw-nat-add)
    nat-binary-signature)
   nat-return-policy))

(def typed-nat-sub =
  (((make-typed-function raw-nat-sub)
    nat-binary-signature)
   nat-return-policy))

(def typed-nat-mult =
  (((make-typed-function raw-nat-mult)
    nat-binary-signature)
   nat-return-policy))

(def raw-safe-nat-div dividend divisor =
  (((raw-if
     (raw-nat-is-zero divisor))
    (raw-make-err divide-by-zero-error))
   (raw-make-ok
    (raw-make-nat
     ((raw-nat-div dividend) divisor)))))

(def typed-nat-div =
  (((make-typed-function raw-safe-nat-div)
    nat-binary-signature)
   raw-keep-return))

(def typed-nat-equal =
  (((make-typed-function raw-nat-equal)
    nat-binary-signature)
   bool-return-policy))

(def typed-nat-less =
  (((make-typed-function raw-nat-less)
    nat-binary-signature)
   bool-return-policy))

(def typed-nat-less-equal =
  (((make-typed-function raw-nat-less-equal)
    nat-binary-signature)
   bool-return-policy))

(def typed-nat-greater =
  (((make-typed-function raw-nat-greater)
    nat-binary-signature)
   bool-return-policy))

(def typed-nat-greater-equal =
  (((make-typed-function raw-nat-greater-equal)
    nat-binary-signature)
   bool-return-policy))

(def typed-nat-is-zero =
  (((make-typed-function raw-nat-is-zero)
    nat-unary-signature)
   bool-return-policy))
