#lang racket/base

(require racket/promise
         "../core/lists.rkt"
         "bool.rkt")

(provide list->host-list)

(define (lazy-apply function argument)
  ((force function) argument))

(define (list->host-list value read-value)
  (let loop ([remaining value])
    (if (bool->boolean
         (lazy-apply typed-is-nil remaining))
        '()
        (cons
         (read-value
          (lazy-apply typed-head remaining))
         (loop
          (lazy-apply typed-tail remaining))))))
