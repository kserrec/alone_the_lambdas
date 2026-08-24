#lang racket/base

(require rackunit
         racket/promise
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/tags.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/type-tag.rkt"
         "helpers/lazy.rkt")

(define tags
  (vector error-type
          bool-type
          list-type
          nat-type
          result-type
          char-type
          string-type))

(define payloads
  (vector raw-true
          raw-false
          raw-true
          raw-false
          raw-true
          raw-false
          raw-true))

(define expected-payloads
  (vector #t #f #t #f #t #f #t))

(define (make-object type-tag value)
  (lazy-apply
   (lazy-apply raw-make-object
               type-tag)
   value))

(define (object-has-type? expected-type object)
  (raw-boolean->boolean
   (lazy-apply
    (lazy-apply raw-is-type
                (lazy-force expected-type))
    object)))

(define objects
  (for/vector ([type-tag (in-vector tags)]
               [payload (in-vector payloads)])
    (make-object type-tag
                 (lazy-force payload))))

(for ([object (in-vector objects)]
      [expected-type (in-range 7)]
      [expected-payload (in-vector expected-payloads)])
  (check-equal?
   (type-tag->integer
    (lazy-apply raw-object-type object))
   expected-type)
  (check-equal?
   (raw-boolean->boolean
    (lazy-apply raw-object-value object))
   expected-payload)
  (check-equal? (procedure-arity
                 (lazy-force object))
                1))

(for* ([expected-index (in-range 7)]
       [object-index (in-range 7)])
  (check-equal?
   (object-has-type?
    (vector-ref tags expected-index)
    (vector-ref objects object-index))
   (= expected-index object-index)))

(check-equal?
 (procedure-arity
  (lazy-force
   (lazy-apply raw-make-object bool-type)))
 1)

(define rejected-value-object
  (make-object bool-type
               (delay
                 (error 'raw-object-type
                        "forced object value"))))

(check-equal?
 (type-tag->integer
  (lazy-apply raw-object-type
              rejected-value-object))
 1)
(check-true
 (object-has-type? bool-type
                   rejected-value-object))

(define rejected-type-object
  (make-object
   (delay
     (error 'raw-object-value
            "forced object type"))
   (lazy-force raw-true)))

(check-true
 (raw-boolean->boolean
  (lazy-apply raw-object-value
              rejected-type-object)))
