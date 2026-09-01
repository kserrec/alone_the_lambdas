#lang racket/base

(require racket/promise
         "../core/rat.rkt"
         "int.rkt"
         "list.rkt"
         "raw-boolean.rkt")

(provide rat->number)

(define (lazy-apply function argument)
  ((force function) argument))

(define (rat->number value)
  (define total
    (for/fold ([total 0])
              ([bit (in-list
                     (list->host-list
                      (lazy-apply raw-rat-denominator value)
                      raw-boolean->boolean))])
      (+ (* total 2)
         (if bit 1 0))))
  (/ (int->integer
      (lazy-apply raw-rat-numerator value))
     total))
