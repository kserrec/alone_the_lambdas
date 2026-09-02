#lang racket/base

(require rackunit
         racket/list
         racket/promise
         racket/runtime-path
         "../core/binary-nat.rkt"
         "../core/lists.rkt"
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/pair.rkt"
         "../core/tags.rkt"
         "../readers/list.rkt"
         "../readers/raw-boolean.rkt"
         "helpers/lazy.rkt"
         (only-in "helpers/values.rkt"
                  apply2
                  host-bits->raw
                  integer->host-bits
                  integer->raw-bits))

(define (raw-bits->host-bits bits)
  (list->host-list bits raw-boolean->boolean))

(define (raw-bits->integer bits)
  (for/fold ([total 0])
            ([bit (in-list (raw-bits->host-bits bits))])
    (+ (* total 2)
       (if bit 1 0))))

(define (check-canonical expected actual)
  (check-equal? (raw-bits->integer actual)
                expected)
  (check-equal? (raw-bits->host-bits actual)
                (integer->host-bits expected)))

(define (raw-boolean-result function left right)
  (raw-boolean->boolean
   (apply2 function left right)))

(define leading-zero-two
  (host-bits->raw
   '(#f #f #t #f)))

(define all-zeroes
  (host-bits->raw
   '(#f #f #f)))

(check-canonical 0
                 (lazy-apply raw-normalize-nat NIL))
(check-canonical 0
                 (lazy-apply raw-normalize-nat all-zeroes))
(check-canonical 2
                 (lazy-apply raw-normalize-nat
                             leading-zero-two))

(check-true
 (raw-boolean->boolean
  (lazy-apply raw-nat-is-zero NIL)))
(check-true
 (raw-boolean->boolean
  (lazy-apply raw-nat-is-zero all-zeroes)))
(check-false
 (raw-boolean->boolean
  (lazy-apply raw-nat-is-zero
              (integer->raw-bits 1))))

(for ([case (in-list
             '((0 1)
               (1 2)
               (3 4)
               (7 8)
               (15 16)
               (255 256)
               (65535 65536)))])
  (check-canonical
   (second case)
   (lazy-apply raw-nat-succ
               (integer->raw-bits
                (first case)))))

(for ([case (in-list
             '((0 0 0)
               (0 19 19)
               (1 1 2)
               (7 1 8)
               (15 17 32)
               (255 1 256)
               (4095 4097 8192)
               (123456 654321 777777)))])
  (check-canonical
   (third case)
   (apply2 raw-nat-add
           (integer->raw-bits (first case))
           (integer->raw-bits (second case)))))

(check-canonical
 3
 (apply2 raw-nat-add
         leading-zero-two
         (integer->raw-bits 1)))

(for ([case (in-list
             '((0 0 0)
               (1 0 1)
               (3 5 0)
               (8 1 7)
               (16 7 9)
               (256 1 255)
               (1000 333 667)
               (65536 1 65535)))])
  (check-canonical
   (third case)
   (apply2 raw-nat-sub
           (integer->raw-bits (first case))
           (integer->raw-bits (second case)))))

(for ([case (in-list
             '((0 0 0)
               (0 999 0)
               (1 37 37)
               (3 5 15)
               (12 12 144)
               (255 257 65535)
               (12345 6789 83810205)))])
  (check-canonical
   (third case)
   (apply2 raw-nat-mult
           (integer->raw-bits (first case))
           (integer->raw-bits (second case)))))

(define division-cases
  '((0 1 0)
    (0 37 0)
    (1 1 1)
    (1 2 0)
    (7 2 3)
    (8 2 4)
    (15 4 3)
    (255 16 15)
    (256 16 16)
    (65535 255 257)
    (654321 123 5319)))

(for ([case (in-list division-cases)])
  (define dividend (first case))
  (define divisor (second case))
  (define expected (third case))
  (define quotient-bits
    (apply2 raw-nat-div
            (integer->raw-bits dividend)
            (integer->raw-bits divisor)))
  (define quotient
    (raw-bits->integer quotient-bits))
  (check-canonical expected quotient-bits)
  (check-true (<= (* quotient divisor)
                  dividend))
  (check-true (< dividend
                 (* (add1 quotient) divisor))))

(check-canonical
 2
 (apply2 raw-nat-div
         (host-bits->raw
          '(#f #f #t #f #t))
         leading-zero-two))

(define comparison-cases
  '((0 0)
    (0 1)
    (1 0)
    (1 1)
    (2 3)
    (3 2)
    (7 8)
    (8 7)
    (15 16)
    (16 15)
    (255 256)
    (256 255)
    (65535 65535)
    (123456 654321)
    (654321 123456)))

(for ([case (in-list comparison-cases)])
  (define left-integer (first case))
  (define right-integer (second case))
  (define left (integer->raw-bits left-integer))
  (define right (integer->raw-bits right-integer))
  (check-equal?
   (raw-boolean-result raw-nat-equal left right)
   (= left-integer right-integer))
  (check-equal?
   (raw-boolean-result raw-nat-less left right)
   (< left-integer right-integer))
  (check-equal?
   (raw-boolean-result raw-nat-less-equal left right)
   (<= left-integer right-integer))
  (check-equal?
   (raw-boolean-result raw-nat-greater left right)
   (> left-integer right-integer))
  (check-equal?
   (raw-boolean-result raw-nat-greater-equal left right)
   (>= left-integer right-integer)))

(check-true
 (raw-boolean-result
  raw-nat-equal
  leading-zero-two
  (integer->raw-bits 2)))

(define rejected-tail-payload
  (apply2
   raw-make-object
   list-type
   (delay
     (error 'raw-normalize-nat
            "forced payload after canonical leading one"))))

(define leading-one-with-rejected-tail-payload
  (apply2
   raw-cons
   raw-true
   rejected-tail-payload))

(check-true
 (raw-boolean->boolean
  (lazy-apply
   raw-list-head
   (lazy-apply raw-normalize-nat
               leading-one-with-rejected-tail-payload))))

(check-canonical
 0
 (apply2
  raw-nat-mult
  (delay
    (error 'raw-nat-mult
           "forced multiplicand while multiplying by zero"))
  (integer->raw-bits 0)))

(for ([function (in-list
                 (list raw-normalize-nat
                       raw-nat-is-zero
                       raw-nat-succ))])
  (check-equal?
   (procedure-arity
    (lazy-force function))
   1))

(for ([function (in-list
                 (list raw-nat-add
                       raw-nat-sub
                       raw-nat-mult
                       raw-nat-div
                       raw-nat-equal
                       raw-nat-less
                       raw-nat-less-equal
                       raw-nat-greater
                       raw-nat-greater-equal))])
  (check-equal?
   (procedure-arity
    (lazy-force function))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force
     (lazy-apply function
                 (integer->raw-bits 1))))
   1))

;; Step 32.1 structural proof: the private binary Nat arithmetic module
;; depends only on the mechanical macro layer, the fixed-point helper, raw
;; list machinery, and raw Boolean logic. It must never depend on tags,
;; objects, typed functions, effects, the codec, or the host, and every
;; binding it exports is raw machinery.

(define-runtime-path binary-nat-source-path "../core/binary-nat.rkt")

(define binary-nat-source-forms
  (call-with-input-file binary-nat-source-path
    (lambda (input)
      (read-line input)
      (for/list ([form (in-port read input)])
        form))))

(define binary-nat-source-requires
  (append-map cdr
              (filter (lambda (form)
                        (and (pair? form)
                             (eq? (car form) 'require)))
                      binary-nat-source-forms)))

(check-equal? binary-nat-source-requires
              '("../macros/macros.rkt"
                "fix.rkt"
                "lists.rkt"
                "logic.rkt"
                "pair.rkt"))

(define binary-nat-source-provides
  (append-map cdr
              (filter (lambda (form)
                        (and (pair? form)
                             (eq? (car form) 'provide)))
                      binary-nat-source-forms)))

(check-true (pair? binary-nat-source-provides))
(for ([provided (in-list binary-nat-source-provides)])
  (check-pred symbol? provided)
  (check-true (regexp-match? #rx"^raw-" (symbol->string provided))
              (format "non-raw export in binary-nat: ~s" provided)))

(define (flatten-datum-symbols datum)
  (cond
    [(symbol? datum) (list datum)]
    [(pair? datum)
     (append (flatten-datum-symbols (car datum))
             (flatten-datum-symbols (cdr datum)))]
    [else '()]))

(define binary-nat-source-symbols
  (flatten-datum-symbols binary-nat-source-forms))

(define forbidden-binary-nat-symbols
  '(raw-make-object raw-object-value raw-is-type
    make-typed-function raw-wrap-return raw-keep-return
    raw-make-ok raw-make-err
    raw-make-nat raw-nat-value
    ZERO ONE TWO THREE FOUR FIVE SIX SEVEN EIGHT NINE TEN
    host))

(for ([name (in-list binary-nat-source-symbols)])
  (check-false (memq name forbidden-binary-nat-symbols)
               (format "tagged or privileged symbol in binary-nat: ~s" name))
  (check-false (regexp-match? #rx"-type$" (symbol->string name))
               (format "type-tag symbol in binary-nat: ~s" name)))

;; Step 32.2: one binary long-division traversal yields both quotient and
;; remainder; remainder, greatest common divisor, and least common multiple
;; build on that result without changing existing division answers.

(define (div-rem-results dividend-bits divisor-bits)
  (define pair-result
    (apply2 raw-nat-div-rem dividend-bits divisor-bits))
  (values (lazy-apply raw-first pair-result)
          (lazy-apply raw-second pair-result)))

(for ([case (in-list division-cases)])
  (define dividend (first case))
  (define divisor (second case))
  (define-values (quotient-bits remainder-bits)
    (div-rem-results (integer->raw-bits dividend)
                     (integer->raw-bits divisor)))
  (check-canonical (quotient dividend divisor) quotient-bits)
  (check-canonical (remainder dividend divisor) remainder-bits)
  (check-canonical (remainder dividend divisor)
                   (apply2 raw-nat-rem
                           (integer->raw-bits dividend)
                           (integer->raw-bits divisor))))

;; Smaller dividend, exact division, nonzero remainder, zero dividend, and
;; representative larger values.
(for ([case (in-list
             '((1 2 0 1)
               (8 2 4 0)
               (7 3 2 1)
               (0 37 0 0)
               (65535 255 257 0)
               (654321 1234 530 301)
               (999999937 31607 31638 17671)))])
  (define-values (quotient-bits remainder-bits)
    (div-rem-results (integer->raw-bits (first case))
                     (integer->raw-bits (second case))))
  (check-canonical (third case) quotient-bits)
  (check-canonical (fourth case) remainder-bits))

;; Non-normalized operands still produce canonical answers.
(let-values ([(quotient-bits remainder-bits)
              (div-rem-results
               (host-bits->raw '(#f #f #t #f #t))
               leading-zero-two)])
  (check-canonical 2 quotient-bits)
  (check-canonical 1 remainder-bits))

(for ([case (in-list
             '((0 0 0)
               (0 7 7)
               (7 0 7)
               (1 1 1)
               (12 18 6)
               (18 12 6)
               (17 5 1)
               (255 256 1)
               (1071 462 21)
               (123456 654321 3)
               (259533024 46137344 32)))])
  (check-canonical
   (third case)
   (apply2 raw-nat-gcd
           (integer->raw-bits (first case))
           (integer->raw-bits (second case)))))

(check-canonical
 2
 (apply2 raw-nat-gcd
         leading-zero-two
         (host-bits->raw '(#f #t #f #f))))

;; The zero guards are the only paths that avoid dividing by a zero
;; greatest common divisor: without them, either LCM operand being zero
;; would send a zero divisor into the raw division loop.
(for ([case (in-list
             '((0 0 0)
               (0 5 0)
               (5 0 0)
               (1 1 1)
               (4 6 12)
               (6 4 12)
               (7 13 91)
               (21 6 42)
               (462 1071 23562)
               (123456 654321 26926617792)))])
  (check-canonical
   (third case)
   (apply2 raw-nat-lcm
           (integer->raw-bits (first case))
           (integer->raw-bits (second case)))))

(for ([function (in-list
                 (list raw-nat-div-rem
                       raw-nat-rem
                       raw-nat-gcd
                       raw-nat-lcm))])
  (check-equal?
   (procedure-arity
    (lazy-force function))
   1)
  (check-equal?
   (procedure-arity
    (lazy-force
     (lazy-apply function
                 (integer->raw-bits 6))))
   1))

;; Step 32.3: parity, halving, and exponentiation by repeated squaring.

(for ([case (in-list
             '((0 #f) (1 #t) (2 #f) (3 #t) (4 #f)
               (255 #t) (256 #f) (65535 #t) (65536 #f)
               (123456 #f) (654321 #t)))])
  (define value (integer->raw-bits (first case)))
  (check-equal?
   (raw-boolean->boolean (lazy-apply raw-nat-odd value))
   (second case))
  (check-equal?
   (raw-boolean->boolean (lazy-apply raw-nat-even value))
   (not (second case))))

(check-false
 (raw-boolean->boolean
  (lazy-apply raw-nat-odd leading-zero-two)))
(check-true
 (raw-boolean->boolean
  (lazy-apply raw-nat-even all-zeroes)))

(for ([case (in-list
             '((0 0) (1 0) (2 1) (3 1) (4 2) (5 2)
               (255 127) (256 128) (65535 32767)
               (654321 327160)))])
  (check-canonical
   (second case)
   (lazy-apply raw-nat-half
               (integer->raw-bits (first case)))))

(check-canonical
 1
 (lazy-apply raw-nat-half leading-zero-two))

;; Zero and one exponents, odd and even exponents, base zero and one, and
;; agreement with host exponentiation on representative values.
(for ([case (in-list
             '((0 0 1)
               (0 1 0)
               (0 5 0)
               (1 0 1)
               (5 0 1)
               (1 4096 1)
               (2 1 2)
               (2 10 1024)
               (2 16 65536)
               (3 7 2187)
               (5 5 3125)
               (10 6 1000000)
               (7 13 96889010407)))])
  (check-canonical
   (third case)
   (apply2 raw-nat-exp
           (integer->raw-bits (first case))
           (integer->raw-bits (second case)))))

(check-canonical
 9
 (apply2 raw-nat-exp
         (host-bits->raw '(#f #t #t))
         leading-zero-two))

;; A 4096-bit result in interpreted lazy evaluation is practical only with
;; the squaring recursion (twelve squarings), not one multiplication per
;; exponent decrement (4095 multiplications on growing operands).
(check-canonical
 (expt 2 4096)
 (apply2 raw-nat-exp
         (integer->raw-bits 2)
         (integer->raw-bits 4096)))

(for ([function (in-list
                 (list raw-nat-odd
                       raw-nat-even
                       raw-nat-half))])
  (check-equal?
   (procedure-arity
    (lazy-force function))
   1))

(check-equal?
 (procedure-arity
  (lazy-force raw-nat-exp))
 1)
(check-equal?
 (procedure-arity
  (lazy-force
   (lazy-apply raw-nat-exp
               (integer->raw-bits 3))))
 1)
