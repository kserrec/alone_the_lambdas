#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "binary-nat.rkt"
         "bootstrap-errors.rkt"
         "fix.rkt"
         "lists.rkt"
         "logic.rkt"
         "objects.rkt"
         "tags.rkt")

(provide raw-list-length
         raw-list-take
         raw-list-drop
         typed-len
         typed-take
         typed-drop)

(def raw-list-length-step recur list count =
  (((raw-if
     (raw-list-is-nil list))
    count)
   ((recur
     (raw-list-tail list))
    (raw-nat-succ count))))

(def raw-list-length list =
  (((raw-fix raw-list-length-step)
    list)
   (raw-nat-value ZERO)))

(def raw-list-take-step recur count list =
  (((raw-if
     ((raw-or
       (raw-nat-is-zero count))
      (raw-list-is-nil list)))
    NIL)
   ((raw-cons
     (raw-list-head list))
    ((recur
      ((raw-nat-sub count)
       (raw-nat-value ONE)))
     (raw-list-tail list)))))

(def raw-list-take count list =
  (((raw-fix raw-list-take-step)
    count)
   list))

(def raw-list-drop-step recur count list =
  (((raw-if
     ((raw-or
       (raw-nat-is-zero count))
      (raw-list-is-nil list)))
    list)
   ((recur
     ((raw-nat-sub count)
      (raw-nat-value ONE)))
    (raw-list-tail list))))

(def raw-list-drop count list =
  (((raw-fix raw-list-drop-step)
    count)
   list))

(def typed-len list =
  (((raw-if
     ((raw-is-type error-type) list))
    list)
   (((raw-if
      ((raw-is-type list-type) list))
     (raw-make-nat
      (raw-list-length list)))
    bootstrap-type-error)))

(def typed-take-list count list =
  (((raw-if
     ((raw-is-type error-type) list))
    list)
   (((raw-if
      ((raw-is-type list-type) list))
     ((raw-list-take
       (raw-nat-value count))
      list))
    bootstrap-type-error)))

(def typed-take count =
  (((raw-if
     ((raw-is-type error-type) count))
    (lambda (ignored)
      count))
   (((raw-if
      ((raw-is-type nat-type) count))
     (typed-take-list count))
    (lambda (ignored)
      bootstrap-type-error))))

(def typed-drop-list count list =
  (((raw-if
     ((raw-is-type error-type) list))
    list)
   (((raw-if
      ((raw-is-type list-type) list))
     ((raw-list-drop
       (raw-nat-value count))
      list))
    bootstrap-type-error)))

(def typed-drop count =
  (((raw-if
     ((raw-is-type error-type) count))
    (lambda (ignored)
      count))
   (((raw-if
      ((raw-is-type nat-type) count))
     (typed-drop-list count))
    (lambda (ignored)
      bootstrap-type-error))))
