#lang racket/base

(require racket/promise
         "../core/byte.rkt"
         "list.rkt"
         "raw-boolean.rkt")

(provide byte-value->integer)

(define (lazy-apply function argument)
  ((force function) argument))

(define (byte-value->integer value)
  (for/fold ([total 0])
            ([bit (in-list
                   (list->host-list
                    (lazy-apply raw-byte-value value)
                    raw-boolean->boolean))])
    (+ (* total 2)
       (if bit 1 0))))
