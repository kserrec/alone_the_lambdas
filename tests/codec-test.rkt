#lang racket/base

(require rackunit
         (only-in racket/list range)
         racket/promise
         (only-in "../core/typed-nat.rkt"
                  raw-nat-value)
         "../core/chars.rkt"
         "../core/errors.rkt"
         "../core/lists.rkt"
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/pair.rkt"
         "../core/result.rkt"
         "../core/strings.rkt"
         "../core/tags.rkt"
         (only-in "../core/typed-logic.rkt" TRUE)
         "../readers/bool.rkt"
         "../readers/raw-boolean.rkt"
         "../runtime/codec.rkt"
         "helpers/lazy.rkt")

(define (apply2 function first second)
  (lazy-apply (lazy-apply function first) second))

(define (typed-value? type value)
  (raw-boolean->boolean
   (apply2 raw-is-type type value)))

(define (failure-reason value)
  (and (codec-failure? value)
       (codec-failure-reason value)))

(define every-byte
  (apply bytes (range 256)))

(define every-char
  (bytes->object-string every-byte))

(check-true (immutable? (object-string->bytes every-char)))
(check-equal? (object-string->bytes every-char)
              every-byte)

(for ([sample (in-list (list #""
                             #"\0"
                             #"A\0B"
                             #"\377\200\0\177"))])
  (define encoded (bytes->object-string sample))
  (check-true (typed-value? string-type encoded))
  (check-equal? (object-string->bytes encoded)
                sample))

;; Encoding copies host bytes into pure lambda values; later mutation of the
;; source byte string cannot alter the object-language String.
(define mutable-source (bytes 65 0 255))
(define copied-string (bytes->object-string mutable-source))
(bytes-set! mutable-source 0 66)
(check-equal? (object-string->bytes copied-string)
              #"A\0\377")

(define two-values
  (list A TRUE))
(define object-list
  (host-list->object-list two-values))
(define decoded-list
  (object-list->host-list object-list))

(check-true (typed-value? list-type object-list))
(check-equal? (length decoded-list) 2)
(check-true (typed-value? char-type (car decoded-list)))
(check-true (typed-value? bool-type (cadr decoded-list)))
(check-equal? (object-list->host-list NIL) '())

(check-equal? (failure-reason (object-list->host-list TRUE))
              'wrong-type)
(check-equal? (failure-reason (object-string->bytes TRUE))
              'wrong-type)

(define malformed-string-payload
  (lazy-apply raw-make-string TRUE))
(check-equal? (failure-reason
               (object-string->bytes malformed-string-payload))
              'wrong-type)

(define wrong-element-string
  (lazy-apply
   raw-make-string
   (host-list->object-list (list TRUE))))
(check-equal? (failure-reason
               (object-string->bytes wrong-element-string))
              'wrong-type)

(define improper-char-list
  (apply2 raw-make-object
          list-type
          (apply2 raw-pair A TRUE)))
(define improper-string
  (lazy-apply raw-make-string improper-char-list))
(check-equal? (failure-reason
               (object-string->bytes improper-string))
              'wrong-type)

(define malformed-tag
  (lambda (step)
    (lambda (seed)
      (lambda (ignored) ignored))))
(define malformed-tail
  (apply2 raw-make-object malformed-tag raw-false))
(define malformed-list-predicate
  (apply2 raw-make-object
          list-type
          (apply2 raw-pair A malformed-tail)))
(check-equal? (failure-reason
               (object-list->host-list malformed-list-predicate))
              'wrong-type)

;; Only the one canonical NIL object terminates a decoded List. A forged cell
;; with an ordinary value in its head and an unrelated Error in its tail is
;; malformed; it must not be mistaken for an empty List and silently truncate.
(define false-nil-list
  (apply2 raw-make-object
          list-type
          (apply2 raw-pair A invalid-nat-error)))
(check-equal? (failure-reason
               (object-list->host-list false-nil-list))
              'wrong-type)
(check-equal? (failure-reason
               (object-string->bytes
                (lazy-apply raw-make-string false-nil-list)))
              'wrong-type)

(define (bits->raw bits)
  (host-list->object-list
   (map (lambda (bit)
          (if bit raw-true raw-false))
        bits)))

(define leading-zero-char
  (apply2 raw-make-object
          char-type
          (bits->raw '(#f #t))))
(define leading-zero-string
  (lazy-apply
   raw-make-string
   (host-list->object-list (list leading-zero-char))))
(check-equal? (failure-reason
               (object-string->bytes leading-zero-string))
              'out-of-range)

(define char-256
  (lazy-apply raw-make-char
              (bits->raw '(#t #f #f #f #f #f #f #f #f))))
(define out-of-range-string
  (lazy-apply
   raw-make-string
   (host-list->object-list (list char-256))))
(check-equal? (failure-reason
               (object-string->bytes out-of-range-string))
              'out-of-range)

;; Nat conversion is exact in both directions, including the protocol bounds
;; and values larger than any current host request needs.
(for ([sample (in-list (list 0
                             1
                             255
                             256
                             65535
                             65536
                             (expt 2 80)))])
  (define encoded (integer->object-nat sample))
  (check-true (typed-value? nat-type encoded))
  (check-equal? (object-nat->integer encoded)
                sample))

(define (object-nat-bits value)
  (map raw-boolean->boolean
       (object-list->host-list
        (lazy-apply raw-nat-value value))))

(check-equal? (object-nat-bits (integer->object-nat 0))
              '(#f))
(check-equal? (object-nat-bits (integer->object-nat 1))
              '(#t))
(check-equal? (object-nat-bits (integer->object-nat 256))
              '(#t #f #f #f #f #f #f #f #f))

(check-equal? (failure-reason (object-nat->integer TRUE))
              'wrong-type)
(check-equal?
 (failure-reason
  (object-nat->integer
   (apply2 raw-make-object nat-type NIL)))
 'out-of-range)
(check-equal?
 (failure-reason
  (object-nat->integer
   (apply2 raw-make-object
           nat-type
           (bits->raw '(#f #t)))))
 'out-of-range)
(check-equal?
 (failure-reason
  (object-nat->integer
   (apply2 raw-make-object
           nat-type
           (host-list->object-list (list TRUE)))))
 'wrong-type)

(define improper-bit-list
  (apply2 raw-make-object
          list-type
          (apply2 raw-pair raw-true TRUE)))
(check-equal?
 (failure-reason
  (object-nat->integer
   (apply2 raw-make-object nat-type improper-bit-list)))
 'wrong-type)

(check-exn exn:fail:contract?
           (lambda ()
             (integer->object-nat -1)))
(check-exn exn:fail:contract?
           (lambda ()
             (integer->object-nat 1/2)))

(define ok-nil (object-ok NIL))
(check-true (typed-value? result-type ok-nil))
(check-true (bool->boolean (lazy-apply is-ok ok-nil)))
(check-true (bool->boolean
             (lazy-apply typed-is-nil
                         (lazy-apply unwrap-ok ok-nil))))

(define err-invalid-nat (object-err invalid-nat-error))
(check-true (typed-value? result-type err-invalid-nat))
(check-true (bool->boolean
             (lazy-apply is-err err-invalid-nat)))
(check-true (typed-value?
             error-type
             (lazy-apply unwrap-err err-invalid-nat)))

(check-exn exn:fail:contract?
           (lambda ()
             (bytes->object-string "not bytes")))

;; Step 35.2: exact Racket numbers translate to canonical Rat values and
;; back; inexact and non-real numbers are rejected; forged noncanonical
;; representations never decode.

(require (only-in "../core/int.rkt" raw-make-int)
         (only-in "../core/rat.rkt" raw-make-rat)
         (only-in "../readers/rat.rkt" rat->number))

(define (object-rat-payload value)
  (lazy-apply raw-object-value value))

(for ([exact (in-list '(0 1 -1 2 -2 1/2 -1/2 7/3 -7/3 123456/7
                        -123456/7 255 65536 -654321
                        1606938044258990275541962092341162602522202993782792835301376))])
  (define value (exact->object-rat exact))
  (check-true (typed-value? rat-type value))
  (check-equal? (rat->number (object-rat-payload value)) exact)
  (check-equal? (object-rat->exact value) exact))

;; Inexact and non-rational numbers are rejected before construction.
(for ([bad (in-list (list 1.5 -0.0 1e3 +inf.0 +nan.0 2+3i))])
  (check-exn exn:fail:contract?
             (lambda ()
               (exact->object-rat bad))))

;; Wrong tags and forged noncanonical payloads are codec failures.
(check-pred codec-failure? (object-rat->exact TRUE))

(define (forged-rat numerator-int denominator-bits)
  (apply2 raw-make-object
          rat-type
          (apply2 raw-pair numerator-int denominator-bits)))

(define (host-integer->bits integer)
  (let loop ([remaining integer]
             [result NIL])
    (if (zero? remaining)
        result
        (loop (quotient remaining 2)
              (apply2 raw-cons
                      (if (odd? remaining) raw-true raw-false)
                      result)))))

(define (host-integer->int integer)
  (apply2 raw-make-int
          (if (negative? integer) raw-false raw-true)
          (host-integer->bits (abs integer))))

;; Unreduced 2/4.
(check-pred codec-failure?
            (object-rat->exact
             (forged-rat (host-integer->int 2)
                         (host-integer->bits 4))))

;; Negative zero numerator.
(check-pred codec-failure?
            (object-rat->exact
             (forged-rat (apply2 raw-make-int
                                 raw-true
                                 (host-integer->bits 0))
                         (host-integer->bits 5))))

;; Zero denominator.
(check-pred codec-failure?
            (object-rat->exact
             (forged-rat (host-integer->int 1)
                         (apply2 raw-cons raw-false NIL))))

;; Non-normalized denominator bits (leading zero).
(check-pred codec-failure?
            (object-rat->exact
             (forged-rat (host-integer->int 1)
                         (apply2 raw-cons
                                 raw-false
                                 (apply2 raw-cons raw-true NIL)))))

;; A genuinely canonical constructed value decodes.
(check-equal?
 (object-rat->exact
  (forged-rat (host-integer->int -3)
              (host-integer->bits 2)))
 -3/2)
