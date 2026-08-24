#lang racket/base

(require rackunit
         racket/promise
         "../core/logic.rkt"
         "../readers/raw-boolean.rkt"
         "helpers/lazy.rkt")

(define (raw-unary operation value)
  (lazy-apply operation
              (lazy-force value)))

(define (raw-binary operation left right)
  (lazy-apply
   (lazy-apply operation
               (lazy-force left))
   (lazy-force right)))

(define (raw-if-value condition then-value else-value)
  (lazy-force
   (lazy-apply
    (lazy-apply
     (lazy-apply raw-if
                 (lazy-force condition))
     then-value)
    else-value)))

(define (observed-unary operation value)
  (raw-boolean->boolean
   (raw-unary operation value)))

(define (observed-binary operation left right)
  (raw-boolean->boolean
   (raw-binary operation left right)))

(check-true (raw-boolean->boolean raw-true))
(check-false (raw-boolean->boolean raw-false))

(check-false (observed-unary raw-not raw-true))
(check-true (observed-unary raw-not raw-false))

(check-true (observed-binary raw-and raw-true raw-true))
(check-false (observed-binary raw-and raw-true raw-false))
(check-false (observed-binary raw-and raw-false raw-true))
(check-false (observed-binary raw-and raw-false raw-false))

(check-true (observed-binary raw-or raw-true raw-true))
(check-true (observed-binary raw-or raw-true raw-false))
(check-true (observed-binary raw-or raw-false raw-true))
(check-false (observed-binary raw-or raw-false raw-false))

(check-false (observed-binary raw-xor raw-true raw-true))
(check-true (observed-binary raw-xor raw-true raw-false))
(check-true (observed-binary raw-xor raw-false raw-true))
(check-false (observed-binary raw-xor raw-false raw-false))

(check-equal? (raw-if-value raw-true
                            'then
                            'else)
              'then)
(check-equal? (raw-if-value raw-false
                            'then
                            'else)
              'else)

(check-equal? (raw-if-value raw-true
                            'selected
                            (delay (error 'raw-if "forced unselected branch")))
              'selected)
(check-equal? (raw-if-value raw-false
                            (delay (error 'raw-if "forced unselected branch"))
                            'selected)
              'selected)
