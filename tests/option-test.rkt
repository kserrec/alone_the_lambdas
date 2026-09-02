#lang racket/base

(require rackunit
         racket/promise
         "../core/errors.rkt"
         "../core/int.rkt"
         "../core/lists.rkt"
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/option.rkt"
         "../core/rat.rkt"
         "../core/tags.rkt"
         (only-in "../core/typed-logic.rkt" TRUE FALSE)
         "../readers/bool.rkt"
         "../readers/error.rkt"
         "../readers/option.rkt"
         "../readers/rat.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/type-tag.rkt"
         "helpers/lazy.rkt")

(define (apply2 function first-argument second-argument)
  (lazy-apply
   (lazy-apply function first-argument)
   second-argument))

(define (apply3 function first-argument second-argument third-argument)
  (lazy-apply
   (apply2 function first-argument second-argument)
   third-argument))

(define (typed-value? type value)
  (raw-boolean->boolean
   (apply2 raw-is-type type value)))

(define (object-tag value)
  (type-tag->integer
   (lazy-apply raw-object-type value)))

(define (host-bits->raw bits)
  (foldr
   (lambda (bit tail)
     (apply2 raw-cons
             (if bit raw-true raw-false)
             tail))
   NIL
   bits))

(define (whole-rat-object integer)
  (apply2 raw-make-object
          rat-type
          (lazy-apply
           raw-whole-rat
           (host-bits->raw
            (for/list ([character
                        (in-string
                         (number->string integer 2))])
              (char=? character #\1))))))

(define (rat-object->number value)
  (rat->number
   (lazy-apply raw-object-value value)))

;; SOME holds any non-Error value; NONE is the singleton absent form.
(define some-two (lazy-apply SOME (whole-rat-object 2)))
(define some-true (lazy-apply SOME TRUE))
(define some-nil (lazy-apply SOME NIL))
(define some-none (lazy-apply SOME NONE))

(for ([value (in-list (list some-two some-true some-nil some-none NONE))])
  (check-equal? (object-tag value) 10))

(check-equal? (option->string some-two) "SOME")
(check-equal? (option->string NONE) "NONE")

;; IS-SOME and IS-NONE are strict Bool checks.
(for ([case (in-list
             (list (list some-two #t)
                   (list some-true #t)
                   (list some-nil #t)
                   (list some-none #t)
                   (list NONE #f)))])
  (check-equal?
   (bool->boolean
    (lazy-apply IS-SOME (car case)))
   (cadr case))
  (check-equal?
   (bool->boolean
    (lazy-apply IS-NONE (car case)))
   (not (cadr case))))

;; NONE is not confusable with failure, false, zero, NIL, or Unit.
(check-false (typed-value? bool-type NONE))
(check-false (typed-value? list-type NONE))
(check-false (typed-value? rat-type NONE))
(check-false (typed-value? error-type NONE))
(check-false (typed-value? unit-type NONE))

;; An Error argument bubbles instead of hiding inside Some.
(define bubbled (lazy-apply SOME invalid-nat-error))
(check-equal? (object-tag bubbled) 0)
(check-equal? (error-value->string bubbled) "INVALID-NAT")

;; OPTION-CASE selects lazily: the unselected branch is never evaluated.
(define (add-three option-value)
  (apply3 OPTION-CASE
          option-value
          (lambda (payload)
            (whole-rat-object 3))
          (whole-rat-object 0)))

(check-equal?
 (rat-object->number
  (apply3 OPTION-CASE
          some-two
          (lambda (payload) payload)
          (delay
            (error 'option "forced unselected none branch"))))
 2)

(check-equal?
 (rat-object->number
  (apply3 OPTION-CASE
          NONE
          (delay
            (error 'option "forced unselected some branch"))
          (whole-rat-object 7)))
 7)

;; A wrong option argument is an ordinary strict mismatch, and an
;; incoming Error bubbles with the OPTION-CASE frame.
(check-equal?
 (error-value->string
  (apply3 OPTION-CASE
          TRUE
          (lambda (payload) payload)
          FALSE))
 "OPTION-CASE(arg1 expected OPTION got BOOL)")
(check-equal?
 (error-value->string
  (apply3 OPTION-CASE
          invalid-nat-error
          (lambda (payload) payload)
          FALSE))
 "INVALID-NAT\n  -> OPTION-CASE(arg1 expected OPTION)")

;; Operations remain chains of unary lambdas.
(for ([function (in-list (list SOME IS-SOME IS-NONE OPTION-CASE))])
  (check-equal?
   (procedure-arity (lazy-force function))
   1))
(check-equal?
 (procedure-arity
  (lazy-force (lazy-apply OPTION-CASE some-two)))
 1)
