#lang racket/base

(require racket/promise
         "../core/strings.rkt"
         "char.rkt"
         "list.rkt")

(provide string-value->string)

(define (lazy-apply function argument)
  ((force function) argument))

(define (string-value->string value)
  (apply
   string-append
   (list->host-list
    (lazy-apply raw-string-value value)
    char-value->string)))
