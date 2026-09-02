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
  (define tag-number
    (type-tag->integer type-tag))
  (case tag-number
    [(0) "ERROR"]
    [(1) "BOOL"]
    [(2) "LIST"]
    [(4) "RESULT"]
    [(5) "CHAR"]
    [(6) "STRING"]
    [(7) "RAT"]
    [(8) "UNIT"]
    [(9) "BYTE"]
    [else
     (format "TYPE:~a"
             tag-number)]))
