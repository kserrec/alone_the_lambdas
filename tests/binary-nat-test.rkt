#lang racket/base

(require rackunit
         racket/list
         racket/promise
         "../core/binary-nat.rkt"
         "../core/lists.rkt"
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/tags.rkt"
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

(define (integer->raw-bits integer)
  (host-bits->raw
   (integer->host-bits integer)))

(define (raw-bits->nat bits)
  (apply2 raw-make-object nat-type bits))

(define (raw-bits->integer bits)
  (nat->integer
   (raw-bits->nat bits)))

(define (raw-bits->host-bits bits)
  (nat->host-bits
   (raw-bits->nat bits)))

(define (check-canonical expected actual)
  (check-equal? (raw-bits->integer actual)
                expected)
  (check-equal? (raw-bits->host-bits actual)
                (integer->host-bits expected)))

(define (raw-boolean-result function left right)
  (raw-boolean->boolean
   (apply2 function left right)))

(define leading-zero-two
  (host-bits->raw
   '(#f #f #t #f)))

(define all-zeroes
  (host-bits->raw
   '(#f #f #f)))

(check-canonical 0
                 (lazy-apply raw-normalize-nat NIL))
(check-canonical 0
                 (lazy-apply raw-normalize-nat all-zeroes))
(check-canonical 2
                 (lazy-apply raw-normalize-nat
                             leading-zero-two))

(define normalized-empty-nat
  (lazy-apply raw-make-nat NIL))

(define normalized-two-nat
  (lazy-apply raw-make-nat leading-zero-two))

(check-equal?
 (type-tag->integer
  (lazy-apply raw-object-type
              normalized-empty-nat))
 3)
(check-equal? (nat->host-bits normalized-empty-nat)
              '(#f))
(check-equal? (nat->integer normalized-two-nat)
              2)
(check-equal? (nat->host-bits normalized-two-nat)
              '(#t #f))

(define constants
  (list ZERO ONE TWO THREE FOUR FIVE
        SIX SEVEN EIGHT NINE TEN))

(for ([constant (in-list constants)]
      [expected (in-naturals)])
  (check-equal?
   (type-tag->integer
    (lazy-apply raw-object-type constant))
   3)
  (check-equal? (nat->integer constant)
                expected)
  (check-equal? (nat->host-bits constant)
                (integer->host-bits expected)))

(check-true
 (raw-boolean->boolean
  (lazy-apply raw-nat-is-zero NIL)))
(check-true
 (raw-boolean->boolean
  (lazy-apply raw-nat-is-zero all-zeroes)))
(check-false
 (raw-boolean->boolean
  (lazy-apply raw-nat-is-zero
              (integer->raw-bits 1))))

(for ([case (in-list
             '((0 1)
               (1 2)
               (3 4)
               (7 8)
               (15 16)
               (255 256)
               (65535 65536)))])
  (check-canonical
   (second case)
   (lazy-apply raw-nat-succ
               (integer->raw-bits
                (first case)))))

(for ([case (in-list
             '((0 0 0)
               (0 19 19)
               (1 1 2)
               (7 1 8)
               (15 17 32)
               (255 1 256)
               (4095 4097 8192)
               (123456 654321 777777)))])
  (check-canonical
   (third case)
   (apply2 raw-nat-add
           (integer->raw-bits (first case))
           (integer->raw-bits (second case)))))

(check-canonical
 3
 (apply2 raw-nat-add
         leading-zero-two
         (integer->raw-bits 1)))

(for ([case (in-list
             '((0 0 0)
               (1 0 1)
               (3 5 0)
               (8 1 7)
               (16 7 9)
               (256 1 255)
               (1000 333 667)
               (65536 1 65535)))])
  (check-canonical
   (third case)
   (apply2 raw-nat-sub
           (integer->raw-bits (first case))
           (integer->raw-bits (second case)))))

(for ([case (in-list
             '((0 0 0)
               (0 999 0)
               (1 37 37)
               (3 5 15)
               (12 12 144)
               (255 257 65535)
               (12345 6789 83810205)))])
  (check-canonical
   (third case)
   (apply2 raw-nat-mult
           (integer->raw-bits (first case))
           (integer->raw-bits (second case)))))

(define comparison-cases
  '((0 0)
    (0 1)
    (1 0)
    (1 1)
    (2 3)
    (3 2)
    (7 8)
    (8 7)
    (15 16)
    (16 15)
    (255 256)
    (256 255)
    (65535 65535)
    (123456 654321)
    (654321 123456)))

(for ([case (in-list comparison-cases)])
  (define left-integer (first case))
  (define right-integer (second case))
  (define left (integer->raw-bits left-integer))
  (define right (integer->raw-bits right-integer))
  (check-equal?
   (raw-boolean-result raw-nat-equal left right)
   (= left-integer right-integer))
  (check-equal?
   (raw-boolean-result raw-nat-less left right)
   (< left-integer right-integer))
  (check-equal?
   (raw-boolean-result raw-nat-less-equal left right)
   (<= left-integer right-integer))
  (check-equal?
   (raw-boolean-result raw-nat-greater left right)
   (> left-integer right-integer))
  (check-equal?
   (raw-boolean-result raw-nat-greater-equal left right)
   (>= left-integer right-integer)))

(check-true
 (raw-boolean-result
  raw-nat-equal
  leading-zero-two
  (integer->raw-bits 2)))

(define rejected-tail-payload
  (apply2
   raw-make-object
   list-type
   (delay
     (error 'raw-normalize-nat
            "forced payload after canonical leading one"))))

(define leading-one-with-rejected-tail-payload
  (apply2
   raw-cons
   raw-true
   rejected-tail-payload))

(check-true
 (raw-boolean->boolean
  (lazy-apply
   raw-list-head
   (lazy-apply raw-normalize-nat
               leading-one-with-rejected-tail-payload))))

(check-canonical
 0
 (apply2
  raw-nat-mult
  (delay
    (error 'raw-nat-mult
           "forced multiplicand while multiplying by zero"))
  (integer->raw-bits 0)))

(for ([function (in-list
                 (list raw-normalize-nat
                       raw-nat-is-zero
                       raw-nat-succ
                       raw-make-nat
                       raw-nat-value))])
  (check-equal?
   (procedure-arity
    (lazy-force function))
   1))

(for ([function (in-list
                 (list raw-nat-add
                       raw-nat-sub
                       raw-nat-mult
                       raw-nat-equal
                       raw-nat-less
                       raw-nat-less-equal
                       raw-nat-greater
                       raw-nat-greater-equal))])
  (check-equal?
   (procedure-arity
    (lazy-force function))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force
     (lazy-apply function
                 (integer->raw-bits 1))))
   1))
