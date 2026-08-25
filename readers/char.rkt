#lang racket/base

(require racket/promise
         "../core/binary-nat.rkt"
         "../core/chars.rkt"
         "nat.rkt")

(provide char-value->integer
         char-value->string)

(define (lazy-apply function argument)
  ((force function) argument))

(define (char-value->integer value)
  (nat->integer
   (lazy-apply
    raw-make-nat
    (lazy-apply raw-char-value value))))

(define (supported-ascii-code? code)
  (or (memv code '(9 10 13))
      (<= 32 code 126)))

(define (char-value->string value)
  (define code
    (char-value->integer value))
  (if (supported-ascii-code? code)
      (string (integer->char code))
      (format "char:~a" code)))
