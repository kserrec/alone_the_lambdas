#lang racket/base

(require rackunit
         racket/list
         racket/promise
         "../core/binary-nat.rkt"
         "../core/int.rkt"
         "../core/lists.rkt"
         "../core/logic.rkt"
         "../core/rat.rkt"
         "../readers/int.rkt"
         "../readers/list.rkt"
         "../readers/rat.rkt"
         "../readers/raw-boolean.rkt"
         "helpers/lazy.rkt")

(define (apply2 function first-argument second-argument)
  (lazy-apply
   (lazy-apply function first-argument)
   second-argument))

(define (host-bits->raw bits)
  (foldr
   (lambda (bit tail)
     (apply2 raw-cons
             (if bit raw-true raw-false)
             tail))
   NIL
   bits))

(define (integer->raw-bits integer)
  (host-bits->raw
   (for/list ([character
               (in-string
                (number->string integer 2))])
     (char=? character #\1))))

(define (integer->int integer)
  (apply2 raw-make-int
          (if (negative? integer) raw-false raw-true)
          (integer->raw-bits (abs integer))))

(define (make-rat numerator denominator)
  (apply2 raw-make-rat
          (integer->int numerator)
          (integer->raw-bits denominator)))

(define (stored-numerator value)
  (int->integer (lazy-apply raw-rat-numerator value)))

(define (stored-denominator value)
  (for/fold ([total 0])
            ([bit (in-list
                   (list->host-list
                    (lazy-apply raw-rat-denominator value)
                    raw-boolean->boolean))])
    (+ (* total 2)
       (if bit 1 0))))

;; Construction reduces to lowest terms with a positive denominator, and
;; the reader observes the exact host rational.
(for* ([top (in-list '(-24 -7 -6 -5 -1 0 1 2 5 6 7 24 123456))]
       [bottom (in-list '(1 2 3 4 6 7 24 25 654321))])
  (define value (make-rat top bottom))
  (define expected (/ top bottom))
  (check-equal? (rat->number value) expected)
  (check-equal? (stored-numerator value) (numerator expected))
  (check-equal? (stored-denominator value) (denominator expected)))

;; Every zero is positive 0/1, including negative and non-normalized
;; spellings.
(for ([value (in-list
              (list (make-rat 0 1)
                    (make-rat 0 7)
                    (apply2 raw-make-rat
                            (apply2 raw-make-int
                                    raw-false
                                    (integer->raw-bits 0))
                            (integer->raw-bits 5))
                    (apply2 raw-make-rat
                            (integer->int 0)
                            (host-bits->raw '(#f #f #t #f)))))])
  (check-equal? (rat->number value) 0)
  (check-equal? (stored-numerator value) 0)
  (check-equal? (stored-denominator value) 1)
  (check-true
   (raw-boolean->boolean
    (lazy-apply raw-int-sign
                (lazy-apply raw-rat-numerator value)))))

;; A non-normalized denominator is normalized and reduced.
(let ([value (apply2 raw-make-rat
                     (integer->int 2)
                     (host-bits->raw '(#f #f #t #f #f)))])
  (check-equal? (rat->number value) 1/2)
  (check-equal? (stored-numerator value) 1)
  (check-equal? (stored-denominator value) 2))

;; Constants.
(check-equal? (rat->number raw-rat-zero) 0)
(check-equal? (stored-denominator raw-rat-zero) 1)
(check-equal? (rat->number raw-rat-one) 1)
(check-equal? (stored-denominator raw-rat-one) 1)

;; Constructor and selectors are chains of unary lambdas.
(check-equal?
 (procedure-arity (lazy-force raw-make-rat))
 1)
(check-equal?
 (procedure-arity
  (lazy-force
   (lazy-apply raw-make-rat (integer->int 3))))
 1)
(for ([function (in-list
                 (list raw-rat-numerator
                       raw-rat-denominator))])
  (check-equal?
   (procedure-arity (lazy-force function))
   1))

;; Step 34.2: ordinary rational operations, verified against Racket's
;; exact rational arithmetic through the one-way reader.

(define (exact->rat exact)
  (make-rat (numerator exact) (denominator exact)))

(define rational-operands
  '(-24 -7/3 -2 -3/2 -1 -1/2 -2/5 0 2/5 1/2 1 3/2 2 7/3 24 123456/7))

(for* ([left-exact (in-list rational-operands)]
       [right-exact (in-list rational-operands)])
  (define left (exact->rat left-exact))
  (define right (exact->rat right-exact))
  (define (binary-rat function)
    (apply2 function left right))
  (define (binary-boolean function)
    (raw-boolean->boolean (binary-rat function)))
  (check-equal? (rat->number (binary-rat raw-rat-add))
                (+ left-exact right-exact))
  (check-equal? (rat->number (binary-rat raw-rat-sub))
                (- left-exact right-exact))
  (check-equal? (rat->number (binary-rat raw-rat-mult))
                (* left-exact right-exact))
  (check-equal? (binary-boolean raw-rat-equal)
                (= left-exact right-exact))
  (check-equal? (binary-boolean raw-rat-less)
                (< left-exact right-exact))
  (check-equal? (binary-boolean raw-rat-less-equal)
                (<= left-exact right-exact))
  (check-equal? (binary-boolean raw-rat-greater)
                (> left-exact right-exact))
  (check-equal? (binary-boolean raw-rat-greater-equal)
                (>= left-exact right-exact)))

;; Unary operations, checks, and floor across signs and wholeness.
(for ([exact (in-list rational-operands)])
  (define value (exact->rat exact))
  (check-equal? (rat->number (lazy-apply raw-rat-negate value))
                (- exact))
  (check-equal? (rat->number (lazy-apply raw-rat-abs value))
                (abs exact))
  (check-equal? (rat->number (lazy-apply raw-rat-floor value))
                (floor exact))
  (check-equal? (stored-denominator
                 (lazy-apply raw-rat-floor value))
                1)
  (check-equal?
   (raw-boolean->boolean (lazy-apply raw-rat-is-zero value))
   (zero? exact))
  (check-equal?
   (raw-boolean->boolean (lazy-apply raw-rat-is-whole value))
   (integer? exact))
  (check-equal?
   (raw-boolean->boolean
    (lazy-apply raw-rat-is-nonnegative-whole value))
   (and (integer? exact) (>= exact 0))))

;; Zero-valued results are canonical positive 0/1.
(for ([value (in-list
              (list (apply2 raw-rat-add
                            (exact->rat 3/2)
                            (exact->rat -3/2))
                    (apply2 raw-rat-sub
                            (exact->rat 7/3)
                            (exact->rat 7/3))
                    (apply2 raw-rat-mult
                            (exact->rat -5/2)
                            (exact->rat 0))
                    (lazy-apply raw-rat-negate (exact->rat 0))))])
  (check-equal? (rat->number value) 0)
  (check-equal? (stored-denominator value) 1)
  (check-true
   (raw-boolean->boolean
    (lazy-apply raw-int-sign
                (lazy-apply raw-rat-numerator value)))))

;; Results are reduced: stored parts match Racket's canonical parts.
(for ([case (in-list '((1/6 1/3) (5/12 7/12) (-5/6 1/3) (3/4 -1/4)))])
  (define sum (apply2 raw-rat-add
                      (exact->rat (first case))
                      (exact->rat (second case))))
  (define expected (+ (first case) (second case)))
  (check-equal? (stored-numerator sum) (numerator expected))
  (check-equal? (stored-denominator sum) (denominator expected)))

;; Operations remain chains of unary lambdas.
(for ([function (in-list
                 (list raw-rat-add
                       raw-rat-sub
                       raw-rat-mult
                       raw-rat-equal
                       raw-rat-less
                       raw-rat-less-equal
                       raw-rat-greater
                       raw-rat-greater-equal))])
  (check-equal?
   (procedure-arity (lazy-force function))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force
     (lazy-apply function (exact->rat 1/2))))
   1))

(for ([function (in-list
                 (list raw-rat-negate
                       raw-rat-abs
                       raw-rat-floor
                       raw-rat-is-zero
                       raw-rat-is-whole
                       raw-rat-is-nonnegative-whole))])
  (check-equal?
   (procedure-arity (lazy-force function))
   1))
