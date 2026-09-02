#lang racket/base

(require racket/promise
         "../core/objects.rkt"
         "type-tag.rkt")

(provide unit->string)

(define (lazy-apply function argument)
  ((force function) argument))

(define (unit->string value)
  (type-tag->string
   (lazy-apply raw-object-type value)))
