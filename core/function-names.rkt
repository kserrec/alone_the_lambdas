#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "errors.rkt"
         "logic.rkt"
         "objects.rkt"
         "pair.rkt"
         "tags.rkt")

(provide cons-function-name
         head-function-name
         tail-function-name
         is-nil-function-name
         len-function-name
         take-function-name
         drop-function-name
         not-function-name
         and-function-name
         or-function-name
         xor-function-name
         if-function-name
         succ-function-name
         add-function-name
         sub-function-name
         mult-function-name
         div-function-name
         eq-function-name
         lt-function-name
         lte-function-name
         gt-function-name
         gte-function-name
         is-zero-function-name
         make-err-function-name
         is-ok-function-name
         is-err-function-name
         unwrap-ok-function-name
         unwrap-err-function-name
         make-char-function-name
         char-eq-function-name
         char-lt-function-name
         char-lte-function-name
         char-gt-function-name
         char-gte-function-name
         make-string-function-name
         string-empty-function-name
         string-length-function-name
         string-eq-function-name
         string-append-function-name
         string-head-function-name
         string-tail-function-name
         string-prefix-function-name
         string-contains-function-name)

(def raw-name-list-cons value tail =
  ((raw-make-object list-type)
   ((raw-pair value) tail)))

(def raw-name-char bits =
  ((raw-make-object char-type) bits))

(def raw-name-string chars =
  ((raw-make-object string-type) chars))

(define-function-name cons-function-name cons)
(define-function-name head-function-name HEAD)
(define-function-name tail-function-name TAIL)
(define-function-name is-nil-function-name IS-NIL)
(define-function-name len-function-name LEN)
(define-function-name take-function-name TAKE)
(define-function-name drop-function-name DROP)

(define-function-name not-function-name NOT)
(define-function-name and-function-name AND)
(define-function-name or-function-name OR)
(define-function-name xor-function-name XOR)
(define-function-name if-function-name if)

(define-function-name succ-function-name SUCC)
(define-function-name add-function-name ADD)
(define-function-name sub-function-name SUB)
(define-function-name mult-function-name MULT)
(define-function-name div-function-name DIV)
(define-function-name eq-function-name EQ)
(define-function-name lt-function-name LT)
(define-function-name lte-function-name LTE)
(define-function-name gt-function-name GT)
(define-function-name gte-function-name GTE)
(define-function-name is-zero-function-name IS-ZERO)

(define-function-name make-err-function-name make-err)
(define-function-name is-ok-function-name is-ok)
(define-function-name is-err-function-name is-err)
(define-function-name unwrap-ok-function-name unwrap-ok)
(define-function-name unwrap-err-function-name unwrap-err)

(define-function-name make-char-function-name MAKE-CHAR)
(define-function-name char-eq-function-name CHAR-EQ)
(define-function-name char-lt-function-name CHAR-LT)
(define-function-name char-lte-function-name CHAR-LTE)
(define-function-name char-gt-function-name CHAR-GT)
(define-function-name char-gte-function-name CHAR-GTE)

(define-function-name make-string-function-name MAKE-STRING)
(define-function-name string-empty-function-name STRING-EMPTY?)
(define-function-name string-length-function-name STRING-LENGTH)
(define-function-name string-eq-function-name STRING-EQ)
(define-function-name string-append-function-name STRING-APPEND)
(define-function-name string-head-function-name STRING-HEAD)
(define-function-name string-tail-function-name STRING-TAIL)
(define-function-name string-prefix-function-name STRING-PREFIX?)
(define-function-name string-contains-function-name STRING-CONTAINS?)
