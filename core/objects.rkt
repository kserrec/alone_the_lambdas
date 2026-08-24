#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "pair.rkt"
         "tags.rkt")

(provide raw-make-object
         raw-object-type
         raw-object-value
         raw-is-type)

(def raw-make-object type-tag value =
  ((raw-pair type-tag) value))

(def raw-object-type object =
  (raw-first object))

(def raw-object-value object =
  (raw-second object))

(def raw-is-type expected-type object =
  ((raw-tag-equal expected-type)
   (raw-object-type object)))
