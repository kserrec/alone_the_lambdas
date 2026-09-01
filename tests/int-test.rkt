#lang racket/base

(require rackunit
         racket/list
         racket/promise
         "../core/binary-nat.rkt"
         "../core/int.rkt"
         "../core/lists.rkt"
         "../core/logic.rkt"
         "../readers/int.rkt"
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

(define (make-int negative? magnitude)
  (apply2 raw-make-int
          (if negative? raw-false raw-true)
          (integer->raw-bits magnitude)))

(define (integer->int integer)
  (make-int (negative? integer) (abs integer)))

(define (int-sign-nonnegative? value)
  (raw-boolean->boolean
   (lazy-apply raw-int-sign value)))

;; Constructor canonicalization: sign and magnitude round-trip, and the
;; reader observes the signed value.
(for ([integer (in-list '(0 1 -1 2 -2 7 -7 255 -255 65536 -65536
                          123456 -654321))])
  (define value (integer->int integer))
  (check-equal? (int->integer value) integer)
  (check-equal? (int-sign-nonnegative? value)
                (>= integer 0)))

;; Negative zero cannot be constructed: a false sign with a zero magnitude
;; becomes positive zero, including through non-normalized zero spellings.
(define negative-zero-attempt
  (apply2 raw-make-int raw-false (integer->raw-bits 0)))

(check-equal? (int->integer negative-zero-attempt) 0)
(check-true (int-sign-nonnegative? negative-zero-attempt))

(define non-normalized-negative-zero
  (apply2 raw-make-int raw-false (host-bits->raw '(#f #f #f))))

(check-equal? (int->integer non-normalized-negative-zero) 0)
(check-true (int-sign-nonnegative? non-normalized-negative-zero))

(define empty-negative-zero
  (apply2 raw-make-int raw-false NIL))

(check-equal? (int->integer empty-negative-zero) 0)
(check-true (int-sign-nonnegative? empty-negative-zero))

;; A non-normalized nonzero magnitude is normalized by construction.
(define non-normalized-negative-two
  (apply2 raw-make-int raw-false (host-bits->raw '(#f #f #t #f))))

(check-equal? (int->integer non-normalized-negative-two) -2)
(check-equal?
 (raw-boolean->boolean
  (lazy-apply raw-list-head
              (lazy-apply raw-int-magnitude
                          non-normalized-negative-two)))
 #t)

;; Constants.
(check-equal? (int->integer raw-int-zero) 0)
(check-true (int-sign-nonnegative? raw-int-zero))
(check-equal? (int->integer raw-int-one) 1)

;; Zero test.
(for ([case (in-list '((0 #t) (1 #f) (-1 #f) (255 #f) (-255 #f)))])
  (check-equal?
   (raw-boolean->boolean
    (lazy-apply raw-int-is-zero
                (integer->int (first case))))
   (second case)))

;; Negation and absolute value, including the zero results that must come
;; back as positive zero.
(for ([integer (in-list '(0 1 -1 5 -5 255 -255 65536 -65536))])
  (define value (integer->int integer))
  (check-equal? (int->integer (lazy-apply raw-int-negate value))
                (- integer))
  (check-equal? (int->integer (lazy-apply raw-int-abs value))
                (abs integer)))

(check-true
 (int-sign-nonnegative?
  (lazy-apply raw-int-negate (integer->int 0))))
(check-true
 (int-sign-nonnegative?
  (lazy-apply raw-int-abs (integer->int 0))))

;; Double negation restores the value; negation then abs is abs.
(for ([integer (in-list '(3 -3 0 100 -100))])
  (define value (integer->int integer))
  (check-equal?
   (int->integer
    (lazy-apply raw-int-negate
                (lazy-apply raw-int-negate value)))
   integer)
  (check-equal?
   (int->integer
    (lazy-apply raw-int-abs
                (lazy-apply raw-int-negate value)))
   (abs integer)))

;; Every Int operation is a chain of unary lambdas.
(check-equal?
 (procedure-arity (lazy-force raw-make-int))
 1)
(check-equal?
 (procedure-arity
  (lazy-force (lazy-apply raw-make-int raw-true)))
 1)
(for ([function (in-list
                 (list raw-int-sign
                       raw-int-magnitude
                       raw-int-is-zero
                       raw-int-negate
                       raw-int-abs))])
  (check-equal?
   (procedure-arity (lazy-force function))
   1))
