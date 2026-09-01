#lang racket/base

(require rackunit
         racket/list
         racket/promise
         racket/runtime-path
         "../core/chars.rkt"
         "../core/errors.rkt"
         "../core/lists.rkt"
         "../core/objects.rkt"
         "../core/result.rkt"
         "../core/strings.rkt"
         "../core/tags.rkt"
         (only-in "../core/typed-logic.rkt"
                  FALSE
                  TRUE
                  typed-if)
         "../core/typed-nat.rkt"
         "../readers/bool.rkt"
         "../readers/char.rkt"
         "../readers/error.rkt"
         "../readers/nat.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/string.rkt"
         "../readers/type-tag.rkt"
         "../tooling/check-purity.rkt"
         "helpers/lazy.rkt")

(define (apply2 function first second)
  (lazy-apply
   (lazy-apply function first)
   second))

(define (apply3 function first second third)
  (lazy-apply
   (apply2 function first second)
   third))

(define (object-type-name value)
  (type-tag->string
   (lazy-apply raw-object-type value)))

(define hi
  (lazy-apply
   MAKE-STRING
   (apply2 typed-cons
           h
           (apply2 typed-cons i NIL))))

(define space-world
  (lazy-apply
   MAKE-STRING
   (apply2 typed-cons
           SPACE
           (apply2 typed-cons
                   w
                   (apply2 typed-cons
                           o
                           (apply2 typed-cons
                                   r
                                   (apply2 typed-cons
                                           l
                                           (apply2 typed-cons
                                                   d
                                                   NIL))))))))

(define greeting
  (apply3 typed-if
          TRUE
          (apply2 STRING-APPEND hi space-world)
          EMPTY-STRING))

(check-equal? (object-type-name TRUE) "BOOL")
(check-equal? (object-type-name FALSE) "BOOL")
(check-equal? (object-type-name ZERO) "NAT")
(check-equal? (object-type-name NIL) "LIST")
(check-equal? (object-type-name A) "CHAR")
(check-equal? (object-type-name greeting) "STRING")

(check-false (bool->boolean
              (lazy-apply typed-is-nil
                          (apply2 typed-cons TRUE NIL))))
(check-equal? (string-value->string greeting)
              "hi world")
(check-equal? (char-value->string
               (lazy-apply STRING-HEAD greeting))
              "h")
(check-equal? (nat->integer
               (lazy-apply STRING-LENGTH greeting))
              8)

(define one-hundred
  (apply2 MULT TEN TEN))

(check-equal? (nat->integer one-hundred)
              100)
(check-equal? (nat->host-bits one-hundred)
              '(#t #t #f #f #t #f #f))

(define division-success
  (apply2 DIV EIGHT TWO))
(define division-failure
  (apply2 DIV EIGHT ZERO))

(check-equal? (object-type-name division-success)
              "RESULT")
(check-true (bool->boolean
             (lazy-apply is-ok division-success)))
(check-equal? (nat->integer
               (lazy-apply unwrap-ok division-success))
              4)
(check-true (bool->boolean
             (lazy-apply is-err division-failure)))
(check-equal? (error-value->string
               (lazy-apply unwrap-err division-failure))
              "DIVIDE-BY-ZERO")

(define contract-failure
  (apply2 ADD TRUE ONE))

(check-equal? (object-type-name contract-failure)
              "ERROR")
(check-equal? (error-value->string contract-failure)
              "ADD(arg1 expected NAT got BOOL)")

(define-runtime-path core-directory
  "../core")

(define production-results
  (files-violations
   (production-files-under core-directory)))

(check-equal? (length production-results)
              18)
(check-equal? (append-map cdr production-results)
              '())
