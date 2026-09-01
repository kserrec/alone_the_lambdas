#lang racket/base

(require racket/promise
         "../core/typed-nat.rkt"
         "list.rkt"
         "raw-boolean.rkt")

(provide nat->host-bits
         nat->integer)

(define (lazy-apply function argument)
  ((force function) argument))

(define (nat->host-bits nat)
  (list->host-list
   (lazy-apply raw-nat-value nat)
   raw-boolean->boolean))

(define (nat->integer nat)
  (for/fold ([total 0])
            ([bit (in-list
                   (nat->host-bits nat))])
    (+ (* total 2)
       (if bit 1 0))))
