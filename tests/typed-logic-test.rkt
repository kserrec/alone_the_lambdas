#lang racket/base

(require rackunit
         racket/list
         racket/promise
         "../core/binary-nat.rkt"
         "../core/errors.rkt"
         "../core/lists.rkt"
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/tags.rkt"
         "../core/rat.rkt"
         (only-in "../core/typed-logic.rkt"
                  TRUE
                  FALSE
                  typed-not
                  typed-and
                  typed-or
                  typed-xor
                  typed-if
                  NOT
                  AND
                  OR
                  XOR
                  [if public-if])
         "../readers/bool.rkt"
         "../readers/list.rkt"
         "../readers/rat.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/type-tag.rkt"
         "helpers/lazy.rkt"
         (only-in "helpers/values.rkt"
                  apply2
                  apply3
                  typed-value?
                  whole-rat-object
                  rat-object->number))

(define ZERO (whole-rat-object 0))
(define ONE (whole-rat-object 1))
(define TWO (whole-rat-object 2))

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
   1)
  (check-equal?
   (type-tag->integer
    (lazy-apply
     raw-type-mismatch-actual-type
     details))
   7)
  (check-equal? (error-frames->host error)
                (list
                 (list position 1))))

(check-bool #t TRUE)
(check-bool #f FALSE)

(check-bool #f
            (lazy-apply typed-not TRUE))
(check-bool #t
            (lazy-apply typed-not FALSE))

(define binary-cases
  (list
   (list TRUE TRUE #t #t #f)
   (list TRUE FALSE #f #t #t)
   (list FALSE TRUE #f #t #t)
   (list FALSE FALSE #f #f #f)))

(for ([case (in-list binary-cases)])
  (define left (first case))
  (define right (second case))
  (check-bool (third case)
              (apply2 typed-and left right))
  (check-bool (fourth case)
              (apply2 typed-or left right))
  (check-bool (fifth case)
              (apply2 typed-xor left right)))

(check-bool #f
            (lazy-apply NOT TRUE))
(check-bool #f
            (apply2 AND TRUE FALSE))
(check-bool #t
            (apply2 OR FALSE TRUE))
(check-bool #t
            (apply2 XOR TRUE FALSE))

(define unary-mismatch
  (lazy-apply typed-not ZERO))

(check-mismatch unary-mismatch 1)

(for ([case (in-list
             (list (list typed-and FALSE)
                   (list typed-or TRUE)
                   (list typed-xor TRUE)))])
  (define operation (first case))
  (define short-circuiting-first (second case))
  (define after-wrong-first
    (lazy-apply operation ZERO))
  (check-equal?
   (procedure-arity
    (lazy-force after-wrong-first))
   1)
  (define wrong-first
    (lazy-apply
     after-wrong-first
     (delay
       (error 'typed-logic
              "forced argument after first-position mismatch"))))
  (check-mismatch wrong-first 1)

  (define wrong-second
    (apply2 operation
            short-circuiting-first
            ZERO))
  (check-mismatch wrong-second 2))

(define bubbled-unary
  (lazy-apply typed-not
              invalid-nat-error))

(check-true
 (error-kind=? bubbled-unary
               invalid-nat-kind))
(check-equal? (error-frames->host bubbled-unary)
              '((1 1)))

(define bubbled-first-partial
  (lazy-apply typed-and
              invalid-nat-error))

(check-equal?
 (procedure-arity
  (lazy-force bubbled-first-partial))
 1)

(define bubbled-first
  (lazy-apply
   bubbled-first-partial
   (delay
     (error 'typed-and
            "forced argument after incoming first-position Error"))))

(check-true
 (error-kind=? bubbled-first
               invalid-nat-kind))
(check-equal? (error-frames->host bubbled-first)
              '((1 1)))

(define bubbled-second
  (apply2 typed-and
          TRUE
          invalid-nat-error))

(check-true
 (error-kind=? bubbled-second
               invalid-nat-kind))
(check-equal? (error-frames->host bubbled-second)
              '((2 1)))
(check-equal? (error-frames->host invalid-nat-error)
              '())

(for ([operation (in-list
                  (list typed-and
                        typed-or
                        typed-xor
                        AND
                        OR
                        XOR))])
  (check-equal?
   (procedure-arity
    (lazy-force operation))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force
     (lazy-apply operation TRUE)))
   1))

(check-equal?
 (procedure-arity
  (lazy-force typed-not))
 1)
(check-equal?
 (procedure-arity
  (lazy-force NOT))
 1)

(define nil-result
  (lazy-apply typed-is-nil NIL))

(define nonempty-result
  (lazy-apply
   typed-is-nil
   (apply2 typed-cons TRUE NIL)))

(check-bool #t nil-result)
(check-bool #f nonempty-result)

(check-equal?
 (rat-object->number
  (apply3 typed-if TRUE ONE TWO))
 1)
(check-equal?
 (rat-object->number
  (apply3 typed-if FALSE ONE TWO))
 2)
(check-true
 (typed-value?
  list-type
  (apply3 typed-if TRUE NIL ONE)))
(check-equal?
 (rat-object->number
  (apply3 public-if FALSE ONE TWO))
 2)

(check-equal?
 (rat-object->number
  (apply3
   typed-if
   TRUE
   ONE
   (delay
     (error 'typed-if
            "forced unselected false branch"))))
 1)

(check-equal?
 (rat-object->number
  (apply3
   typed-if
   FALSE
   (delay
     (error 'typed-if
            "forced unselected true branch"))
   TWO))
 2)

(define wrong-if-after-condition
  (lazy-apply typed-if ZERO))

(check-equal?
 (procedure-arity
  (lazy-force wrong-if-after-condition))
 1)

(define wrong-if-after-first-branch
  (lazy-apply
   wrong-if-after-condition
   (delay
     (error 'typed-if
            "forced branch after wrong condition"))))

(check-equal?
 (procedure-arity
  (lazy-force wrong-if-after-first-branch))
 1)

(define wrong-if
  (lazy-apply
   wrong-if-after-first-branch
   (delay
     (error 'typed-if
            "forced final branch after wrong condition"))))

(check-mismatch wrong-if 1)

(define bubbled-if-after-condition
  (lazy-apply typed-if
              invalid-nat-error))

(check-equal?
 (procedure-arity
  (lazy-force bubbled-if-after-condition))
 1)

(define bubbled-if-after-first-branch
  (lazy-apply
   bubbled-if-after-condition
   (delay
     (error 'typed-if
            "forced branch after incoming condition Error"))))

(check-equal?
 (procedure-arity
  (lazy-force bubbled-if-after-first-branch))
 1)

(define bubbled-if
  (lazy-apply
   bubbled-if-after-first-branch
   (delay
     (error 'typed-if
            "forced final branch after incoming condition Error"))))

(check-true
 (error-kind=? bubbled-if
               invalid-nat-kind))
(check-equal? (error-frames->host bubbled-if)
              '((1 1)))

(define selected-error
  (apply3 typed-if
          TRUE
          invalid-nat-error
          ZERO))

(check-true
 (error-kind=? selected-error
               invalid-nat-kind))
(check-equal? (error-frames->host selected-error)
              '())

(check-equal?
 (procedure-arity
  (lazy-force typed-if))
 1)
(check-equal?
 (procedure-arity
  (lazy-force
   (lazy-apply typed-if TRUE)))
 1)
(check-equal?
 (procedure-arity
  (lazy-force
   (apply2 typed-if TRUE ONE)))
 1)
(check-equal?
 (procedure-arity
  (lazy-force public-if))
 1)

(check-equal?
 (lazy-force
  (apply3 raw-if raw-true
          'raw-selected
          'raw-rejected))
 'raw-selected)
