#lang racket/base

(require rackunit
         racket/list
         racket/promise
         "../core/byte.rkt"
         "../core/errors.rkt"
         "../core/int.rkt"
         "../core/lists.rkt"
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/rat.rkt"
         "../core/tags.rkt"
         (only-in "../core/typed-logic.rkt" TRUE)
         (only-in "../core/typed-rat.rkt" typed-rat-add)
         "../readers/bool.rkt"
         "../readers/byte.rkt"
         "../readers/error.rkt"
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

(define (exact->typed-rat exact)
  (apply2 raw-make-object
          rat-type
          (apply2 raw-make-rat
                  (apply2 raw-make-int
                          (if (negative? exact) raw-false raw-true)
                          (host-bits->raw
                           (for/list ([character
                                       (in-string
                                        (number->string
                                         (abs (numerator exact)) 2))])
                             (char=? character #\1))))
                  (host-bits->raw
                   (for/list ([character
                               (in-string
                                (number->string (denominator exact) 2))])
                     (char=? character #\1))))))

(define (typed-value? type value)
  (raw-boolean->boolean
   (apply2 raw-is-type type value)))

(define (object-tag value)
  (type-tag->integer
   (lazy-apply raw-object-type value)))

;; Every value 0 through 255 constructs, reads back, and converts to the
;; same whole Rat; no other value constructs.
(for ([code (in-list '(0 1 2 127 128 254 255))])
  (define byte-value
    (lazy-apply MAKE-BYTE (exact->typed-rat code)))
  (check-equal? (object-tag byte-value) 9)
  (check-equal? (byte-value->integer byte-value) code)
  (define back (lazy-apply BYTE-VALUE byte-value))
  (check-equal? (object-tag back) 7)
  (check-equal? (rat->number
                 (lazy-apply raw-object-value back))
                code))

;; Negative, fractional, and over-255 inputs are the InvalidByte Error.
(for ([bad (in-list '(-1 -255 1/2 255/2 256 65536))])
  (check-equal?
   (error-value->string
    (lazy-apply MAKE-BYTE (exact->typed-rat bad)))
   "INVALID-BYTE\n  -> MAKE-BYTE(result)"))

;; Wrong argument types are ordinary strict mismatches.
(check-equal?
 (error-value->string
  (lazy-apply MAKE-BYTE TRUE))
 "MAKE-BYTE(arg1 expected RAT got BOOL)")
(check-equal?
 (error-value->string
  (lazy-apply BYTE-VALUE TRUE))
 "BYTE-VALUE(arg1 expected BYTE got BOOL)")

;; Ordinary Rat arithmetic rejects Byte: Byte is data, not a number.
(define byte-65
  (lazy-apply MAKE-BYTE (exact->typed-rat 65)))
(check-equal?
 (error-value->string
  (apply2 typed-rat-add byte-65 (exact->typed-rat 1)))
 "ADD(arg1 expected RAT got BYTE)")

;; Comparisons agree with host comparison across boundaries.
(for* ([left-code (in-list '(0 1 64 255))]
       [right-code (in-list '(0 1 64 255))])
  (define left (lazy-apply MAKE-BYTE (exact->typed-rat left-code)))
  (define right (lazy-apply MAKE-BYTE (exact->typed-rat right-code)))
  (for ([case (in-list
               (list (list BYTE-EQ =)
                     (list BYTE-LT <)
                     (list BYTE-LTE <=)
                     (list BYTE-GT >)
                     (list BYTE-GTE >=)))])
    (define result (apply2 (first case) left right))
    (check-equal? (object-tag result) 1)
    (check-equal? (bool->boolean result)
                  ((second case) left-code right-code))))

;; Byte comparisons reject Char even though both carry binary payloads.
(check-equal?
 (error-value->string
  (apply2 BYTE-EQ byte-65 TRUE))
 "BYTE-EQ(arg2 expected BYTE got BOOL)")

;; Operations remain chains of unary lambdas.
(for ([function (in-list
                 (list MAKE-BYTE BYTE-VALUE))])
  (check-equal?
   (procedure-arity (lazy-force function))
   1))
(for ([function (in-list
                 (list BYTE-EQ BYTE-LT BYTE-LTE BYTE-GT BYTE-GTE))])
  (check-equal?
   (procedure-arity (lazy-force function))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force (lazy-apply function byte-65)))
   1))
