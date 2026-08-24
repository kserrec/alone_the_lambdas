#lang racket/base

(require rackunit
         "../macros/macros.rkt"
         "helpers/lazy.rkt")

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
