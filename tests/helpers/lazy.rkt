#lang racket/base

(require racket/promise)

(provide lazy-apply
         lazy-force)

(define (lazy-apply function argument)
  ((force function) argument))

(define (lazy-force value)
  (force value))
