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
         "../core/logic.rkt"
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
         "../core/rat.rkt"
         "../core/typed-rat.rkt"
         "../readers/error.rkt"
         "../readers/list.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/string.rkt"
         "../readers/type-tag.rkt"
         "helpers/lazy.rkt"
         (only-in "helpers/values.rkt"
                  apply2
                  apply3
                  typed-value?
                  host-bits->raw
                  whole-rat-object))

(define ONE (whole-rat-object 1))
(define FOUR (whole-rat-object 4))
(define EIGHT (whole-rat-object 8))

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
   (list rat-type "RAT")
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
   (list (lazy-apply typed-len-rat TRUE)
         "LEN" 1 "LIST" "BOOL")
   (list (apply2 typed-take-rat TRUE NIL)
         "TAKE" 1 "RAT" "BOOL")
   (list (apply2 typed-drop-rat TRUE NIL)
         "DROP" 1 "RAT" "BOOL")

   (list (lazy-apply typed-not ONE)
         "NOT" 1 "BOOL" "RAT")
   (list (apply2 typed-and ONE TRUE)
         "AND" 1 "BOOL" "RAT")
   (list (apply2 typed-or ONE TRUE)
         "OR" 1 "BOOL" "RAT")
   (list (apply2 typed-xor ONE TRUE)
         "XOR" 1 "BOOL" "RAT")
   (list (apply3 typed-if ONE TRUE TRUE)
         "if" 1 "BOOL" "RAT")

   (list (lazy-apply typed-rat-succ TRUE)
         "SUCC" 1 "RAT" "BOOL")
   (list (apply2 typed-rat-add TRUE ONE)
         "ADD" 1 "RAT" "BOOL")
   (list (apply2 typed-rat-sub TRUE ONE)
         "SUB" 1 "RAT" "BOOL")
   (list (apply2 typed-rat-mult TRUE ONE)
         "MULT" 1 "RAT" "BOOL")
   (list (apply2 typed-rat-div TRUE ONE)
         "DIV" 1 "RAT" "BOOL")
   (list (apply2 typed-rat-exp TRUE ONE)
         "EXP" 1 "RAT" "BOOL")
   (list (lazy-apply typed-rat-recip TRUE)
         "RECIP" 1 "RAT" "BOOL")
   (list (lazy-apply typed-rat-negate TRUE)
         "NEG" 1 "RAT" "BOOL")
   (list (lazy-apply typed-rat-abs TRUE)
         "ABS" 1 "RAT" "BOOL")
   (list (lazy-apply typed-rat-floor TRUE)
         "FLOOR" 1 "RAT" "BOOL")
   (list (apply2 typed-rat-equal TRUE ONE)
         "EQ" 1 "RAT" "BOOL")
   (list (apply2 typed-rat-less TRUE ONE)
         "LT" 1 "RAT" "BOOL")
   (list (apply2 typed-rat-less-equal TRUE ONE)
         "LTE" 1 "RAT" "BOOL")
   (list (apply2 typed-rat-greater TRUE ONE)
         "GT" 1 "RAT" "BOOL")
   (list (apply2 typed-rat-greater-equal TRUE ONE)
         "GTE" 1 "RAT" "BOOL")
   (list (lazy-apply typed-rat-is-zero TRUE)
         "IS-ZERO" 1 "RAT" "BOOL")
   (list (lazy-apply typed-rat-is-whole TRUE)
         "IS-WHOLE" 1 "RAT" "BOOL")
   (list (lazy-apply typed-rat-is-nonnegative-whole TRUE)
         "IS-NONNEGATIVE-WHOLE" 1 "RAT" "BOOL")

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

   (list (lazy-apply typed-make-char-rat TRUE)
         "MAKE-CHAR" 1 "RAT" "BOOL")
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
   (list (lazy-apply typed-string-length-rat TRUE)
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
  (apply2 typed-rat-add TRUE ONE))

(define nested-error
  (lazy-apply typed-string-length-rat
              add-error))

(check-equal?
 (error-value->string nested-error)
 "ADD(arg1 expected RAT got BOOL)\n  -> STRING-LENGTH(arg1 expected STRING)")

(check-equal?
 (error-value->string
  (lazy-apply typed-rat-succ
              invalid-nat-error))
 "INVALID-NAT\n  -> SUCC(arg1 expected RAT)")

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
   (list (lazy-apply typed-make-char-rat
                     (apply2 typed-rat-mult
                             (apply2 typed-rat-mult FOUR EIGHT)
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
  (lazy-apply typed-rat-succ
              (lazy-apply typed-head NIL)))
 "EMPTY-LIST\n  -> HEAD(result)\n  -> SUCC(arg1 expected RAT)")
