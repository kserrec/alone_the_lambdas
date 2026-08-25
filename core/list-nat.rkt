#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "binary-nat.rkt"
         "fix.rkt"
         "function-names.rkt"
         "lists.rkt"
         "logic.rkt"
         "objects.rkt"
         "tags.rkt"
         "typecheck.rkt")

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

(def list-unary-signature =
  ((raw-cons list-type) NIL))

(def nat-list-signature =
  ((raw-cons nat-type)
   ((raw-cons list-type) NIL)))

(def raw-list-object payload =
  ((raw-make-object list-type) payload))

(def raw-list-length-value list-value =
  (raw-list-length
   (raw-list-object list-value)))

(def raw-list-take-values count list-value =
  ((raw-list-take count)
   (raw-list-object list-value)))

(def raw-list-drop-values count list-value =
  ((raw-list-drop count)
   (raw-list-object list-value)))

(def typed-len =
  ((((make-typed-function raw-list-length-value)
     len-function-name)
    list-unary-signature)
   (raw-wrap-return nat-type)))

(def typed-take =
  ((((make-typed-function raw-list-take-values)
     take-function-name)
    nat-list-signature)
   raw-keep-return))

(def typed-drop =
  ((((make-typed-function raw-list-drop-values)
     drop-function-name)
    nat-list-signature)
   raw-keep-return))
