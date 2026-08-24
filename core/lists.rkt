#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "bootstrap-errors.rkt"
         "fix.rkt"
         "logic.rkt"
         "objects.rkt"
         "pair.rkt"
         "tags.rkt")

(provide NIL
         raw-cons
         raw-list-head
         raw-list-tail
         raw-list-is-nil
         typed-cons
         typed-head
         typed-tail
         typed-is-nil
         raw-fold
         raw-append
         raw-reverse
         raw-map
         raw-filter)

(def raw-list-cell value tail =
  ((raw-pair value) tail))

(def NIL =
  ((raw-make-object list-type)
   ((raw-list-cell bootstrap-empty-list-error)
    bootstrap-empty-list-error)))

(def raw-cons value tail =
  ((raw-make-object list-type)
   ((raw-list-cell value) tail)))

(def raw-list-head list =
  (raw-first (raw-object-value list)))

(def raw-list-tail list =
  (raw-second (raw-object-value list)))

(def raw-list-is-nil list =
  ((raw-is-type error-type)
   (raw-list-tail list)))

(def typed-cons value tail =
  (((raw-if
     ((raw-is-type error-type) value))
    value)
   (((raw-if
      ((raw-is-type list-type) tail))
     ((raw-cons value) tail))
    (((raw-if
       ((raw-is-type error-type) tail))
      tail)
     bootstrap-type-error))))

(def typed-head list =
  (((raw-if
     ((raw-is-type error-type) list))
    list)
   (((raw-if
      ((raw-is-type list-type) list))
     (((raw-if
        (raw-list-is-nil list))
       bootstrap-empty-list-error)
      (raw-list-head list)))
    bootstrap-type-error)))

(def typed-tail list =
  (((raw-if
     ((raw-is-type error-type) list))
    list)
   (((raw-if
      ((raw-is-type list-type) list))
     (((raw-if
        (raw-list-is-nil list))
       bootstrap-empty-list-error)
      (raw-list-tail list)))
    bootstrap-type-error)))

(def typed-is-nil list =
  (((raw-if
     ((raw-is-type error-type) list))
    list)
   (((raw-if
      ((raw-is-type list-type) list))
     (raw-list-is-nil list))
    bootstrap-type-error)))

(def raw-fold-step recur function initial list =
  (((raw-if
     (raw-list-is-nil list))
    initial)
   ((function (raw-list-head list))
    (((recur function) initial)
     (raw-list-tail list)))))

(def raw-fold =
  (raw-fix raw-fold-step))

(def raw-append left right =
  (((raw-fold raw-cons) right) left))

(def raw-reverse-step recur remaining reversed =
  (((raw-if
     (raw-list-is-nil remaining))
    reversed)
   ((recur (raw-list-tail remaining))
    ((raw-cons (raw-list-head remaining))
     reversed))))

(def raw-reverse list =
  (((raw-fix raw-reverse-step) list) NIL))

(def raw-map-step function value mapped-tail =
  ((raw-cons (function value)) mapped-tail))

(def raw-map function list =
  (((raw-fold (raw-map-step function)) NIL)
   list))

(def raw-filter-step predicate value filtered-tail =
  (((raw-if
     (predicate value))
    ((raw-cons value) filtered-tail))
   filtered-tail))

(def raw-filter predicate list =
  (((raw-fold (raw-filter-step predicate)) NIL)
   list))
