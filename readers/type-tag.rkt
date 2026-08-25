#lang racket/base

(require racket/promise)

(provide type-tag->integer
         type-tag->string)

(define (lazy-apply function argument)
  ((force function) argument))

(define (type-tag->integer type-tag)
  (force
   (lazy-apply
    (lazy-apply type-tag add1)
    0)))

(define (type-tag->string type-tag)
  (case (type-tag->integer type-tag)
    [(0) "ERROR"]
    [(1) "BOOL"]
    [(2) "LIST"]
    [(3) "NAT"]
    [(4) "RESULT"]
    [(5) "CHAR"]
    [(6) "STRING"]
    [else
     (format "TYPE:~a"
             (type-tag->integer type-tag))]))
