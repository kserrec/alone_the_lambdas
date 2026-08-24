#lang racket/base

(require racket/promise
         "../core/lists.rkt"
         "raw-boolean.rkt")

(provide list->host-list)

(define (lazy-apply function argument)
  ((force function) argument))

(define (list->host-list list read-value)
  (let loop ([remaining list])
    (if (raw-boolean->boolean
         (lazy-apply typed-is-nil remaining))
        '()
        (cons
         (read-value
          (lazy-apply typed-head remaining))
         (loop
          (lazy-apply typed-tail remaining))))))
