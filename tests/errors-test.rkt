#lang racket/base

(require rackunit
         racket/list
         racket/promise
         "../core/binary-nat.rkt"
         "../core/errors.rkt"
         "../core/list-nat.rkt"
         "../core/lists.rkt"
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/tags.rkt"
         "../readers/bool.rkt"
         "../readers/list.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/type-tag.rkt"
         "helpers/lazy.rkt")

(define (apply2 function first second)
  (lazy-apply
   (lazy-apply function first)
   second))

(define (apply3 function first second third)
  (lazy-apply
   (apply2 function first second)
   third))

(define (error-value? value)
  (raw-boolean->boolean
   (apply2 raw-is-type error-type value)))

(define (list-value? value)
  (raw-boolean->boolean
   (apply2 raw-is-type list-type value)))

(define (nil-value? value)
  (bool->boolean
   (lazy-apply typed-is-nil value)))

(define (error-kind error)
  (lazy-apply
   raw-error-root-kind
   (lazy-apply raw-error-root error)))

(define (error-kind=? error kind)
  (raw-boolean->boolean
   (apply2 raw-error-kind-equal
           (error-kind error)
           kind)))

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

(define kinds
  (list type-mismatch-kind
        empty-list-kind
        invalid-nat-kind
        divide-by-zero-kind))

(for ([kind (in-list kinds)]
      [expected (in-naturals)])
  (check-equal? (type-tag->integer kind)
                expected))

(for* ([left (in-list kinds)]
       [right (in-list kinds)])
  (check-equal?
   (raw-boolean->boolean
    (apply2 raw-error-kind-equal left right))
   (= (type-tag->integer left)
      (type-tag->integer right))))

(check-equal? (type-tag->integer argument-position-one)
              1)
(check-equal? (type-tag->integer argument-position-two)
              2)

(check-true (list-value? NIL))
(check-true (nil-value? NIL))
(check-true (error-value? empty-list-error))
(check-true (error-kind=? empty-list-error
                         empty-list-kind))
(check-true
 (nil-value?
  (lazy-apply raw-error-frames
              empty-list-error)))
(check-true
 (error-kind=?
  (lazy-apply raw-list-tail NIL)
  empty-list-kind))

(check-true (error-value? invalid-nat-error))
(check-true (error-kind=? invalid-nat-error
                         invalid-nat-kind))
(check-true (error-value? divide-by-zero-error))
(check-true (error-kind=? divide-by-zero-error
                         divide-by-zero-kind))
(check-true
 (nil-value?
  (lazy-apply raw-error-frames
              invalid-nat-error)))
(check-true
 (nil-value?
  (lazy-apply raw-error-frames
              divide-by-zero-error)))

(define mismatch
  (apply3 raw-make-type-mismatch-error
          argument-position-two
          list-type
          bool-type))

(define mismatch-root
  (lazy-apply raw-error-root mismatch))

(define mismatch-details
  (lazy-apply raw-error-root-details
              mismatch-root))

(check-true (error-value? mismatch))
(check-true (error-kind=? mismatch
                         type-mismatch-kind))
(check-true
 (nil-value?
  (lazy-apply raw-error-frames mismatch)))
(check-equal?
 (type-tag->integer
  (lazy-apply raw-type-mismatch-argument-position
              mismatch-details))
 2)
(check-equal?
 (type-tag->integer
  (lazy-apply raw-type-mismatch-expected-type
              mismatch-details))
 2)
(check-equal?
 (type-tag->integer
  (lazy-apply raw-type-mismatch-actual-type
              mismatch-details))
 1)

(define first-frame
  (apply2 raw-make-error-frame
          argument-position-one
          nat-type))

(check-equal? (frame->host first-frame)
              '(1 3))

(define once-bubbled
  (apply3 raw-bubble-error
          mismatch
          argument-position-one
          nat-type))

(define twice-bubbled
  (apply3 raw-bubble-error
          once-bubbled
          argument-position-two
          list-type))

(check-true (error-kind=? once-bubbled
                         type-mismatch-kind))
(check-true (error-kind=? twice-bubbled
                         type-mismatch-kind))
(check-equal? (error-frames->host mismatch)
              '())
(check-equal? (error-frames->host once-bubbled)
              '((1 3)))
(check-equal? (error-frames->host twice-bubbled)
              '((2 2) (1 3)))

(define twice-bubbled-details
  (lazy-apply
   raw-error-root-details
   (lazy-apply raw-error-root
               twice-bubbled)))

(check-equal?
 (type-tag->integer
  (lazy-apply raw-type-mismatch-argument-position
              twice-bubbled-details))
 2)
(check-equal?
 (type-tag->integer
  (lazy-apply raw-type-mismatch-expected-type
              twice-bubbled-details))
 2)
(check-equal?
 (type-tag->integer
  (lazy-apply raw-type-mismatch-actual-type
              twice-bubbled-details))
 1)

(define true-object
  (apply2 raw-make-object bool-type raw-true))

(define head-type-error
  (lazy-apply typed-head true-object))

(define cons-tail-type-error
  (apply2 typed-cons true-object true-object))

(for ([case (in-list
             (list
              (list head-type-error 1 2 1)
              (list cons-tail-type-error 2 2 1)))])
  (define error (first case))
  (define details
    (lazy-apply
     raw-error-root-details
     (lazy-apply raw-error-root error)))
  (check-true (error-kind=? error
                           type-mismatch-kind))
  (check-equal?
   (type-tag->integer
    (lazy-apply raw-type-mismatch-argument-position
                details))
   (second case))
  (check-equal?
   (type-tag->integer
    (lazy-apply raw-type-mismatch-expected-type
                details))
   (third case))
  (check-equal?
   (type-tag->integer
    (lazy-apply raw-type-mismatch-actual-type
                details))
   (fourth case)))

(define nested-empty-error
  (lazy-apply
   typed-len
   (lazy-apply typed-head NIL)))

(check-true (error-kind=? nested-empty-error
                         empty-list-kind))
(check-equal? (error-frames->host nested-empty-error)
              '((1 2)))

(define cons-head-propagation
  (apply2 typed-cons invalid-nat-error NIL))

(define cons-tail-propagation
  (apply2 typed-cons true-object invalid-nat-error))

(define head-propagation
  (lazy-apply typed-head invalid-nat-error))

(define take-count-propagation
  (apply2 typed-take invalid-nat-error NIL))

(define take-list-propagation
  (apply2 typed-take ZERO invalid-nat-error))

(for ([error (in-list
              (list cons-head-propagation
                    cons-tail-propagation
                    head-propagation
                    take-count-propagation
                    take-list-propagation))])
  (check-true (error-kind=? error
                           invalid-nat-kind)))

(check-equal? (error-frames->host cons-head-propagation)
              '())
(check-equal? (error-frames->host cons-tail-propagation)
              '((2 2)))
(check-equal? (error-frames->host head-propagation)
              '((1 2)))
(check-equal? (error-frames->host take-count-propagation)
              '((1 3)))
(check-equal? (error-frames->host take-list-propagation)
              '((2 2)))

(define lazy-root
  (apply2
   raw-make-error-root
   invalid-nat-kind
   (delay
     (error 'raw-error-root-kind
            "forced root details"))))

(define lazy-error
  (apply2
   raw-make-error
   lazy-root
   (delay
     (error 'raw-error-root
            "forced frame list"))))

(check-equal?
 (type-tag->integer
  (lazy-apply
   raw-error-root-kind
   (lazy-apply raw-error-root lazy-error)))
 2)

(define lazy-framed
  (apply2 raw-add-error-frame
          lazy-error
          first-frame))

(check-equal?
 (frame->host
  (lazy-apply
   raw-list-head
   (lazy-apply raw-error-frames
               lazy-framed)))
 '(1 3))

(for ([function (in-list
                 (list raw-error-root-kind
                       raw-error-root-details
                       raw-type-mismatch-argument-position
                       raw-type-mismatch-expected-type
                       raw-type-mismatch-actual-type
                       raw-error-frame-argument-position
                       raw-error-frame-expected-type
                       raw-error-payload-root
                       raw-error-payload-frames
                       raw-error-root
                       raw-error-frames
                       raw-make-root-error))])
  (check-equal?
   (procedure-arity
    (lazy-force function))
   1))

(for ([function (in-list
                 (list raw-error-kind-equal
                       raw-make-error-root
                       raw-make-error-frame
                       raw-make-error-payload
                       raw-make-error
                       raw-add-error-frame))])
  (check-equal?
   (procedure-arity
    (lazy-force function))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force
     (lazy-apply function raw-false)))
   1))

(for ([function (in-list
                 (list raw-make-type-mismatch-details
                       raw-make-type-mismatch-error
                       raw-bubble-error))])
  (check-equal?
   (procedure-arity
    (lazy-force function))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force
     (lazy-apply function raw-false)))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force
     (apply2 function raw-false raw-false)))
   1))
