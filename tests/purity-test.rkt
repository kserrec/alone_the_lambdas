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
(check-equal? (kinds '(begin first
                             second))
              '(forbidden-host-form))
(check-equal? (kinds '(string-ref value
                                  index))
              '(forbidden-host-form))
(check-equal? (kinds '(host request))
              '(forbidden-host-form))
(check-equal? (kinds '(type-check2 value))
              '(arity-specific-checker))
(check-equal? (kinds '(make-typed-function-3 raw-function))
              '(arity-specific-checker))
(check-equal? (kinds '(make-typed-function raw-function))
              '())
(check-equal? (kinds '((lambda (value)
                         value)
                       argument))
              '())
(check-equal? (kinds '(lambda (value)
                        0))
              '(forbidden-host-datum))
(check-equal? (kinds '(lambda (value)
                        #t))
              '(forbidden-host-datum))
(check-equal? (kinds '(lambda (value)
                        "host value"))
              '(forbidden-host-datum))
(check-equal? (kinds '(lambda (value)
                        #\a))
              '(forbidden-host-datum))
(check-equal? (kinds '(lambda (value)
                        #(host vector)))
              '(forbidden-host-datum))

(define scaffolding-datum
  '(module example "lazy-shell.rkt"
     (#%module-begin
      (require "dependency.rkt")
      (provide identity)
      (def identity value =
        value))))

(check-equal? (kinds scaffolding-datum)
              '())

(define host-backed-production-datum
  '(module example "lazy-shell.rkt"
     (#%module-begin
      (require "dependency.rkt")
      (provide value)
      (def value =
        0))))

(check-equal? (kinds host-backed-production-datum)
              '(forbidden-host-datum))

(define-runtime-path core-directory
  "../core")

(define production-findings
  (append-map file-violations
              (production-files-under
               core-directory)))

(check-equal? production-findings
              '())
