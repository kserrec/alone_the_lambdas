#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "binary-nat.rkt"
         "errors.rkt"
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
    (((raw-bubble-error list)
      argument-position-one)
     list-type))
   (((raw-if
      ((raw-is-type list-type) list))
     (raw-make-nat
      (raw-list-length list)))
    (((raw-make-type-mismatch-error
       argument-position-one)
      list-type)
     (raw-object-type list)))))

(def typed-take-list count list =
  (((raw-if
     ((raw-is-type error-type) list))
    (((raw-bubble-error list)
      argument-position-two)
     list-type))
   (((raw-if
      ((raw-is-type list-type) list))
     ((raw-list-take
      (raw-nat-value count))
      list))
    (((raw-make-type-mismatch-error
       argument-position-two)
      list-type)
     (raw-object-type list)))))

(def typed-take count =
  (((raw-if
     ((raw-is-type error-type) count))
    (lambda (ignored)
      (((raw-bubble-error count)
        argument-position-one)
       nat-type)))
   (((raw-if
      ((raw-is-type nat-type) count))
     (typed-take-list count))
    (lambda (ignored)
      (((raw-make-type-mismatch-error
         argument-position-one)
        nat-type)
       (raw-object-type count))))))

(def typed-drop-list count list =
  (((raw-if
     ((raw-is-type error-type) list))
    (((raw-bubble-error list)
      argument-position-two)
     list-type))
   (((raw-if
      ((raw-is-type list-type) list))
     ((raw-list-drop
      (raw-nat-value count))
      list))
    (((raw-make-type-mismatch-error
       argument-position-two)
      list-type)
     (raw-object-type list)))))

(def typed-drop count =
  (((raw-if
     ((raw-is-type error-type) count))
    (lambda (ignored)
      (((raw-bubble-error count)
        argument-position-one)
       nat-type)))
   (((raw-if
      ((raw-is-type nat-type) count))
     (typed-drop-list count))
    (lambda (ignored)
      (((raw-make-type-mismatch-error
         argument-position-one)
        nat-type)
       (raw-object-type count))))))
