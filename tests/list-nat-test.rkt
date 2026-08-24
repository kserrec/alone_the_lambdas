#lang racket/base

(require rackunit
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
         "../readers/nat.rkt"
         "../readers/raw-boolean.rkt"
         "helpers/lazy.rkt")

(define (apply2 function first second)
  (lazy-apply
   (lazy-apply function first)
   second))

(define (prepend value tail)
  (apply2 typed-cons value tail))

(define (read-bool-object object)
  (raw-boolean->boolean
   (lazy-apply raw-object-value object)))

(define (list-value? value)
  (raw-boolean->boolean
   (apply2 raw-is-type list-type value)))

(define (nat-value? value)
  (raw-boolean->boolean
   (apply2 raw-is-type nat-type value)))

(define (error-value? value)
  (raw-boolean->boolean
   (apply2 raw-is-type error-type value)))

(define (error-kind=? error kind)
  (raw-boolean->boolean
   (apply2
    raw-error-kind-equal
    (lazy-apply
     raw-error-root-kind
     (lazy-apply raw-error-root error))
    kind)))

(define (nil-value? value)
  (bool->boolean
   (lazy-apply typed-is-nil value)))

(define true-object
  (apply2 raw-make-object bool-type raw-true))

(define false-object
  (apply2 raw-make-object bool-type raw-false))

(define sample
  (prepend true-object
           (prepend false-object
                    (prepend true-object
                             (prepend false-object NIL)))))

(define (read-list list)
  (list->host-list list read-bool-object))

(define (raw-length->integer list)
  (nat->integer
   (lazy-apply
    raw-make-nat
    (lazy-apply raw-list-length list))))

(check-equal? (raw-length->integer NIL) 0)
(check-equal? (raw-length->integer sample) 4)

(define empty-length
  (lazy-apply typed-len NIL))

(define sample-length
  (lazy-apply typed-len sample))

(check-true (nat-value? empty-length))
(check-true (nat-value? sample-length))
(check-equal? (nat->integer empty-length) 0)
(check-equal? (nat->integer sample-length) 4)
(check-equal? (nat->host-bits sample-length)
              '(#t #f #f))

(check-equal? (read-list
               (apply2 typed-take ZERO sample))
              '())
(check-equal? (read-list
               (apply2 typed-take ONE sample))
              '(#t))
(check-equal? (read-list
               (apply2 typed-take TWO sample))
              '(#t #f))
(check-equal? (read-list
               (apply2 typed-take FOUR sample))
              '(#t #f #t #f))
(check-equal? (read-list
               (apply2 typed-take TEN sample))
              '(#t #f #t #f))

(check-equal? (read-list
               (apply2 typed-drop ZERO sample))
              '(#t #f #t #f))
(check-equal? (read-list
               (apply2 typed-drop ONE sample))
              '(#f #t #f))
(check-equal? (read-list
               (apply2 typed-drop TWO sample))
              '(#t #f))
(check-true
 (nil-value?
  (apply2 typed-drop FOUR sample)))
(check-true
 (nil-value?
  (apply2 typed-drop TEN sample)))

(check-true
 (nil-value?
  (apply2 typed-take TEN NIL)))
(check-true
 (nil-value?
  (apply2 typed-drop TEN NIL)))

(define (every-tail-is-list? list)
  (and (list-value? list)
       (or (nil-value? list)
           (every-tail-is-list?
            (lazy-apply typed-tail list)))))

(check-true
 (every-tail-is-list?
  (apply2 typed-take THREE sample)))
(check-true
 (every-tail-is-list?
  (apply2 typed-drop ONE sample)))

(define incoming-error
  invalid-nat-error)

(define rejected-bool-object
  (apply2
   raw-make-object
   bool-type
   (delay
     (error 'list-nat-operation
            "forced rejected object payload"))))

(check-true
 (error-value?
  (lazy-apply typed-len true-object)))
(check-true
 (error-value?
  (lazy-apply typed-len rejected-bool-object)))

(define bubbled-length
  (lazy-apply typed-len incoming-error))

(check-true (error-value? bubbled-length))
(check-true
 (error-kind=? bubbled-length
               invalid-nat-kind))

(for ([function (in-list (list typed-take typed-drop))])
  (define bubbled-count
    (apply2
     function
     incoming-error
     (delay
       (error 'list-nat-operation
              "forced list after count Error"))))
  (check-true (error-value? bubbled-count))
  (check-true
   (error-kind=? bubbled-count
                 invalid-nat-kind))

  (define rejected-count
    (apply2
     function
     true-object
     (delay
       (error 'list-nat-operation
              "forced list after wrong count type"))))
  (check-true (error-value? rejected-count))
  (check-true
   (error-kind=? rejected-count
                 type-mismatch-kind))

  (define bubbled-list
    (apply2 function TWO incoming-error))
  (check-true (error-value? bubbled-list))
  (check-true
   (error-kind=? bubbled-list
                 invalid-nat-kind))

  (check-true
   (error-value?
    (apply2 function TWO true-object))))

(define raw-zero-bits
  (lazy-apply raw-nat-value ZERO))

(check-true
 (nil-value?
  (apply2
   raw-list-take
   raw-zero-bits
   (delay
     (error 'raw-list-take
            "forced list while taking zero")))))

(define fragile-list
  (apply2
   raw-cons
   true-object
   (delay
     (error 'raw-list-drop
            "forced tail while dropping zero"))))

(check-true
 (read-bool-object
  (lazy-apply
   raw-list-head
   (apply2 raw-list-drop
           raw-zero-bits
           fragile-list))))

(check-equal?
 (procedure-arity
  (lazy-force typed-len))
 1)

(for ([function (in-list (list typed-take typed-drop))])
  (check-equal?
   (procedure-arity
    (lazy-force function))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force
     (lazy-apply function TWO)))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force
     (lazy-apply function incoming-error)))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force
     (lazy-apply function true-object)))
   1))
