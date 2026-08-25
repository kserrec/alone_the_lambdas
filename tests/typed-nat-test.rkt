#lang racket/base

(require rackunit
         racket/list
         racket/promise
         (only-in "../core/binary-nat.rkt"
                  raw-make-nat)
         "../core/errors.rkt"
         "../core/lists.rkt"
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/tags.rkt"
         (only-in "../core/typed-logic.rkt"
                  TRUE)
         "../core/typed-nat.rkt"
         "../readers/bool.rkt"
         "../readers/list.rkt"
         "../readers/nat.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/type-tag.rkt"
         "helpers/lazy.rkt")

(define (apply2 function first second)
  (lazy-apply
   (lazy-apply function first)
   second))

(define (host-bits->raw bits)
  (foldr
   (lambda (bit tail)
     (apply2 raw-cons
             (if bit raw-true raw-false)
             tail))
   NIL
   bits))

(define (integer->host-bits integer)
  (for/list ([character
              (in-string
               (number->string integer 2))])
    (char=? character #\1)))

(define (integer->nat integer)
  (lazy-apply
   raw-make-nat
   (host-bits->raw
    (integer->host-bits integer))))

(define (typed-value? type value)
  (raw-boolean->boolean
   (apply2 raw-is-type type value)))

(define (error-kind=? error kind)
  (raw-boolean->boolean
   (apply2
    raw-error-kind-equal
    (lazy-apply
     raw-error-root-kind
     (lazy-apply raw-error-root error))
    kind)))

(define (mismatch-details error)
  (lazy-apply
   raw-error-root-details
   (lazy-apply raw-error-root error)))

(define (frame->host frame)
  (list
   (type-tag->integer
    (lazy-apply
     raw-error-frame-argument-position
     frame))
   (type-tag->integer
    (lazy-apply
     raw-error-frame-expected-type
     frame))))

(define (error-frames->host error)
  (list->host-list
   (lazy-apply raw-error-frames error)
   frame->host))

(define (check-nat expected value)
  (check-true
   (typed-value? nat-type value))
  (check-equal? (nat->integer value)
                expected)
  (check-equal? (nat->host-bits value)
                (integer->host-bits expected)))

(define (check-bool expected value)
  (check-true
   (typed-value? bool-type value))
  (check-equal? (bool->boolean value)
                expected))

(define (check-mismatch error position)
  (define details
    (mismatch-details error))
  (check-true
   (error-kind=? error
                 type-mismatch-kind))
  (check-equal?
   (type-tag->integer
    (lazy-apply
     raw-type-mismatch-argument-position
     details))
   position)
  (check-equal?
   (type-tag->integer
    (lazy-apply
     raw-type-mismatch-expected-type
     details))
   3)
  (check-equal?
   (type-tag->integer
    (lazy-apply
     raw-type-mismatch-actual-type
     details))
   1)
  (check-equal? (error-frames->host error)
                (list
                 (list position 3))))

(define (check-bubbled error position)
  (check-true
   (error-kind=? error
                 invalid-nat-kind))
  (check-equal? (error-frames->host error)
                (list (list position 3))))

(define constants
  (list ZERO ONE TWO THREE FOUR FIVE
        SIX SEVEN EIGHT NINE TEN))

(for ([constant (in-list constants)]
      [expected (in-naturals)])
  (check-nat expected constant))

(for ([case (in-list
             '((0 1)
               (1 2)
               (7 8)
               (15 16)
               (255 256)
               (65535 65536)))])
  (check-nat
   (second case)
   (lazy-apply
    typed-nat-succ
    (integer->nat (first case)))))

(for ([case (in-list
             '((0 0 0)
               (0 19 19)
               (2 3 5)
               (15 17 32)
               (255 1 256)
               (12345 6789 19134)))])
  (check-nat
   (third case)
   (apply2 typed-nat-add
           (integer->nat (first case))
           (integer->nat (second case)))))

(for ([case (in-list
             '((0 0 0)
               (3 5 0)
               (8 1 7)
               (256 1 255)
               (1000 333 667)))])
  (check-nat
   (third case)
   (apply2 typed-nat-sub
           (integer->nat (first case))
           (integer->nat (second case)))))

(for ([case (in-list
             '((0 999 0)
               (1 37 37)
               (3 5 15)
               (12 12 144)
               (255 257 65535)))])
  (check-nat
   (third case)
   (apply2 typed-nat-mult
           (integer->nat (first case))
           (integer->nat (second case)))))

(define comparison-operations
  (list
   (list typed-nat-equal =)
   (list typed-nat-less <)
   (list typed-nat-less-equal <=)
   (list typed-nat-greater >)
   (list typed-nat-greater-equal >=)))

(define comparison-cases
  '((0 0)
    (0 1)
    (1 0)
    (7 7)
    (15 16)
    (16 15)
    (255 256)
    (654321 123456)))

(for* ([case (in-list comparison-cases)]
       [operation (in-list comparison-operations)])
  (define left (first case))
  (define right (second case))
  (check-bool
   ((second operation) left right)
   (apply2 (first operation)
           (integer->nat left)
           (integer->nat right))))

(check-bool #t
            (lazy-apply typed-nat-is-zero ZERO))
(check-bool #f
            (lazy-apply typed-nat-is-zero ONE))
(check-bool #f
            (lazy-apply typed-nat-is-zero
                        (integer->nat 65536)))

(check-nat 11
           (lazy-apply SUCC TEN))
(check-nat 7
           (apply2 ADD THREE FOUR))
(check-nat 0
           (apply2 SUB THREE FOUR))
(check-nat 12
           (apply2 MULT THREE FOUR))
(check-bool #t
            (apply2 EQ FOUR FOUR))
(check-bool #t
            (apply2 LT THREE FOUR))
(check-bool #t
            (apply2 LTE FOUR FOUR))
(check-bool #t
            (apply2 GT FOUR THREE))
(check-bool #t
            (apply2 GTE FOUR FOUR))
(check-bool #t
            (lazy-apply IS-ZERO ZERO))

(define unary-operations
  (list typed-nat-succ
        typed-nat-is-zero))

(define binary-operations
  (list typed-nat-add
        typed-nat-sub
        typed-nat-mult
        typed-nat-equal
        typed-nat-less
        typed-nat-less-equal
        typed-nat-greater
        typed-nat-greater-equal))

(for ([operation (in-list unary-operations)])
  (check-mismatch
   (lazy-apply operation TRUE)
   1)
  (check-bubbled
   (lazy-apply operation
               invalid-nat-error)
   1))

(for ([operation (in-list binary-operations)])
  (define wrong-first-partial
    (lazy-apply operation TRUE))
  (check-equal?
   (procedure-arity
    (lazy-force wrong-first-partial))
   1)
  (check-mismatch
   (lazy-apply
    wrong-first-partial
    (delay
      (error 'typed-nat
             "forced argument after first-position mismatch")))
   1)
  (check-mismatch
   (apply2 operation ONE TRUE)
   2)

  (define bubbled-first-partial
    (lazy-apply operation
                invalid-nat-error))
  (check-equal?
   (procedure-arity
    (lazy-force bubbled-first-partial))
   1)
  (check-bubbled
   (lazy-apply
    bubbled-first-partial
    (delay
      (error 'typed-nat
             "forced argument after first-position Error")))
   1)
  (check-bubbled
   (apply2 operation ONE invalid-nat-error)
   2))

(check-equal? (error-frames->host invalid-nat-error)
              '())

(define nested-root-error
  (apply2 typed-nat-add TRUE TWO))

(define nested-error
  (lazy-apply typed-nat-succ
              nested-root-error))

(define nested-details
  (mismatch-details nested-error))

(check-true
 (error-kind=? nested-error
               type-mismatch-kind))
(check-equal? (error-frames->host nested-error)
              '((1 3) (1 3)))
(check-equal?
 (type-tag->integer
  (lazy-apply
   raw-type-mismatch-argument-position
   nested-details))
 1)
(check-equal?
 (type-tag->integer
  (lazy-apply
   raw-type-mismatch-expected-type
   nested-details))
 3)
(check-equal?
 (type-tag->integer
  (lazy-apply
   raw-type-mismatch-actual-type
   nested-details))
 1)

(for ([operation (in-list
                  (append binary-operations
                          (list ADD SUB MULT
                                EQ LT LTE GT GTE)))])
  (check-equal?
   (procedure-arity
    (lazy-force operation))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force
     (lazy-apply operation ONE)))
   1))

(for ([operation (in-list
                  (append unary-operations
                          (list SUCC IS-ZERO)))])
  (check-equal?
   (procedure-arity
    (lazy-force operation))
   1))
