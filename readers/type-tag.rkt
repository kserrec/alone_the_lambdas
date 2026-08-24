#lang racket/base

(require racket/promise)

(provide type-tag->integer)

(define (lazy-apply function argument)
  ((force function) argument))

(define (type-tag->integer type-tag)
  (force
   (lazy-apply
    (lazy-apply type-tag add1)
    0)))
