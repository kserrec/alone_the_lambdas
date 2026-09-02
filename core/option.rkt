#lang s-exp "../macros/lazy-with-macros.rkt"

;; Option is the public type for expected absence: `SOME value` holds any
;; non-Error object-language value (an Error argument bubbles instead of
;; hiding inside Some), and NONE is the singleton absent form. NONE means
;; expected absence; `Result Err` means a computation failed. OPTION-CASE
;; is the lazy eliminator: like IF, its return is intentionally
;; polymorphic, so it validates its Option argument strictly and then
;; selects one branch without evaluating the other. No `Any` tag exists
;; and the generalized checker is unchanged.

(require "../macros/macros.rkt"
         (only-in "errors.rkt"
                  NIL
                  raw-cons
                  raw-bubble-error
                  raw-make-type-mismatch-error
                  argument-position-one)
         "function-names.rkt"
         "logic.rkt"
         "objects.rkt"
         "pair.rkt"
         "tags.rkt"
         "typecheck.rkt")

(provide raw-make-some
         raw-option-is-some
         raw-option-value
         NONE
         typed-make-some
         typed-option-is-some
         typed-option-is-none
         typed-option-case
         (rename-out [typed-make-some SOME]
                     [typed-option-is-some IS-SOME]
                     [typed-option-is-none IS-NONE]
                     [typed-option-case OPTION-CASE]))

(def raw-make-option flag payload =
  ((raw-make-object option-type)
   ((raw-pair flag) payload)))

(def raw-make-some payload =
  ((raw-make-option raw-true) payload))

(def NONE =
  ((raw-make-option raw-false) raw-false))

(def raw-option-is-some payload =
  (raw-first payload))

(def raw-option-value payload =
  (raw-second payload))

(def option-unary-signature =
  ((raw-cons option-type) NIL))

(def typed-make-some value =
  (((raw-if
     ((raw-is-type error-type) value))
    value)
   (raw-make-some value)))

(def typed-option-is-some =
  ((((make-typed-function raw-option-is-some)
     is-some-function-name)
    option-unary-signature)
   (raw-wrap-return bool-type)))

(def raw-option-is-none payload =
  (raw-not
   (raw-option-is-some payload)))

(def typed-option-is-none =
  ((((make-typed-function raw-option-is-none)
     is-none-function-name)
    option-unary-signature)
   (raw-wrap-return bool-type)))

;; OPTION-CASE option some-function none-value: strict on the Option,
;; lazy on both branches.
(def typed-option-case option some-function none-value =
  (((raw-if
     ((raw-is-type error-type) option))
    ((((raw-bubble-error option)
       option-case-function-name)
      argument-position-one)
     option-type))
   (((raw-if
      ((raw-is-type option-type) option))
     (lambda-let payload = (raw-object-value option)
       (((raw-if
          (raw-option-is-some payload))
         (some-function
          (raw-option-value payload)))
        none-value)))
    ((((raw-bubble-error
        (((raw-make-type-mismatch-error
           argument-position-one)
          option-type)
         (raw-object-type option)))
       option-case-function-name)
      argument-position-one)
     option-type))))
