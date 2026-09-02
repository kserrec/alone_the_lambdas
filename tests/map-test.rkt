#lang racket/base

(require rackunit
         racket/promise
         "../core/byte.rkt"
         "../core/chars.rkt"
         "../core/errors.rkt"
         "../core/int.rkt"
         "../core/lists.rkt"
         "../core/logic.rkt"
         "../core/map.rkt"
         "../core/objects.rkt"
         "../core/pair.rkt"
         "../core/option.rkt"
         "../core/rat.rkt"
         (only-in "../core/strings.rkt" MAKE-STRING STRING-EQ)
         "../core/tags.rkt"
         (only-in "../core/typed-logic.rkt" TRUE FALSE)
         (only-in "../core/typed-rat.rkt" typed-rat-equal)
         "../readers/bool.rkt"
         "../readers/error.rkt"
         "../readers/map.rkt"
         "../readers/option.rkt"
         "../readers/rat.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/type-tag.rkt"
         "helpers/lazy.rkt")

(define (apply2 function first-argument second-argument)
  (lazy-apply (lazy-apply function first-argument) second-argument))

(define (typed-value? type value)
  (raw-boolean->boolean (apply2 raw-is-type type value)))

(define (object-tag value)
  (type-tag->integer (lazy-apply raw-object-type value)))

(define (host-bits->raw bits)
  (foldr
   (lambda (bit tail)
     (apply2 raw-cons (if bit raw-true raw-false) tail))
   NIL
   bits))

(define (whole-rat-object integer)
  (apply2 raw-make-object
          rat-type
          (lazy-apply
           raw-whole-rat
           (host-bits->raw
            (for/list ([character
                        (in-string (number->string integer 2))])
              (char=? character #\1))))))

(define (rat-object->number value)
  (rat->number (lazy-apply raw-object-value value)))

(define (lookup-number map-value key)
  (define result (apply2 MAP-LOOKUP map-value key))
  (check-equal? (object-tag result) 10)
  (if (bool->boolean (lazy-apply IS-SOME result))
      (rat-object->number
       (lazy-apply raw-option-value
                   (lazy-apply raw-object-value result)))
      'none))

;; An empty Map under Rat equality: lookup is expected absence, size zero.
(define rat-map (lazy-apply MAKE-MAP typed-rat-equal))
(check-equal? (object-tag rat-map) 11)
(check-true (bool->boolean (lazy-apply MAP-EMPTY? rat-map)))
(check-equal? (rat-object->number (lazy-apply MAP-SIZE rat-map)) 0)
(check-equal? (map->string rat-map) "MAP:0")
(check-equal? (lookup-number rat-map (whole-rat-object 1)) 'none)

;; MAKE-MAP bubbles an Error argument rather than storing it.
(check-equal?
 (error-value->string (lazy-apply MAKE-MAP invalid-nat-error))
 "INVALID-NAT")

;; Wrong Map arguments and incoming Errors carry the operation's frame.
(check-equal?
 (error-value->string (apply2 MAP-LOOKUP TRUE (whole-rat-object 1)))
 "MAP-LOOKUP(arg1 expected MAP got BOOL)")
(check-equal?
 (error-value->string
  (apply2 MAP-LOOKUP invalid-nat-error (whole-rat-object 1)))
 "INVALID-NAT\n  -> MAP-LOOKUP(arg1 expected MAP)")
(check-equal?
 (error-value->string
  (apply2 MAP-LOOKUP rat-map invalid-nat-error))
 "INVALID-NAT\n  -> MAP-LOOKUP(result)")
(check-equal?
 (error-value->string (lazy-apply MAP-EMPTY? TRUE))
 "MAP-EMPTY?(arg1 expected MAP got BOOL)")
(check-equal?
 (error-value->string (lazy-apply MAP-SIZE TRUE))
 "MAP-SIZE(arg1 expected MAP got BOOL)")

;; An equality function that answers with a non-Bool is a structured
;; Error; one that answers with an Error bubbles. Both need one entry so
;; a comparison actually runs — built through the raw layer here, ahead
;; of the Step 39.2 public MAP-SET.
(define (raw-map-with-one-entry equality key value)
  (apply2 raw-make-object
          map-type
          (apply2 raw-pair
                  equality
                  (apply2 raw-cons
                          (apply2 raw-pair key value)
                          NIL))))

(define wrong-answer-map
  (raw-map-with-one-entry
   (lambda (left) (lambda (right) (whole-rat-object 1)))
   (whole-rat-object 1)
   (whole-rat-object 2)))
(check-equal?
 (error-value->string
  (apply2 MAP-LOOKUP wrong-answer-map (whole-rat-object 1)))
 "MAP-LOOKUP(arg1 expected BOOL got RAT)")

(define error-answer-map
  (raw-map-with-one-entry
   (lambda (left) (lambda (right) invalid-nat-error))
   (whole-rat-object 1)
   (whole-rat-object 2)))
(check-equal?
 (error-value->string
  (apply2 MAP-LOOKUP error-answer-map (whole-rat-object 1)))
 "INVALID-NAT\n  -> MAP-LOOKUP(result)")

;; A found entry returns SOME of its stored value under the Map's own
;; equality function.
(define populated
  (raw-map-with-one-entry typed-rat-equal
                          (whole-rat-object 4)
                          (whole-rat-object 44)))
(check-equal? (lookup-number populated (whole-rat-object 4)) 44)
(check-equal? (lookup-number populated (whole-rat-object 5)) 'none)
(check-false (bool->boolean (lazy-apply MAP-EMPTY? populated)))
(check-equal? (rat-object->number (lazy-apply MAP-SIZE populated)) 1)
(check-equal? (map->string populated) "MAP:1")

;; Operations remain chains of unary lambdas.
(for ([function (in-list (list MAKE-MAP MAP-EMPTY? MAP-SIZE MAP-LOOKUP))])
  (check-equal? (procedure-arity (lazy-force function)) 1))
(check-equal?
 (procedure-arity (lazy-force (lazy-apply MAP-LOOKUP rat-map)))
 1)
