#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt")

(provide raw-true
         raw-false
         raw-if
         raw-not
         raw-and
         raw-or
         raw-xor)

(def raw-true when-true when-false =
  when-true)

(def raw-false when-true when-false =
  when-false)

(def raw-if condition then-value else-value =
  ((condition then-value) else-value))

(def raw-not value =
  ((value raw-false) raw-true))

(def raw-and left right =
  ((left right) raw-false))

(def raw-or left right =
  ((left raw-true) right))

(def raw-xor left right =
  ((left (raw-not right)) right))
