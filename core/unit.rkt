#lang s-exp "../macros/lazy-with-macros.rkt"

;; Unit is the public type with exactly one value. UNIT carries a single
;; fixed internal payload and replaces Ok(NIL) wherever an operation
;; succeeds with no useful answer, so NIL means only an actual empty List.
;; There is no Unit predicate: the exact-tag checker validates Unit
;; positionally, and no polymorphic mechanism is added to support one.

(require "../macros/macros.rkt"
         "logic.rkt"
         "objects.rkt"
         "tags.rkt")

(provide UNIT)

(def UNIT =
  ((raw-make-object unit-type) raw-true))
