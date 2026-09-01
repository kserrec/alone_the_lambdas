#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "binary-nat.rkt"
         "errors.rkt"
         "function-names.rkt"
         "lists.rkt"
         "logic.rkt"
         "objects.rkt"
         "result.rkt"
         "tags.rkt"
         "typecheck.rkt")

(provide raw-make-nat
         raw-nat-value
         ZERO
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

;; Temporary compatibility layer: tagged Nat construction and the public
;; constants live here until Phase 35 replaces the public Nat surface with
;; Rat. Raw arithmetic in binary-nat.rkt stays free of tags and objects.

(def raw-make-nat bits =
  ((raw-make-object nat-type)
   (raw-normalize-nat bits)))

(def raw-nat-value nat =
  (raw-object-value nat))

(def ZERO =
  (raw-make-nat raw-zero-bits))

(def ONE =
  (raw-make-nat raw-one-bits))

(def TWO =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value ONE))))

(def THREE =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value TWO))))

(def FOUR =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value THREE))))

(def FIVE =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value FOUR))))

(def SIX =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value FIVE))))

(def SEVEN =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value SIX))))

(def EIGHT =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value SEVEN))))

(def NINE =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value EIGHT))))

(def TEN =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value NINE))))

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
  ((((make-typed-function raw-nat-succ)
     succ-function-name)
    nat-unary-signature)
   nat-return-policy))

(def typed-nat-add =
  ((((make-typed-function raw-nat-add)
     add-function-name)
    nat-binary-signature)
   nat-return-policy))

(def typed-nat-sub =
  ((((make-typed-function raw-nat-sub)
     sub-function-name)
    nat-binary-signature)
   nat-return-policy))

(def typed-nat-mult =
  ((((make-typed-function raw-nat-mult)
     mult-function-name)
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
  ((((make-typed-function raw-safe-nat-div)
     div-function-name)
    nat-binary-signature)
   raw-keep-return))

(def typed-nat-equal =
  ((((make-typed-function raw-nat-equal)
     eq-function-name)
    nat-binary-signature)
   bool-return-policy))

(def typed-nat-less =
  ((((make-typed-function raw-nat-less)
     lt-function-name)
    nat-binary-signature)
   bool-return-policy))

(def typed-nat-less-equal =
  ((((make-typed-function raw-nat-less-equal)
     lte-function-name)
    nat-binary-signature)
   bool-return-policy))

(def typed-nat-greater =
  ((((make-typed-function raw-nat-greater)
     gt-function-name)
    nat-binary-signature)
   bool-return-policy))

(def typed-nat-greater-equal =
  ((((make-typed-function raw-nat-greater-equal)
     gte-function-name)
    nat-binary-signature)
   bool-return-policy))

(def typed-nat-is-zero =
  ((((make-typed-function raw-nat-is-zero)
     is-zero-function-name)
    nat-unary-signature)
   bool-return-policy))
