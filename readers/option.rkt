#lang racket/base

(require racket/promise
         "../core/objects.rkt"
         "../core/option.rkt"
         "raw-boolean.rkt")

(provide option->string)

(define (lazy-apply function argument)
  ((force function) argument))

(define (option->string value)
  (if (raw-boolean->boolean
       (lazy-apply raw-option-is-some
                   (lazy-apply raw-object-value value)))
      "SOME"
      "NONE"))
