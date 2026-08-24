#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt")

(provide raw-pair
         raw-first
         raw-second)

(def raw-pair left right selector =
  ((selector left) right))

(def raw-first value =
  (value
   (lambda (left)
     (lambda (right)
       left))))

(def raw-second value =
  (value
   (lambda (left)
     (lambda (right)
       right))))
