#lang racket/base

(require rackunit
         racket/list
         racket/promise
         "../core/errors.rkt"
         "../core/int.rkt"
         "../core/lists.rkt"
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/rat.rkt"
         "../core/result.rkt"
         "../core/tags.rkt"
         "../core/typed-rat.rkt"
         (only-in "../core/typed-logic.rkt"
                  TRUE
                  FALSE)
         "../readers/bool.rkt"
         "../readers/error.rkt"
         "../readers/int.rkt"
         "../readers/list.rkt"
         "../readers/rat.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/type-tag.rkt"
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

(define (exact->typed-rat exact)
  (apply2 raw-make-object
          rat-type
          (apply2 raw-make-rat
                  (integer->int (numerator exact))
                  (integer->raw-bits (denominator exact)))))

(define (object-tag value)
  (type-tag->integer
   (lazy-apply raw-object-type value)))

(define (typed-rat->number value)
  (rat->number
   (lazy-apply raw-object-value value)))

(define (typed-bool->boolean value)
  (bool->boolean value))

(define (result-payload result)
  (lazy-apply raw-object-value result))

(define (result-ok? result)
  (raw-boolean->boolean
   (lazy-apply raw-result-is-ok
               (result-payload result))))

;; The raw Result payload for Ok carries a tagged Rat; unwrap it directly.
(define (ok-value->number result)
  (rat->number
   (lazy-apply raw-object-value
               (lazy-apply raw-result-value
                           (result-payload result)))))

(define rational-values
  '(-24 -7/3 -3/2 -1 -1/2 0 1/2 1 3/2 7/3 24))

;; Successful strict operations return correctly tagged canonical values.
(for* ([left-exact (in-list '(-7/3 -1 0 1/2 3/2 24))]
       [right-exact (in-list '(-7/3 -1 0 1/2 3/2 24))])
  (define left (exact->typed-rat left-exact))
  (define right (exact->typed-rat right-exact))
  (for ([case (in-list
               (list (list typed-rat-add +)
                     (list typed-rat-sub -)
                     (list typed-rat-mult *)))])
    (define result (apply2 (first case) left right))
    (check-equal? (object-tag result) 7)
    (check-equal? (typed-rat->number result)
                  ((second case) left-exact right-exact)))
  (for ([case (in-list
               (list (list typed-rat-equal =)
                     (list typed-rat-less <)
                     (list typed-rat-less-equal <=)
                     (list typed-rat-greater >)
                     (list typed-rat-greater-equal >=)))])
    (define result (apply2 (first case) left right))
    (check-equal? (object-tag result) 1)
    (check-equal? (typed-bool->boolean result)
                  ((second case) left-exact right-exact))))

(for ([exact (in-list rational-values)])
  (define value (exact->typed-rat exact))
  (check-equal? (typed-rat->number (lazy-apply typed-rat-succ value))
                (add1 exact))
  (check-equal? (typed-rat->number (lazy-apply typed-rat-negate value))
                (- exact))
  (check-equal? (typed-rat->number (lazy-apply typed-rat-abs value))
                (abs exact))
  (check-equal? (typed-rat->number (lazy-apply typed-rat-floor value))
                (floor exact))
  (check-equal? (typed-bool->boolean
                 (lazy-apply typed-rat-is-zero value))
                (zero? exact))
  (check-equal? (typed-bool->boolean
                 (lazy-apply typed-rat-is-whole value))
                (integer? exact))
  (check-equal? (typed-bool->boolean
                 (lazy-apply typed-rat-is-nonnegative-whole value))
                (and (integer? exact) (>= exact 0))))

;; Division, reciprocal, and powers keep their already-typed Result.
(let ([result (apply2 typed-rat-div
                      (exact->typed-rat 7/3)
                      (exact->typed-rat -1/2))])
  (check-equal? (object-tag result) 4)
  (check-true (result-ok? result))
  (check-equal? (ok-value->number result) -14/3))

(let ([result (apply2 typed-rat-div
                      (exact->typed-rat 1)
                      (exact->typed-rat 0))])
  (check-equal? (object-tag result) 4)
  (check-false (result-ok? result)))

(let ([result (lazy-apply typed-rat-recip
                          (exact->typed-rat -2/5))])
  (check-true (result-ok? result))
  (check-equal? (ok-value->number result) -5/2))

(let ([result (apply2 typed-rat-exp
                      (exact->typed-rat -3/2)
                      (exact->typed-rat 5))])
  (check-true (result-ok? result))
  (check-equal? (ok-value->number result) -243/32))

(let ([result (apply2 typed-rat-exp
                      (exact->typed-rat 4/9)
                      (exact->typed-rat 1/2))])
  (check-equal? (object-tag result) 4)
  (check-false (result-ok? result)))

;; Wrong argument types produce structured Errors with the operation's
;; function name, and the checker's frames render as with every other tag.
(check-equal?
 (error-value->string
  (apply2 typed-rat-add TRUE (exact->typed-rat 1)))
 "ADD(arg1 expected RAT got BOOL)")

(check-equal?
 (error-value->string
  (apply2 typed-rat-add (exact->typed-rat 1) FALSE))
 "ADD(arg2 expected RAT got BOOL)")

(check-equal?
 (error-value->string
  (lazy-apply typed-rat-recip TRUE))
 "RECIP(arg1 expected RAT got BOOL)")

(check-equal?
 (error-value->string
  (apply2 typed-rat-exp TRUE (exact->typed-rat 2)))
 "EXP(arg1 expected RAT got BOOL)")

(check-equal?
 (error-value->string
  (lazy-apply typed-rat-is-nonnegative-whole TRUE))
 "IS-NONNEGATIVE-WHOLE(arg1 expected RAT got BOOL)")

;; An incoming Error bubbles with a new frame instead of being replaced.
(let ([bubbled
       (apply2 typed-rat-mult
               (apply2 typed-rat-add TRUE (exact->typed-rat 1))
               (exact->typed-rat 2))])
  (check-equal? (object-tag bubbled) 0)
  (check-equal?
   (error-value->string bubbled)
   "ADD(arg1 expected RAT got BOOL)\n  -> MULT(arg1 expected RAT)"))

;; Failure on the first argument still absorbs the remaining arity.
(let ([absorbed (lazy-apply typed-rat-add TRUE)])
  (check-equal?
   (procedure-arity (lazy-force absorbed))
   1))

;; Strict operations remain chains of unary lambdas.
(for ([function (in-list
                 (list typed-rat-succ
                       typed-rat-add
                       typed-rat-sub
                       typed-rat-mult
                       typed-rat-div
                       typed-rat-exp
                       typed-rat-recip
                       typed-rat-negate
                       typed-rat-abs
                       typed-rat-floor
                       typed-rat-equal
                       typed-rat-less
                       typed-rat-less-equal
                       typed-rat-greater
                       typed-rat-greater-equal
                       typed-rat-is-zero
                       typed-rat-is-whole
                       typed-rat-is-nonnegative-whole))])
  (check-equal?
   (procedure-arity (lazy-force function))
   1))
