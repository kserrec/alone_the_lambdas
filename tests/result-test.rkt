#lang racket/base

(require rackunit
         racket/list
         racket/promise
         "../core/errors.rkt"
         "../core/lists.rkt"
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/result.rkt"
         "../core/tags.rkt"
         (only-in "../core/typed-logic.rkt"
                  FALSE
                  TRUE)
         "../core/rat.rkt"
         "../core/typed-rat.rkt"
         "../readers/bool.rkt"
         "../readers/list.rkt"
         "../readers/rat.rkt"
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
  (apply2 raw-make-object
          rat-type
          (lazy-apply
           raw-whole-rat
           (host-bits->raw
            (integer->host-bits integer)))))

(define ZERO (integer->nat 0))
(define ONE (integer->nat 1))
(define THREE (integer->nat 3))
(define SEVEN (integer->nat 7))
(define TEN (integer->nat 10))

(define DIV typed-rat-div)
(define SUCC typed-rat-succ)

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
   (typed-value? rat-type value))
  (check-equal? (rat->number
                 (lazy-apply raw-object-value value))
                expected)
  (check-equal? (list->host-list
                 (lazy-apply raw-rat-magnitude-bits
                             (lazy-apply raw-object-value value))
                 raw-boolean->boolean)
                (integer->host-bits expected)))

(define (check-result-case expected-ok? result)
  (check-true
   (typed-value? result-type result))
  (check-equal?
   (bool->boolean
    (lazy-apply is-ok result))
   expected-ok?)
  (check-equal?
   (bool->boolean
    (lazy-apply is-err result))
   (not expected-ok?)))

(define (check-mismatch error position expected-type actual-type)
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
   expected-type)
  (check-equal?
   (type-tag->integer
    (lazy-apply
     raw-type-mismatch-actual-type
     details))
   actual-type)
  (check-equal? (error-frames->host error)
                (list
                 (list position expected-type))))

(define (check-bubbled error position expected-type)
  (check-true
   (error-kind=? error
                 invalid-nat-kind))
  (check-equal? (error-frames->host error)
                (list
                 (list position expected-type))))

(define ok-seven
  (lazy-apply make-ok SEVEN))

(check-result-case #t ok-seven)
(check-nat 7
           (lazy-apply unwrap-ok ok-seven))

(define internal-ok-three
  (lazy-apply typed-make-ok THREE))

(check-result-case #t internal-ok-three)
(check-nat 3
           (lazy-apply
            typed-result-unwrap-ok
            internal-ok-three))

(define err-invalid-nat
  (lazy-apply make-err
              invalid-nat-error))

(check-result-case #f err-invalid-nat)

(define unwrapped-invalid-nat
  (lazy-apply unwrap-err
              err-invalid-nat))

(check-true
 (typed-value? error-type
               unwrapped-invalid-nat))
(check-true
 (error-kind=? unwrapped-invalid-nat
               invalid-nat-kind))
(check-equal? (error-frames->host
               unwrapped-invalid-nat)
              '())

(define internal-err
  (lazy-apply typed-make-err
              divide-by-zero-error))

(check-result-case #f internal-err)
(check-true
 (error-kind=?
  (lazy-apply typed-result-unwrap-err
              internal-err)
  divide-by-zero-kind))

(define (check-wrong-variant error)
  (check-true
   (typed-value? error-type error))
  (check-true
   (error-kind=? error
                 wrong-result-variant-kind))
  (check-equal? (error-frames->host error)
                '((0 0))))

(check-wrong-variant
 (lazy-apply unwrap-ok err-invalid-nat))
(check-wrong-variant
 (lazy-apply unwrap-err ok-seven))
(check-wrong-variant
 (lazy-apply typed-result-unwrap-ok internal-err))
(check-wrong-variant
 (lazy-apply typed-result-unwrap-err internal-ok-three))

(define wrong-variant-then-succ
  (lazy-apply SUCC
              (lazy-apply unwrap-err ok-seven)))

(check-true
 (error-kind=? wrong-variant-then-succ
               wrong-result-variant-kind))
(check-equal? (error-frames->host wrong-variant-then-succ)
              '((1 7) (0 0)))

(define propagated-ok-input
  (lazy-apply make-ok
              invalid-nat-error))

(check-true
 (typed-value? error-type
               propagated-ok-input))
(check-true
 (error-kind=? propagated-ok-input
               invalid-nat-kind))
(check-equal? (error-frames->host
               propagated-ok-input)
              '())

(check-mismatch
 (lazy-apply make-err TRUE)
 1
 0
 1)

(define result-accessors
  (list is-ok
        is-err
        unwrap-ok
        unwrap-err
        typed-result-is-ok
        typed-result-is-err
        typed-result-unwrap-ok
        typed-result-unwrap-err))

(for ([accessor (in-list result-accessors)])
  (check-mismatch
   (lazy-apply accessor TRUE)
   1
   4
   1)
  (check-bubbled
   (lazy-apply accessor
               invalid-nat-error)
   1
   4))

(check-equal? (error-frames->host
               invalid-nat-error)
              '())

(define lazy-nat
  (apply2
   raw-make-object
   rat-type
   (delay
     (error 'result
            "forced Ok payload"))))

(define lazy-ok
  (lazy-apply make-ok lazy-nat))

(check-true
 (bool->boolean
  (lazy-apply is-ok lazy-ok)))
(check-false
 (bool->boolean
  (lazy-apply is-err lazy-ok)))

(for ([function (in-list
                 (append result-accessors
                         (list make-ok
                               make-err
                               typed-make-ok
                               typed-make-err)))])
  (check-equal?
   (procedure-arity
    (lazy-force function))
   1))

;; Public division is exact rational division since the Step 35.5 switch.
(define division-cases
  '((0 1)
    (1 1)
    (1 2)
    (7 2)
    (8 2)
    (15 4)
    (255 16)
    (256 16)
    (65535 255)
    (654321 123)))

(for ([case (in-list division-cases)])
  (define dividend (first case))
  (define divisor (second case))
  (define result
    (apply2 DIV
            (integer->nat dividend)
            (integer->nat divisor)))
  (check-result-case #t result)
  (define quotient-value
    (lazy-apply unwrap-ok result))
  (check-true
   (typed-value? rat-type quotient-value))
  (check-equal?
   (rat->number
    (lazy-apply raw-object-value quotient-value))
   (/ dividend divisor)))

(for ([dividend (in-list '(0 1 999 65535))])
  (define result
    (apply2 typed-rat-div
            (integer->nat dividend)
            ZERO))
  (check-result-case #f result)
  (define failure
    (lazy-apply unwrap-err result))
  (check-true
   (typed-value? error-type failure))
  (check-true
   (error-kind=? failure
                 divide-by-zero-kind))
  (check-equal? (error-frames->host failure)
                '()))

(define wrong-first-partial
  (lazy-apply DIV TRUE))

(check-equal?
 (procedure-arity
  (lazy-force wrong-first-partial))
 1)

(check-mismatch
 (lazy-apply
  wrong-first-partial
  (delay
    (error 'result
           "forced argument after first DIV mismatch")))
 1
 7
 1)

(check-mismatch
 (apply2 DIV ONE FALSE)
 2
 7
 1)

(define bubbled-first-partial
  (lazy-apply DIV invalid-nat-error))

(check-equal?
 (procedure-arity
  (lazy-force bubbled-first-partial))
 1)

(check-bubbled
 (lazy-apply
  bubbled-first-partial
  (delay
    (error 'result
           "forced argument after first DIV Error")))
 1
 7)

(check-bubbled
 (apply2 DIV ONE invalid-nat-error)
 2
 7)

(define lazy-dividend
  (apply2
   raw-make-object
   rat-type
   (delay
     (error 'result
            "forced dividend bits for zero divisor"))))

(define lazy-zero-result
  (apply2 DIV lazy-dividend ZERO))

(check-result-case #f lazy-zero-result)
(check-true
 (error-kind=?
  (lazy-apply unwrap-err
              lazy-zero-result)
  divide-by-zero-kind))

(define zero-result
  (apply2 DIV TEN ZERO))

(define explicitly-unwrapped-error
  (lazy-apply unwrap-err zero-result))

(define later-propagated-error
  (lazy-apply SUCC
              explicitly-unwrapped-error))

(check-true
 (error-kind=? later-propagated-error
               divide-by-zero-kind))
(check-equal? (error-frames->host
               explicitly-unwrapped-error)
              '())
(check-equal? (error-frames->host
               later-propagated-error)
              '((1 7)))

(for ([function (in-list
                 (list DIV
                       typed-rat-div))])
  (check-equal?
   (procedure-arity
    (lazy-force function))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force
     (lazy-apply function ONE)))
   1))
