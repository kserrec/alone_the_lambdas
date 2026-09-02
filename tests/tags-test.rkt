#lang racket/base

(require rackunit
         "../core/tags.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/type-tag.rkt"
         "helpers/lazy.rkt")

;; Tag 3 is permanently retired (formerly NAT) and never reassigned.
(define tags
  (vector error-type
          bool-type
          list-type
          result-type
          char-type
          string-type
          rat-type))

(define tag-numbers
  (vector 0 1 2 4 5 6 7))

(define (tag-equal? left right)
  (raw-boolean->boolean
   (lazy-apply
    (lazy-apply raw-tag-equal
                (lazy-force left))
    (lazy-force right))))

(for ([tag (in-vector tags)]
      [expected (in-vector tag-numbers)])
  (check-equal? (type-tag->integer tag)
                expected)
  (check-equal? (procedure-arity
                 (lazy-force tag))
                1)
  (check-equal? (procedure-arity
                 (lazy-force
                  (lazy-apply tag add1)))
                1))

(for* ([left-index (in-range 7)]
       [right-index (in-range 7)])
  (check-equal?
   (tag-equal? (vector-ref tags left-index)
               (vector-ref tags right-index))
   (= left-index right-index)))
