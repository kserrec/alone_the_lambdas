#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "fix.rkt"
         "logic.rkt"
         "objects.rkt"
         "pair.rkt"
         "tags.rkt")

(provide type-mismatch-kind
         empty-list-kind
         invalid-nat-kind
         divide-by-zero-kind
         invalid-char-kind
         invalid-string-kind
         wrong-result-variant-kind
         non-whole-exponent-kind
         result-position
         argument-position-one
         argument-position-two
         raw-error-kind-equal
         raw-make-error-root
         raw-error-root-kind
         raw-error-root-details
         raw-make-type-mismatch-details
         raw-type-mismatch-argument-position
         raw-type-mismatch-expected-type
         raw-type-mismatch-actual-type
         raw-make-error-frame
         raw-error-frame-function-name
         raw-error-frame-argument-position
         raw-error-frame-expected-type
         raw-make-error-payload
         raw-error-payload-root
         raw-error-payload-frames
         raw-make-error
         raw-error-root
         raw-error-frames
         raw-make-root-error
         raw-make-type-mismatch-error
         raw-add-error-frame
         raw-bubble-error
         raw-add-result-frame
         NIL
         raw-cons
         empty-list-error
         invalid-nat-error
         divide-by-zero-error
         invalid-char-error
         invalid-string-error
         wrong-result-variant-error
         non-whole-exponent-error)

(def type-mismatch-kind = church-zero)
(def empty-list-kind = church-one)
(def invalid-nat-kind = church-two)
(def divide-by-zero-kind = church-three)
(def invalid-char-kind = church-four)
(def invalid-string-kind = church-five)
(def wrong-result-variant-kind = church-six)
(def non-whole-exponent-kind = church-seven)

(def result-position = church-zero)
(def argument-position-one = church-one)
(def argument-position-two = church-two)

(def raw-error-kind-equal left right =
  ((raw-tag-equal left) right))

(def raw-make-error-root kind details =
  ((raw-pair kind) details))

(def raw-error-root-kind root =
  (raw-first root))

(def raw-error-root-details root =
  (raw-second root))

(def raw-make-type-mismatch-details argument-position expected-type actual-type =
  ((raw-pair argument-position)
   ((raw-pair expected-type) actual-type)))

(def raw-type-mismatch-argument-position details =
  (raw-first details))

(def raw-type-mismatch-expected-type details =
  (raw-first
   (raw-second details)))

(def raw-type-mismatch-actual-type details =
  (raw-second
   (raw-second details)))

(def raw-make-error-frame function-name argument-position expected-type =
  ((raw-pair function-name)
   ((raw-pair argument-position) expected-type)))

(def raw-error-frame-function-name frame =
  (raw-first frame))

(def raw-error-frame-argument-position frame =
  (raw-first
   (raw-second frame)))

(def raw-error-frame-expected-type frame =
  (raw-second
   (raw-second frame)))

(def raw-make-error-payload root frames =
  ((raw-pair root) frames))

(def raw-error-payload-root payload =
  (raw-first payload))

(def raw-error-payload-frames payload =
  (raw-second payload))

(def raw-make-error root frames =
  ((raw-make-object error-type)
   ((raw-make-error-payload root) frames)))

(def raw-error-root error =
  (raw-error-payload-root
   (raw-object-value error)))

(def raw-error-frames error =
  (raw-error-payload-frames
   (raw-object-value error)))

(def raw-error-list-knot-step self =
  ((raw-pair
    ((raw-make-object list-type)
     ((raw-pair
       (raw-second self))
      (raw-second self))))
   ((raw-make-object error-type)
    ((raw-make-error-payload
      ((raw-make-error-root empty-list-kind)
       raw-false))
     (raw-first self)))))

(def raw-error-list-knot =
  (raw-fix raw-error-list-knot-step))

(def NIL =
  (raw-first raw-error-list-knot))

(def empty-list-error =
  (raw-second raw-error-list-knot))

(def raw-cons value tail =
  ((raw-make-object list-type)
   ((raw-pair value) tail)))

(def raw-make-root-error kind =
  ((raw-make-error
    ((raw-make-error-root kind)
     raw-false))
   NIL))

(def raw-make-type-mismatch-error argument-position expected-type actual-type =
  ((raw-make-error
    ((raw-make-error-root type-mismatch-kind)
     (((raw-make-type-mismatch-details argument-position)
       expected-type)
      actual-type)))
   NIL))

(def raw-add-error-frame error frame =
  ((raw-make-error
    (raw-error-root error))
   ((raw-cons frame)
    (raw-error-frames error))))

(def raw-bubble-error error function-name argument-position expected-type =
  ((raw-add-error-frame error)
   (((raw-make-error-frame function-name)
     argument-position)
    expected-type)))

(def raw-add-result-frame error function-name =
  ((raw-add-error-frame error)
   (((raw-make-error-frame function-name)
     result-position)
    error-type)))

(def invalid-nat-error =
  (raw-make-root-error invalid-nat-kind))

(def divide-by-zero-error =
  (raw-make-root-error divide-by-zero-kind))

(def invalid-char-error =
  (raw-make-root-error invalid-char-kind))

(def invalid-string-error =
  (raw-make-root-error invalid-string-kind))

(def wrong-result-variant-error =
  (raw-make-root-error wrong-result-variant-kind))

(def non-whole-exponent-error =
  (raw-make-root-error non-whole-exponent-kind))
