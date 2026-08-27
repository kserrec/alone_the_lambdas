#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "errors.rkt"
         "function-names.rkt"
         "lists.rkt"
         "logic.rkt"
         "objects.rkt"
         "pair.rkt"
         "tags.rkt"
         "typecheck.rkt")

(provide raw-make-result
         raw-make-ok
         raw-make-err
         raw-result-is-ok
         raw-result-is-err
         raw-result-value
         raw-result-unwrap-ok
         raw-result-unwrap-err
         typed-make-ok
         typed-make-err
         typed-result-is-ok
         typed-result-is-err
         typed-result-unwrap-ok
         typed-result-unwrap-err
         (rename-out [typed-make-ok make-ok]
                     [typed-make-err make-err]
                     [typed-result-is-ok is-ok]
                     [typed-result-is-err is-err]
                     [typed-result-unwrap-ok unwrap-ok]
                     [typed-result-unwrap-err unwrap-err]))

(def raw-make-result success payload =
  ((raw-make-object result-type)
   ((raw-pair success) payload)))

(def raw-make-ok payload =
  ((raw-make-result raw-true) payload))

(def raw-make-err error =
  ((raw-make-result raw-false) error))

(def raw-result-is-ok payload =
  (raw-first payload))

(def raw-result-is-err payload =
  (raw-not
   (raw-result-is-ok payload)))

(def raw-result-value payload =
  (raw-second payload))

(def raw-result-unwrap-ok payload =
  (((raw-if
     (raw-result-is-ok payload))
    (raw-result-value payload))
   ((raw-add-result-frame wrong-result-variant-error)
    unwrap-ok-function-name)))

(def raw-result-unwrap-err payload =
  (((raw-if
     (raw-result-is-err payload))
    (raw-result-value payload))
   ((raw-add-result-frame wrong-result-variant-error)
    unwrap-err-function-name)))

(def result-unary-signature =
  ((raw-cons result-type) NIL))

(def typed-make-ok value =
  (((raw-if
     ((raw-is-type error-type) value))
    value)
   (raw-make-ok value)))

;; This constructor intentionally consumes an Error as data instead of
;; bubbling it through the typed boundary.
(def typed-make-err error =
  (((raw-if
     ((raw-is-type error-type) error))
    (raw-make-err error))
   ((((raw-bubble-error
       (((raw-make-type-mismatch-error
          argument-position-one)
         error-type)
        (raw-object-type error)))
      make-err-function-name)
     argument-position-one)
    error-type)))

(def typed-result-is-ok =
  ((((make-typed-function raw-result-is-ok)
     is-ok-function-name)
    result-unary-signature)
   (raw-wrap-return bool-type)))

(def typed-result-is-err =
  ((((make-typed-function raw-result-is-err)
     is-err-function-name)
    result-unary-signature)
   (raw-wrap-return bool-type)))

(def typed-result-unwrap-ok =
  ((((make-typed-function raw-result-unwrap-ok)
     unwrap-ok-function-name)
    result-unary-signature)
   raw-keep-return))

(def typed-result-unwrap-err =
  ((((make-typed-function raw-result-unwrap-err)
     unwrap-err-function-name)
    result-unary-signature)
   raw-keep-return))
