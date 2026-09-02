#lang racket/base

(require rackunit
         "../core/tags.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/type-tag.rkt"
         "helpers/lazy.rkt")

;; Tag 3 is permanently retired (formerly NAT) and never reassigned. Every
;; live tag is pinned to its documented number so a miscounted successor
;; chain in tags.rkt — or drift against the reader's hardcoded name table —
;; fails here, the same guard the error-kind space carries in errors-test.
(define tags
  (vector error-type
          bool-type
          list-type
          result-type
          char-type
          string-type
          rat-type
          unit-type
          byte-type
          option-type
          map-type))

(define tag-numbers
  (vector 0 1 2 4 5 6 7 8 9 10 11))

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

(for* ([left-index (in-range (vector-length tags))]
       [right-index (in-range (vector-length tags))])
  (check-equal?
   (tag-equal? (vector-ref tags left-index)
               (vector-ref tags right-index))
   (= left-index right-index)))

;; The reader's rendered names stay in step with the tag numbers.
(for ([tag (in-vector tags)]
      [name (in-vector
             (vector "ERROR" "BOOL" "LIST" "RESULT" "CHAR" "STRING"
                     "RAT" "UNIT" "BYTE" "OPTION" "MAP"))])
  (check-equal? (type-tag->string tag) name))
