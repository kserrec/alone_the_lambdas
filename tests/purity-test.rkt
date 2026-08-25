#lang racket/base

(require rackunit
         racket/file
         racket/list
         racket/runtime-path
         "../tooling/check-purity.rkt")

(define-runtime-path trusted-macros-directory
  "../macros")

(define (kinds datum)
  (map violation-kind
       (datum-violations datum)))

(define (write-datum path datum)
  (call-with-output-file path
    #:exists 'truncate
    (lambda (output)
      (write datum output))))

(define (file-kinds datum [dependencies '()])
  (define directory
    (make-temporary-file "alone-the-lambdas-purity-~a"
                         'directory
                         (current-directory)))
  (define core
    (build-path directory
                "core"))
  (define path
    (build-path core
                "production.rkt"))
  (dynamic-wind
    (lambda ()
      (make-directory core)
      (make-file-or-directory-link
       trusted-macros-directory
       (build-path directory
                   "macros"))
      (write-datum path datum)
      (for ([dependency (in-list dependencies)])
        (write-datum
         (build-path core
                     (car dependency))
         (cadr dependency))))
    (lambda ()
      (map violation-kind
           (file-violations path)))
    (lambda ()
      (delete-directory/files directory))))

(define (untrusted-shell-file-kinds datum)
  (define directory
    (make-temporary-file "alone-the-lambdas-shell-~a"
                         'directory
                         (current-directory)))
  (define core
    (build-path directory
                "core"))
  (define macros
    (build-path directory
                "macros"))
  (define path
    (build-path core
                "production.rkt"))
  (dynamic-wind
    (lambda ()
      (make-directory core)
      (make-directory macros)
      (write-datum
       (build-path macros
                   "lazy-with-macros.rkt")
       '(module lookalike racket/base
          (#%module-begin)))
      (write-datum
       (build-path macros
                   "macros.rkt")
       '(module lookalike racket/base
          (#%module-begin)))
      (write-datum path datum))
    (lambda ()
      (map violation-kind
           (file-violations path)))
    (lambda ()
      (delete-directory/files directory))))

(define (symlink-file-kinds datum)
  (define directory
    (make-temporary-file "alone-the-lambdas-link-~a"
                         'directory
                         (current-directory)))
  (define target
    (build-path directory
                "target.rkt"))
  (define link
    (build-path directory
                "production.rkt"))
  (dynamic-wind
    (lambda ()
      (write-datum target datum)
      (make-file-or-directory-link target
                                   link))
    (lambda ()
      (map violation-kind
           (file-violations link)))
    (lambda ()
      (delete-directory/files directory))))

(check-equal? (kinds '(lambda (value)
                        value))
              '())
(check-equal? (kinds '(lambda (left right)
                        left))
              '(non-unary-lambda))
(check-equal? (kinds '(lambda arguments
                        arguments))
              '(non-unary-lambda))
(check-equal? (kinds '(lambda (value)
                        value
                        value))
              '(non-unary-lambda))
(check-equal? (kinds '(lambda (lambda)
                        (lambda lambda)))
              '())
(check-equal? (kinds '(lambda (define)
                        (define define)))
              '())
(check-equal? (kinds '(lambda (lambda-let)
                        (lambda-let lambda-let)))
              '())
(check-equal? (kinds '(define (identity value)
                        value))
              '(host-function-definition))
(check-not-false
 (member 'host-function-definition
         (kinds '(define raw-operation
                   +))))
(check-not-false
 (member 'forbidden-host-identifier
         (kinds '(define raw-operation
                   +))))
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
(check-equal? (kinds '(raw-operation left right))
              '(non-unary-application))
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
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (require "dependency.rkt")
      (provide identity)
      (def identity value =
        value))))

(check-equal? (kinds scaffolding-datum)
              '())

(define lookalike-shell-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (require "../macros/macros.rkt"))))

(define lookalike-shell-findings
  (untrusted-shell-file-kinds lookalike-shell-datum))

(check-not-false
 (and (member 'unexpected-production-language
              lookalike-shell-findings)
      (member 'disallowed-production-import
              lookalike-shell-findings)))

(define host-backed-production-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (require "dependency.rkt")
      (provide value)
      (def value =
        0))))

(check-equal? (kinds host-backed-production-datum)
              '(forbidden-host-datum))

(define renamed-host-import-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (require "../macros/macros.rkt"
               (rename-in racket/base
                          [+ raw-operation]))
      (provide bad)
      (def bad left right =
        (raw-operation left right)))))

(check-not-false
 (member 'disallowed-production-import
         (kinds renamed-host-import-datum)))
(check-not-false
 (member 'non-unary-application
         (kinds renamed-host-import-datum)))

(define dotenv-like-import-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (require "service.env.rkt"))))

(check-not-false
 (member 'disallowed-production-import
         (kinds dotenv-like-import-datum)))

(define uppercase-dotenv-like-import-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (require "SERVICE.ENV.RKT"))))

(check-not-false
 (member 'disallowed-production-import
         (kinds uppercase-dotenv-like-import-datum)))

(check-equal?
 (symlink-file-kinds
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin)))
 '(disallowed-production-path))

(define shadowed-module-syntax-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (require "../macros/macros.rkt")
      (provide result)
      (def require value = value)
      (require "../macros/macros.rkt")
      (def lambda-let value = value)
      (lambda-let result = value value)
      (def def first second third = first)
      (def result = value))))

(check-equal?
 (filter
  (lambda (kind)
    (eq? kind 'reserved-production-binding))
  (file-kinds shadowed-module-syntax-datum))
 '(reserved-production-binding
   reserved-production-binding
   reserved-production-binding))

(define pure-dependency-datum
  '(module dependency "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (provide identity)
      (def identity value =
        value))))

(define renamed-project-import-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (require (rename-in "dependency.rkt"
                          [identity renamed-identity]))
      (provide call)
      (def call value =
        (renamed-identity value)))))

(check-equal?
 (file-kinds renamed-project-import-datum
             (list
              (list "dependency.rkt"
                    pure-dependency-datum)))
 '())

(define reserved-renamed-project-import-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (require (rename-in "dependency.rkt"
                          [identity require]))
      (require "../macros/macros.rkt"))))

(check-not-false
 (member
  'reserved-production-binding
  (file-kinds reserved-renamed-project-import-datum
              (list
               (list "dependency.rkt"
                     pure-dependency-datum)))))

(define numbered-checker-definition-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (provide type-check2)
      (def type-check2 value = value))))

(check-not-false
 (member 'arity-specific-checker
         (file-kinds numbered-checker-definition-datum)))

(define numbered-checker-boundary-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (require (rename-in "dependency.rkt"
                          [identity make-typed-function-3]))
      (provide (rename-out [local type-check2]))
      (def local value = value))))

(check-equal?
 (filter
  (lambda (kind)
    (eq? kind 'arity-specific-checker))
  (file-kinds numbered-checker-boundary-datum
              (list
               (list "dependency.rkt"
                     pure-dependency-datum))))
 '(arity-specific-checker
   arity-specific-checker))

(define impure-provider-datum
  '(module provider "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (provide add1))))

(define forwarding-dependency-datum
  '(module dependency "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (require "provider.rkt")
      (provide add1))))

(define transitive-import-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (require "dependency.rkt")
      (provide bad)
      (def bad value =
        (add1 value)))))

(check-not-false
 (member
  'impure-production-import
  (file-kinds transitive-import-datum
              (list
               (list "dependency.rkt"
                     forwarding-dependency-datum)
               (list "provider.rkt"
                     impure-provider-datum)))))

(define wrong-language-datum
  '(module example racket/base
     (#%module-begin
      (provide bad)
      (define bad +))))

(check-not-false
 (member 'unexpected-production-language
         (kinds wrong-language-datum)))

(define unapproved-language-binding-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (provide bad)
      (def bad value =
        (add1 value)))))

(check-not-false
 (member 'unapproved-production-identifier
         (file-kinds unapproved-language-binding-datum)))

(define forbidden-language-value-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (provide bad)
      (def bad =
        +))))

(check-not-false
 (member 'forbidden-host-identifier
         (file-kinds forbidden-language-value-datum)))

(define shadowed-host-names-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (provide call)
      (def call map value =
        (map value)))))

(check-equal? (file-kinds shadowed-host-names-datum)
              '())

(define inherited-host-export-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (provide +))))

(check-not-false
 (member 'unapproved-production-export
         (file-kinds inherited-host-export-datum)))

(define transformed-export-datum
  '(module example "../macros/lazy-with-macros.rkt"
     (#%module-begin
      (provide (all-defined-out)))))

(check-not-false
 (member 'disallowed-production-export
         (file-kinds transformed-export-datum)))

(define-runtime-path core-directory
  "../core")

(define production-findings
  (append-map file-violations
              (production-files-under
               core-directory)))

(check-equal? production-findings
              '())
