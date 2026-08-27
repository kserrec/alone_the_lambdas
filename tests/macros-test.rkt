#lang racket/base

(require rackunit
         "../macros/macros.rkt"
         "helpers/lazy.rkt")

(module function-name-fixtures lazy
  (require "../macros/macros.rkt"
           (only-in "../core/errors.rkt" NIL)
           (only-in "../core/lists.rkt" raw-cons)
           (only-in "../core/logic.rkt" raw-false raw-true)
           (only-in "../core/objects.rkt" raw-make-object)
           (only-in "../core/tags.rkt" char-type string-type))

  (provide ascii-function-name
           two-byte-function-name
           three-byte-function-name
           four-byte-function-name)

  (def raw-name-char bits =
    ((raw-make-object char-type) bits))

  (def raw-name-string chars =
    ((raw-make-object string-type) chars))

  (define-function-name ascii-function-name lambda-name)
  (define-function-name two-byte-function-name |λ-name|)
  (define-function-name three-byte-function-name |名-name|)
  (define-function-name four-byte-function-name |🙂-name|))

(require (submod "." function-name-fixtures)
         "../runtime/codec.rkt")

(def identity value =
  value)

(def choose-third first-value second-value third-value fourth-value fifth-value =
  third-value)

(def constant =
  'constant)

(check-equal? (identity 'value)
              'value)
(check-equal? (((((choose-third 'first)
                  'second)
                 'third)
                'fourth)
               'fifth)
              'third)
(check-equal? constant
              'constant)

(check-equal? (procedure-arity choose-third)
              1)
(check-equal? (procedure-arity (choose-third 'first))
              1)
(check-equal? (procedure-arity ((choose-third 'first) 'second))
              1)

(define outside 'outside)

(check-equal? (lazy-force
               (lambda-let outside = 'inside
                 outside))
              'inside)
(check-equal? outside
              'outside)

;; Function-name Strings use the same one-Char-per-UTF-8-byte representation
;; approved for the standalone String-literal surface. Unicode code points are
;; never stored directly, so no generated Char exceeds the range 0 through 255.
(check-equal? (object-string->bytes ascii-function-name)
              #"lambda-name")
(check-equal? (object-string->bytes two-byte-function-name)
              (string->bytes/utf-8 "λ-name"))
(check-equal? (object-string->bytes three-byte-function-name)
              (string->bytes/utf-8 "名-name"))
(check-equal? (object-string->bytes four-byte-function-name)
              (string->bytes/utf-8 "🙂-name"))
