#lang racket/base

(require rackunit
         racket/list
         racket/runtime-path
         "../tooling/check-purity.rkt")

(define (kinds datum)
  (map violation-kind
       (datum-violations datum)))

(check-equal? (kinds '(lambda (value)
                        value))
              '())
(check-equal? (kinds '(lambda (left right)
                        left))
              '(non-unary-lambda))
(check-equal? (kinds '(lambda arguments
                        arguments))
              '(non-unary-lambda))
(check-equal? (kinds '(define (identity value)
                        value))
              '(host-function-definition))
(check-equal? (kinds '(if condition
                          when-true
                          when-false))
              '(forbidden-host-form))
(check-equal? (kinds '((lambda (value)
                         value)
                       argument))
              '())

(define-runtime-path core-directory
  "../core")

(define production-findings
  (append-map file-violations
              (production-files-under
               core-directory)))

(check-equal? production-findings
              '())
