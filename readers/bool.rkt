#lang racket/base

(require racket/promise
         "../core/objects.rkt"
         "raw-boolean.rkt")

(provide bool->boolean)

(define (lazy-apply function argument)
  ((force function) argument))

(define (bool->boolean value)
  (raw-boolean->boolean
   (lazy-apply raw-object-value value)))
