#lang racket/base

(require rackunit
         racket/list
         racket/promise
         "../core/binary-nat.rkt"
         "../core/chars.rkt"
         "../core/errors.rkt"
         "../core/lists.rkt"
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/tags.rkt"
         (only-in "../core/typed-logic.rkt"
                  TRUE)
         "../readers/bool.rkt"
         "../readers/char.rkt"
         "../readers/list.rkt"
         "../readers/nat.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/type-tag.rkt"
         "helpers/lazy.rkt")

(define (apply2 function first second)
  (lazy-apply
   (lazy-apply function first)
   second))

(define (host-bits->raw bits)
  (foldr
   (lambda (bit tail)
     (apply2 raw-cons
             (if bit raw-true raw-false)
             tail))
   NIL
   bits))

(define (integer->host-bits integer)
  (for/list ([character
              (in-string
               (number->string integer 2))])
    (char=? character #\1)))

(define (integer->nat integer)
  (lazy-apply
   raw-make-nat
   (host-bits->raw
    (integer->host-bits integer))))

(define (typed-value? type value)
  (raw-boolean->boolean
   (apply2 raw-is-type type value)))

(define (error-kind=? error kind)
  (raw-boolean->boolean
   (apply2
    raw-error-kind-equal
    (lazy-apply
     raw-error-root-kind
     (lazy-apply raw-error-root error))
    kind)))

(define (mismatch-details error)
  (lazy-apply
   raw-error-root-details
   (lazy-apply raw-error-root error)))

(define (frame->host frame)
  (list
   (type-tag->integer
    (lazy-apply
     raw-error-frame-argument-position
     frame))
   (type-tag->integer
    (lazy-apply
     raw-error-frame-expected-type
     frame))))

(define (error-frames->host error)
  (list->host-list
   (lazy-apply raw-error-frames error)
   frame->host))

(define (char-value->nat value)
  (lazy-apply
   raw-make-nat
   (lazy-apply raw-char-value value)))

(define (check-char expected value)
  (check-true
   (typed-value? char-type value))
  (check-equal? (char-value->integer value)
                expected)
  (check-equal?
   (nat->host-bits
    (char-value->nat value))
   (integer->host-bits expected))
  (check-equal?
   (type-tag->integer
    (lazy-apply
     raw-object-type
     (lazy-apply raw-char-value value)))
   2))

(define (check-bool expected value)
  (check-true
   (typed-value? bool-type value))
  (check-equal? (bool->boolean value)
                expected))

(define (check-mismatch error position expected-type)
  (define details
    (mismatch-details error))
  (check-true
   (error-kind=? error
                 type-mismatch-kind))
  (check-equal?
   (type-tag->integer
    (lazy-apply
     raw-type-mismatch-argument-position
     details))
   position)
  (check-equal?
   (type-tag->integer
    (lazy-apply
     raw-type-mismatch-expected-type
     details))
   expected-type)
  (check-equal?
   (type-tag->integer
    (lazy-apply
     raw-type-mismatch-actual-type
     details))
   1)
  (check-equal? (error-frames->host error)
                '()))

(define (check-bubbled error position expected-type)
  (check-true
   (error-kind=? error
                 invalid-nat-kind))
  (check-equal? (error-frames->host error)
                (list
                 (list position expected-type))))

(define uppercase-constants
  (list A B C D E F G H I J K L M
        N O P Q R S T U V W X Y Z))

(define lowercase-constants
  (list a b c d e f g h i j k l m
        n o p q r s t u v w x y z))

(define digit-constants
  (list DIGIT-0 DIGIT-1 DIGIT-2 DIGIT-3 DIGIT-4
        DIGIT-5 DIGIT-6 DIGIT-7 DIGIT-8 DIGIT-9))

(for ([constant (in-list uppercase-constants)]
      [code (in-range 65 91)])
  (check-char code constant)
  (check-equal? (char-value->string constant)
                (string (integer->char code))))

(for ([constant (in-list lowercase-constants)]
      [code (in-range 97 123)])
  (check-char code constant)
  (check-equal? (char-value->string constant)
                (string (integer->char code))))

(for ([constant (in-list digit-constants)]
      [code (in-range 48 58)])
  (check-char code constant)
  (check-equal? (char-value->string constant)
                (string (integer->char code))))

(define named-constant-cases
  (list
   (list SPACE 32 " ")
   (list TAB 9 "\t")
   (list CR 13 "\r")
   (list LF 10 "\n")
   (list DOT 46 ".")
   (list COMMA 44 ",")
   (list COLON 58 ":")
   (list SEMICOLON 59 ";")
   (list SLASH 47 "/")
   (list BACKSLASH 92 "\\")
   (list HYPHEN 45 "-")
   (list UNDERSCORE 95 "_")
   (list QUESTION 63 "?")
   (list EQUAL 61 "=")
   (list AMPERSAND 38 "&")
   (list PERCENT 37 "%")
   (list HASH 35 "#")
   (list LEFT-PAREN 40 "(")
   (list RIGHT-PAREN 41 ")")
   (list LEFT-BRACKET 91 "[")
   (list RIGHT-BRACKET 93 "]")
   (list LEFT-BRACE 123 "{")
   (list RIGHT-BRACE 125 "}")))

(for ([case (in-list named-constant-cases)])
  (check-char (second case)
              (first case))
  (check-equal?
   (char-value->string
    (first case))
   (third case)))

(for ([code (in-list
             '(0 1 8 9 10 13 32 65 126
               127 128 173 254 255))])
  (check-char
   code
   (lazy-apply MAKE-CHAR
               (integer->nat code))))

(check-equal?
 (char-value->string
  (lazy-apply MAKE-CHAR ZERO))
 "char:0")

(check-equal?
 (char-value->string
  (lazy-apply MAKE-CHAR
              (integer->nat 127)))
 "char:127")

(check-equal?
 (char-value->string
  (lazy-apply MAKE-CHAR
              (integer->nat 173)))
 "char:173")

(check-equal?
 (char-value->string
  (lazy-apply MAKE-CHAR
              (integer->nat 255)))
 "char:255")

(for ([code (in-list '(256 257 511 65535))])
  (define failure
    (lazy-apply MAKE-CHAR
                (integer->nat code)))
  (check-true
   (typed-value? error-type failure))
  (check-true
   (error-kind=? failure
                 invalid-char-kind))
  (check-equal? (error-frames->host failure)
                '()))

(check-mismatch
 (lazy-apply MAKE-CHAR TRUE)
 1
 3)

(define rejected-bool-payload
  (apply2
   raw-make-object
   bool-type
   (delay
     (error 'char
            "forced wrong-type payload"))))

(check-mismatch
 (lazy-apply MAKE-CHAR
             rejected-bool-payload)
 1
 3)

(define bubbled-error
  (lazy-apply MAKE-CHAR
              invalid-nat-error))

(check-true
 (error-kind=? bubbled-error
               invalid-nat-kind))
(check-equal? (error-frames->host bubbled-error)
              '((1 3)))
(check-equal? (error-frames->host invalid-nat-error)
              '())

(define comparison-operations
  (list
   (list CHAR-EQ =)
   (list CHAR-LT <)
   (list CHAR-LTE <=)
   (list CHAR-GT >)
   (list CHAR-GTE >=)))

(define comparison-cases
  (list
   (list TAB TAB)
   (list TAB LF)
   (list SPACE A)
   (list A A)
   (list A Z)
   (list Z A)
   (list Z a)
   (list a Z)
   (list DIGIT-0 DIGIT-9)
   (list RIGHT-BRACE RIGHT-BRACE)
   (list
    (lazy-apply MAKE-CHAR ZERO)
    (lazy-apply MAKE-CHAR
                (integer->nat 255)))))

(for* ([case (in-list comparison-cases)]
       [operation (in-list comparison-operations)])
  (define left (first case))
  (define right (second case))
  (check-bool
   ((second operation)
    (char-value->integer left)
    (char-value->integer right))
   (apply2 (first operation)
           left
           right)))

(define internal-comparisons
  (list typed-char-equal
        typed-char-less
        typed-char-less-equal
        typed-char-greater
        typed-char-greater-equal))

(for ([operation (in-list internal-comparisons)])
  (define wrong-first-partial
    (lazy-apply operation TRUE))
  (check-equal?
   (procedure-arity
    (lazy-force wrong-first-partial))
   1)
  (check-mismatch
   (lazy-apply
    wrong-first-partial
    (delay
      (error 'char
             "forced argument after first Char mismatch")))
   1
   5)
  (check-mismatch
   (apply2 operation A TRUE)
   2
   5)

  (define bubbled-first-partial
    (lazy-apply operation
                invalid-nat-error))
  (check-equal?
   (procedure-arity
    (lazy-force bubbled-first-partial))
   1)
  (check-bubbled
   (lazy-apply
    bubbled-first-partial
    (delay
      (error 'char
             "forced argument after first Char Error")))
   1
   5)
  (check-bubbled
   (apply2 operation A invalid-nat-error)
   2
   5))

(check-equal? (error-frames->host invalid-nat-error)
              '())

(define leading-zero-two
  (host-bits->raw
   '(#f #f #t #f)))

(check-char
 2
 (lazy-apply raw-make-char
             leading-zero-two))

(for ([function (in-list
                 (list raw-make-char
                       raw-char-value
                       typed-make-char
                       MAKE-CHAR))])
  (check-equal?
   (procedure-arity
   (lazy-force function))
   1))

(for ([function (in-list
                 (append
                  internal-comparisons
                  (list CHAR-EQ CHAR-LT CHAR-LTE
                        CHAR-GT CHAR-GTE)))])
  (check-equal?
   (procedure-arity
    (lazy-force function))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force
     (lazy-apply function A)))
   1))
