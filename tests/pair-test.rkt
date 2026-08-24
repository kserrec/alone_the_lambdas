#lang racket/base

(require rackunit
         racket/promise
         "../core/pair.rkt"
         "helpers/lazy.rkt")

(define left-value (gensym 'left))
(define right-value (gensym 'right))

(define pair-value
  (lazy-apply
   (lazy-apply raw-pair left-value)
   right-value))

(check-eq? (lazy-force
            (lazy-apply raw-first pair-value))
           left-value)
(check-eq? (lazy-force
            (lazy-apply raw-second pair-value))
           right-value)

(define first-lazy-pair
  (lazy-apply
   (lazy-apply raw-pair left-value)
   (delay (error 'raw-first "forced second field"))))

(check-eq? (lazy-force
            (lazy-apply raw-first first-lazy-pair))
           left-value)

(define second-lazy-pair
  (lazy-apply
   (lazy-apply raw-pair
               (delay (error 'raw-second "forced first field")))
   right-value))

(check-eq? (lazy-force
            (lazy-apply raw-second second-lazy-pair))
           right-value)
