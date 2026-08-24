#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "logic.rkt"
         "objects.rkt"
         "tags.rkt")

(provide bootstrap-type-error
         bootstrap-empty-list-error)

(def bootstrap-error payload =
  ((raw-make-object error-type) payload))

(def bootstrap-type-error =
  (bootstrap-error raw-false))

(def bootstrap-empty-list-error =
  (bootstrap-error raw-true))
