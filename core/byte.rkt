#lang s-exp "../macros/lazy-with-macros.rkt"

;; Byte is public data, not a second number type: exactly 256 valid values
;; from 0 through 255, internally backed by a private normalized binary Nat
;; magnitude. Construction takes a nonnegative whole Rat and rejects every
;; other value as the InvalidByte contract Error; conversion back yields a
;; whole-valued Rat. Ordinary Rat arithmetic rejects Byte through the
;; unchanged exact-tag checker. A byte sequence is `List Byte`; no separate
;; Bytes type exists.

(require "../macros/macros.rkt"
         "binary-nat.rkt"
         (only-in "errors.rkt"
                  NIL
                  raw-cons
                  raw-add-result-frame
                  invalid-byte-error)
         "function-names.rkt"
         "logic.rkt"
         "objects.rkt"
         (only-in "rat.rkt"
                  raw-rat-is-nonnegative-whole
                  raw-rat-magnitude-bits
                  raw-whole-rat)
         "tags.rkt"
         "typecheck.rkt")

(provide raw-make-byte
         raw-byte-value
         typed-make-byte
         typed-byte-value
         typed-byte-equal
         typed-byte-less
         typed-byte-less-equal
         typed-byte-greater
         typed-byte-greater-equal
         (rename-out [typed-make-byte MAKE-BYTE]
                     [typed-byte-value BYTE-VALUE]
                     [typed-byte-equal BYTE-EQ]
                     [typed-byte-less BYTE-LT]
                     [typed-byte-less-equal BYTE-LTE]
                     [typed-byte-greater BYTE-GT]
                     [typed-byte-greater-equal BYTE-GTE]))

(def raw-two-bits =
  (raw-nat-succ raw-one-bits))

(def raw-four-bits =
  ((raw-nat-add raw-two-bits) raw-two-bits))

(def raw-sixteen-bits =
  ((raw-nat-mult raw-four-bits) raw-four-bits))

(def raw-byte-max-bits =
  ((raw-nat-sub
    ((raw-nat-mult raw-sixteen-bits)
     raw-sixteen-bits))
   raw-one-bits))

(def raw-make-byte bits =
  ((raw-make-object byte-type)
   (raw-normalize-nat bits)))

(def raw-byte-value byte =
  (raw-object-value byte))

(def raw-make-checked-byte rat =
  (((raw-if
     (raw-rat-is-nonnegative-whole rat))
    (lambda-let magnitude = (raw-rat-magnitude-bits rat)
      (((raw-if
         ((raw-nat-less-equal magnitude)
          raw-byte-max-bits))
        (raw-make-byte magnitude))
       ((raw-add-result-frame invalid-byte-error)
        make-byte-function-name))))
   ((raw-add-result-frame invalid-byte-error)
    make-byte-function-name)))

(def raw-byte-to-rat bits =
  (raw-whole-rat bits))

(def byte-constructor-signature =
  ((raw-cons rat-type) NIL))

(def byte-unary-signature =
  ((raw-cons byte-type) NIL))

(def byte-binary-signature =
  ((raw-cons byte-type)
   ((raw-cons byte-type) NIL)))

(def typed-make-byte =
  ((((make-typed-function raw-make-checked-byte)
     make-byte-function-name)
    byte-constructor-signature)
   raw-keep-return))

(def typed-byte-value =
  ((((make-typed-function raw-byte-to-rat)
     byte-value-function-name)
    byte-unary-signature)
   (raw-wrap-return rat-type)))

(def typed-byte-equal =
  ((((make-typed-function raw-nat-equal)
     byte-eq-function-name)
    byte-binary-signature)
   (raw-wrap-return bool-type)))

(def typed-byte-less =
  ((((make-typed-function raw-nat-less)
     byte-lt-function-name)
    byte-binary-signature)
   (raw-wrap-return bool-type)))

(def typed-byte-less-equal =
  ((((make-typed-function raw-nat-less-equal)
     byte-lte-function-name)
    byte-binary-signature)
   (raw-wrap-return bool-type)))

(def typed-byte-greater =
  ((((make-typed-function raw-nat-greater)
     byte-gt-function-name)
    byte-binary-signature)
   (raw-wrap-return bool-type)))

(def typed-byte-greater-equal =
  ((((make-typed-function raw-nat-greater-equal)
     byte-gte-function-name)
    byte-binary-signature)
   (raw-wrap-return bool-type)))
