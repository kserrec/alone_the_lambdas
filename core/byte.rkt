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
         (only-in "chars.rkt"
                  raw-make-char
                  raw-char-value)
         (only-in "errors.rkt"
                  NIL
                  raw-cons
                  raw-add-result-frame
                  invalid-byte-error)
         "fix.rkt"
         "function-names.rkt"
         (only-in "lists.rkt"
                  raw-list-head
                  raw-list-is-nil
                  raw-list-tail
                  raw-map)
         "logic.rkt"
         "objects.rkt"
         (only-in "rat.rkt"
                  raw-rat-is-nonnegative-whole
                  raw-rat-magnitude-bits
                  raw-whole-rat)
         (only-in "strings.rkt"
                  raw-make-string)
         "tags.rkt"
         "typecheck.rkt")

(provide raw-make-byte
         raw-byte-value
         typed-string-to-bytes
         typed-bytes-to-string
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
                     [typed-byte-greater-equal BYTE-GTE]
                     [typed-string-to-bytes STRING-TO-BYTES]
                     [typed-bytes-to-string BYTES-TO-STRING]))

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

;; A byte sequence is `List Byte`. Text crosses to binary data and back
;; entirely in lambda computation: one Byte per Char in each direction,
;; validating every element rather than assuming any List is a byte
;; sequence.

(def raw-char-to-byte char =
  (raw-make-byte
   (raw-char-value char)))

(def raw-string-to-bytes chars =
  ((raw-map raw-char-to-byte) chars))

(def raw-byte-to-char byte =
  (raw-make-char
   (raw-byte-value byte)))

(def raw-byte-list-valid-step recur bytes =
  (((raw-if
     (raw-list-is-nil bytes))
    raw-true)
   (((raw-if
      ((raw-is-type byte-type)
       (raw-list-head bytes)))
     (recur
      (raw-list-tail bytes)))
    raw-false)))

(def raw-byte-list-valid? =
  (raw-fix raw-byte-list-valid-step))

(def raw-list-object payload =
  ((raw-make-object list-type) payload))

(def raw-bytes-to-string list-payload =
  (lambda-let bytes =
    (raw-list-object list-payload)
    (((raw-if
       (raw-byte-list-valid? bytes))
      (raw-make-string
       ((raw-map raw-byte-to-char) bytes)))
     ((raw-add-result-frame invalid-byte-error)
      bytes-to-string-function-name))))

(def string-unary-signature =
  ((raw-cons string-type) NIL))

(def list-unary-signature =
  ((raw-cons list-type) NIL))

(def typed-string-to-bytes =
  ((((make-typed-function raw-string-to-bytes)
     string-to-bytes-function-name)
    string-unary-signature)
   raw-keep-return))

(def typed-bytes-to-string =
  ((((make-typed-function raw-bytes-to-string)
     bytes-to-string-function-name)
    list-unary-signature)
   raw-keep-return))
