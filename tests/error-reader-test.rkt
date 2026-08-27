#lang racket/base

(require rackunit
         racket/list
         racket/promise
         "../core/binary-nat.rkt"
         "../core/chars.rkt"
         "../core/errors.rkt"
         "../core/function-names.rkt"
         "../core/list-nat.rkt"
         "../core/lists.rkt"
         "../core/objects.rkt"
         "../core/result.rkt"
         "../core/strings.rkt"
         "../core/tags.rkt"
         (only-in "../core/typed-logic.rkt"
                  TRUE
                  typed-not
                  typed-and
                  typed-or
                  typed-xor
                  typed-if)
         "../core/typed-nat.rkt"
         "../readers/error.rkt"
         "../readers/list.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/string.rkt"
         "../readers/type-tag.rkt"
         "helpers/lazy.rkt")

(define (apply2 function first second)
  (lazy-apply
   (lazy-apply function first)
   second))

(define (apply3 function first second third)
  (lazy-apply
   (apply2 function first second)
   third))

(define (typed-value? type value)
  (raw-boolean->boolean
   (apply2 raw-is-type type value)))

(define function-name-cases
  (list
   (list cons-function-name "cons")
   (list head-function-name "HEAD")
   (list tail-function-name "TAIL")
   (list is-nil-function-name "IS-NIL")
   (list len-function-name "LEN")
   (list take-function-name "TAKE")
   (list drop-function-name "DROP")
   (list not-function-name "NOT")
   (list and-function-name "AND")
   (list or-function-name "OR")
   (list xor-function-name "XOR")
   (list if-function-name "if")
   (list succ-function-name "SUCC")
   (list add-function-name "ADD")
   (list sub-function-name "SUB")
   (list mult-function-name "MULT")
   (list div-function-name "DIV")
   (list eq-function-name "EQ")
   (list lt-function-name "LT")
   (list lte-function-name "LTE")
   (list gt-function-name "GT")
   (list gte-function-name "GTE")
   (list is-zero-function-name "IS-ZERO")
   (list make-err-function-name "make-err")
   (list is-ok-function-name "is-ok")
   (list is-err-function-name "is-err")
   (list unwrap-ok-function-name "unwrap-ok")
   (list unwrap-err-function-name "unwrap-err")
   (list make-char-function-name "MAKE-CHAR")
   (list char-eq-function-name "CHAR-EQ")
   (list char-lt-function-name "CHAR-LT")
   (list char-lte-function-name "CHAR-LTE")
   (list char-gt-function-name "CHAR-GT")
   (list char-gte-function-name "CHAR-GTE")
   (list make-string-function-name "MAKE-STRING")
   (list string-empty-function-name "STRING-EMPTY?")
   (list string-length-function-name "STRING-LENGTH")
   (list string-eq-function-name "STRING-EQ")
   (list string-append-function-name "STRING-APPEND")
   (list string-head-function-name "STRING-HEAD")
   (list string-tail-function-name "STRING-TAIL")
   (list string-prefix-function-name "STRING-PREFIX?")
   (list string-contains-function-name "STRING-CONTAINS?")))

(for ([case (in-list function-name-cases)])
  (check-true
   (typed-value? string-type
                 (first case)))
  (check-equal?
   (string-value->string
    (first case))
   (second case)))

(define type-name-cases
  (list
   (list error-type "ERROR")
   (list bool-type "BOOL")
   (list list-type "LIST")
   (list nat-type "NAT")
   (list result-type "RESULT")
   (list char-type "CHAR")
   (list string-type "STRING")))

(for ([case (in-list type-name-cases)])
  (check-equal? (type-tag->string
                 (first case))
                (second case)))

(define mismatch-cases
  (list
   (list (apply2 typed-cons TRUE TRUE)
         "cons" 2 "LIST" "BOOL")
   (list (lazy-apply typed-head TRUE)
         "HEAD" 1 "LIST" "BOOL")
   (list (lazy-apply typed-tail TRUE)
         "TAIL" 1 "LIST" "BOOL")
   (list (lazy-apply typed-is-nil TRUE)
         "IS-NIL" 1 "LIST" "BOOL")
   (list (lazy-apply typed-len TRUE)
         "LEN" 1 "LIST" "BOOL")
   (list (apply2 typed-take TRUE NIL)
         "TAKE" 1 "NAT" "BOOL")
   (list (apply2 typed-drop TRUE NIL)
         "DROP" 1 "NAT" "BOOL")

   (list (lazy-apply typed-not ONE)
         "NOT" 1 "BOOL" "NAT")
   (list (apply2 typed-and ONE TRUE)
         "AND" 1 "BOOL" "NAT")
   (list (apply2 typed-or ONE TRUE)
         "OR" 1 "BOOL" "NAT")
   (list (apply2 typed-xor ONE TRUE)
         "XOR" 1 "BOOL" "NAT")
   (list (apply3 typed-if ONE TRUE TRUE)
         "if" 1 "BOOL" "NAT")

   (list (lazy-apply typed-nat-succ TRUE)
         "SUCC" 1 "NAT" "BOOL")
   (list (apply2 typed-nat-add TRUE ONE)
         "ADD" 1 "NAT" "BOOL")
   (list (apply2 typed-nat-sub TRUE ONE)
         "SUB" 1 "NAT" "BOOL")
   (list (apply2 typed-nat-mult TRUE ONE)
         "MULT" 1 "NAT" "BOOL")
   (list (apply2 typed-nat-div TRUE ONE)
         "DIV" 1 "NAT" "BOOL")
   (list (apply2 typed-nat-equal TRUE ONE)
         "EQ" 1 "NAT" "BOOL")
   (list (apply2 typed-nat-less TRUE ONE)
         "LT" 1 "NAT" "BOOL")
   (list (apply2 typed-nat-less-equal TRUE ONE)
         "LTE" 1 "NAT" "BOOL")
   (list (apply2 typed-nat-greater TRUE ONE)
         "GT" 1 "NAT" "BOOL")
   (list (apply2 typed-nat-greater-equal TRUE ONE)
         "GTE" 1 "NAT" "BOOL")
   (list (lazy-apply typed-nat-is-zero TRUE)
         "IS-ZERO" 1 "NAT" "BOOL")

   (list (lazy-apply typed-make-err TRUE)
         "make-err" 1 "ERROR" "BOOL")
   (list (lazy-apply typed-result-is-ok TRUE)
         "is-ok" 1 "RESULT" "BOOL")
   (list (lazy-apply typed-result-is-err TRUE)
         "is-err" 1 "RESULT" "BOOL")
   (list (lazy-apply typed-result-unwrap-ok TRUE)
         "unwrap-ok" 1 "RESULT" "BOOL")
   (list (lazy-apply typed-result-unwrap-err TRUE)
         "unwrap-err" 1 "RESULT" "BOOL")

   (list (lazy-apply typed-make-char TRUE)
         "MAKE-CHAR" 1 "NAT" "BOOL")
   (list (apply2 typed-char-equal TRUE A)
         "CHAR-EQ" 1 "CHAR" "BOOL")
   (list (apply2 typed-char-less TRUE A)
         "CHAR-LT" 1 "CHAR" "BOOL")
   (list (apply2 typed-char-less-equal TRUE A)
         "CHAR-LTE" 1 "CHAR" "BOOL")
   (list (apply2 typed-char-greater TRUE A)
         "CHAR-GT" 1 "CHAR" "BOOL")
   (list (apply2 typed-char-greater-equal TRUE A)
         "CHAR-GTE" 1 "CHAR" "BOOL")

   (list (lazy-apply typed-make-string TRUE)
         "MAKE-STRING" 1 "LIST" "BOOL")
   (list (lazy-apply typed-string-empty? TRUE)
         "STRING-EMPTY?" 1 "STRING" "BOOL")
   (list (lazy-apply typed-string-length TRUE)
         "STRING-LENGTH" 1 "STRING" "BOOL")
   (list (apply2 typed-string-equal TRUE EMPTY-STRING)
         "STRING-EQ" 1 "STRING" "BOOL")
   (list (apply2 typed-string-append TRUE EMPTY-STRING)
         "STRING-APPEND" 1 "STRING" "BOOL")
   (list (lazy-apply typed-string-head TRUE)
         "STRING-HEAD" 1 "STRING" "BOOL")
   (list (lazy-apply typed-string-tail TRUE)
         "STRING-TAIL" 1 "STRING" "BOOL")
   (list (apply2 typed-string-prefix? TRUE EMPTY-STRING)
         "STRING-PREFIX?" 1 "STRING" "BOOL")
   (list (apply2 typed-string-contains? TRUE EMPTY-STRING)
         "STRING-CONTAINS?" 1 "STRING" "BOOL")))

(for ([case (in-list mismatch-cases)])
  (define error (first case))
  (define name (second case))
  (define position (third case))
  (define expected-type (fourth case))
  (define actual-type (fifth case))
  (check-true
   (typed-value? error-type error))
  (check-equal?
   (error-value->string error)
   (format "~a(arg~a expected ~a got ~a)"
           name
           position
           expected-type
           actual-type)))

(define add-error
  (apply2 typed-nat-add TRUE ONE))

(define nested-error
  (lazy-apply typed-string-length
              add-error))

(check-equal?
 (error-value->string nested-error)
 "ADD(arg1 expected NAT got BOOL)\n  -> STRING-LENGTH(arg1 expected STRING)")

(check-equal?
 (error-value->string
  (lazy-apply typed-nat-succ
              invalid-nat-error))
 "INVALID-NAT\n  -> SUCC(arg1 expected NAT)")

(define raw-mismatch
  (apply3 raw-make-type-mismatch-error
          argument-position-two
          list-type
          bool-type))

(check-equal?
 (error-value->string raw-mismatch)
 "TYPE-MISMATCH(arg2 expected LIST got BOOL)")
(check-equal?
 (error-value->string invalid-nat-error)
 "INVALID-NAT")
(check-equal?
 (error-value->string divide-by-zero-error)
 "DIVIDE-BY-ZERO")
(check-equal?
 (error-value->string invalid-char-error)
 "INVALID-CHAR")
(check-equal?
 (error-value->string invalid-string-error)
 "INVALID-STRING")
(check-equal?
 (error-value->string wrong-result-variant-error)
 "WRONG-RESULT-VARIANT")

(define one-element-list
  (apply2 typed-cons ONE NIL))

(define result-frame-cases
  (list
   (list (lazy-apply typed-head NIL)
         "EMPTY-LIST" "HEAD")
   (list (lazy-apply typed-tail NIL)
         "EMPTY-LIST" "TAIL")
   (list (lazy-apply typed-make-char
                     (apply2 typed-nat-mult
                             (apply2 typed-nat-mult FOUR EIGHT)
                             EIGHT))
         "INVALID-CHAR" "MAKE-CHAR")
   (list (lazy-apply typed-make-string one-element-list)
         "INVALID-STRING" "MAKE-STRING")
   (list (lazy-apply typed-string-head EMPTY-STRING)
         "EMPTY-LIST" "STRING-HEAD")
   (list (lazy-apply typed-string-tail EMPTY-STRING)
         "EMPTY-LIST" "STRING-TAIL")
   (list (lazy-apply typed-result-unwrap-ok
                     (lazy-apply typed-make-err invalid-nat-error))
         "WRONG-RESULT-VARIANT" "unwrap-ok")
   (list (lazy-apply typed-result-unwrap-err
                     (lazy-apply typed-make-ok ONE))
         "WRONG-RESULT-VARIANT" "unwrap-err")))

(for ([case (in-list result-frame-cases)])
  (define error (first case))
  (define root (second case))
  (define name (third case))
  (check-true
   (typed-value? error-type error))
  (check-equal?
   (error-value->string error)
   (format "~a\n  -> ~a(result)" root name)))

(check-equal?
 (error-value->string
  (lazy-apply typed-nat-succ
              (lazy-apply typed-head NIL)))
 "EMPTY-LIST\n  -> HEAD(result)\n  -> SUCC(arg1 expected NAT)")
