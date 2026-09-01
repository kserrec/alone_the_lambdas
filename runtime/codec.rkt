#lang racket/base

;; Trusted deterministic representation conversion. This module performs no
;; operating-system effect and is imported in production only by host.rkt.

(require racket/promise
         (only-in "../core/typed-nat.rkt"
                  raw-make-nat
                  raw-nat-value)
         (only-in "../core/chars.rkt"
                  raw-char-value
                  raw-make-char)
         (only-in "../core/int.rkt"
                  raw-make-int
                  raw-int-sign
                  raw-int-magnitude)
         (only-in "../core/lists.rkt"
                  NIL
                  raw-cons
                  raw-list-head
                  raw-list-tail)
         (only-in "../core/logic.rkt"
                  raw-false
                  raw-true)
         (only-in "../core/objects.rkt"
                  raw-is-type
                  raw-make-object
                  raw-object-value)
         (only-in "../core/pair.rkt"
                  raw-pair)
         (only-in "../core/rat.rkt"
                  raw-rat-numerator
                  raw-rat-denominator)
         (only-in "../core/result.rkt"
                  raw-make-err
                  raw-make-ok)
         (only-in "../core/strings.rkt"
                  raw-make-string
                  raw-string-value)
         (only-in "../core/tags.rkt"
                  char-type
                  list-type
                  nat-type
                  rat-type
                  string-type))

(provide (struct-out codec-failure)
         object-list->host-list
         host-list->object-list
         object-string->bytes
         bytes->object-string
         object-nat->integer
         integer->object-nat
         exact->object-rat
         object-rat->exact
         object-ok
         object-err)

(struct codec-failure (reason)
  #:transparent)

(define true-marker 'codec-true)
(define false-marker 'codec-false)

(define (lazy-apply function argument)
  ((force function) argument))

(define (lazy-apply2 function first second)
  (lazy-apply (lazy-apply function first) second))

(define (raw-boolean->boolean value)
  (define selected
    (force
     (lazy-apply2 value true-marker false-marker)))
  (cond
    [(eq? selected true-marker) #t]
    [(eq? selected false-marker) #f]
    [else (codec-failure 'wrong-type)]))

(define (object-has-type? expected value)
  (define decoded
    (raw-boolean->boolean
     (lazy-apply2 raw-is-type expected value)))
  (and (boolean? decoded) decoded))

(define (malformed-value-failure failure)
  (codec-failure 'wrong-type))

(define (object-list->host-list value)
  (with-handlers ([exn:fail? malformed-value-failure])
    (if (not (object-has-type? list-type value))
        (codec-failure 'wrong-type)
        (let loop ([remaining (force value)]
                   [reversed '()]
                   [seen '()])
            (cond
              [(memq remaining seen)
               (codec-failure 'wrong-type)]
              [(not (object-has-type? list-type remaining))
               (codec-failure 'wrong-type)]
              [(eq? remaining (force NIL))
               (reverse reversed)]
              [else
               (define tail
                 (force (lazy-apply raw-list-tail remaining)))
               (if (not (object-has-type? list-type tail))
                   (codec-failure 'wrong-type)
                   (loop tail
                         (cons (force
                                (lazy-apply raw-list-head remaining))
                               reversed)
                         (cons remaining seen)))])))))

(define (host-list->object-list values)
  (let loop ([remaining values])
    (if (null? remaining)
        NIL
        (lazy-apply2 raw-cons
                     (car remaining)
                     (loop (cdr remaining))))))

(define (raw-bit->boolean value)
  (with-handlers ([exn:fail? malformed-value-failure])
    (raw-boolean->boolean value)))

(define (raw-bits->integer bits-value)
  (define bits
    (object-list->host-list bits-value))
  (cond
    [(codec-failure? bits) bits]
    [(null? bits) (codec-failure 'out-of-range)]
    [else
     (define decoded
       (for/list ([bit (in-list bits)])
         (raw-bit->boolean bit)))
     (cond
       [(ormap codec-failure? decoded)
        (codec-failure 'wrong-type)]
       [(and (> (length decoded) 1)
             (not (car decoded)))
        (codec-failure 'out-of-range)]
       [else
        (for/fold ([total 0])
                  ([bit (in-list decoded)])
          (+ (* total 2)
             (if bit 1 0)))])]))

(define (raw-bits->byte bits-value)
  (define integer
    (raw-bits->integer bits-value))
  (cond
    [(codec-failure? integer) integer]
    [(<= integer 255) integer]
    [else (codec-failure 'out-of-range)]))

(define (object-char->byte value)
  (with-handlers ([exn:fail? malformed-value-failure])
    (if (object-has-type? char-type value)
        (raw-bits->byte
         (lazy-apply raw-char-value value))
        (codec-failure 'wrong-type))))

(define (first-codec-failure values)
  (cond
    [(null? values) #f]
    [(codec-failure? (car values)) (car values)]
    [else (first-codec-failure (cdr values))]))

(define (object-string->bytes value)
  (with-handlers ([exn:fail? malformed-value-failure])
    (if (not (object-has-type? string-type value))
        (codec-failure 'wrong-type)
        (let ([chars
               (object-list->host-list
                (lazy-apply raw-string-value value))])
          (if (codec-failure? chars)
              chars
              (let ([decoded
                     (for/list ([char (in-list chars)])
                       (object-char->byte char))])
                (define failure
                  (first-codec-failure decoded))
                (if failure
                    failure
                    (bytes->immutable-bytes
                     (apply bytes decoded)))))))))

(define (object-nat->integer value)
  (with-handlers ([exn:fail? malformed-value-failure])
    (if (object-has-type? nat-type value)
        (raw-bits->integer
         (lazy-apply raw-nat-value value))
        (codec-failure 'wrong-type))))

(define (integer->raw-bits integer)
  (define bits
    (if (zero? integer)
        (list #f)
        (let loop ([remaining integer]
                   [result '()])
          (if (zero? remaining)
              result
              (loop (quotient remaining 2)
                    (cons (odd? remaining) result))))))
  (host-list->object-list
   (map (lambda (bit)
          (if bit raw-true raw-false))
        bits)))

(define (byte->object-char integer)
  (lazy-apply raw-make-char
              (integer->raw-bits integer)))

(define (bytes->object-string value)
  (unless (bytes? value)
    (raise-argument-error 'bytes->object-string "bytes?" value))
  (lazy-apply
   raw-make-string
   (host-list->object-list
    (for/list ([integer (in-bytes value)])
              (byte->object-char integer)))))

(define (integer->object-nat integer)
  (unless (exact-nonnegative-integer? integer)
    (raise-argument-error 'integer->object-nat
                          "exact-nonnegative-integer?"
                          integer))
  (lazy-apply raw-make-nat
              (integer->raw-bits integer)))

;; Racket exact rationals are canonical by construction — reduced, with a
;; positive denominator — so translation builds the stored representation
;; directly and never runs object-language arithmetic.
(define (exact->object-rat value)
  (unless (and (rational? value) (exact? value))
    (raise-argument-error 'exact->object-rat
                          "(and/c rational? exact?)"
                          value))
  (lazy-apply2
   raw-make-object
   rat-type
   (lazy-apply2
    raw-pair
    (lazy-apply2 raw-make-int
                 (if (negative? value) raw-false raw-true)
                 (integer->raw-bits (abs (numerator value))))
    (integer->raw-bits (denominator value)))))

(define (object-rat->exact value)
  (with-handlers ([exn:fail? malformed-value-failure])
    (cond
      [(not (object-has-type? rat-type value))
       (codec-failure 'wrong-type)]
      [else
       (define payload
         (lazy-apply raw-object-value value))
       (define sign
         (raw-bit->boolean
          (lazy-apply raw-int-sign
                      (lazy-apply raw-rat-numerator payload))))
       (define magnitude
         (raw-bits->integer
          (lazy-apply raw-int-magnitude
                      (lazy-apply raw-rat-numerator payload))))
       (define bottom
         (raw-bits->integer
          (lazy-apply raw-rat-denominator payload)))
       (cond
         [(codec-failure? sign) sign]
         [(not (boolean? sign)) (codec-failure 'wrong-type)]
         [(codec-failure? magnitude) magnitude]
         [(codec-failure? bottom) bottom]
         [(zero? bottom) (codec-failure 'out-of-range)]
         [(and (zero? magnitude)
               (or (not sign)
                   (not (= bottom 1))))
          (codec-failure 'out-of-range)]
         [(not (= (gcd magnitude bottom) 1))
          (codec-failure 'out-of-range)]
         [sign (/ magnitude bottom)]
         [else (- (/ magnitude bottom))])])))

(define (object-ok payload)
  (lazy-apply raw-make-ok payload))

(define (object-err error-value)
  (lazy-apply raw-make-err error-value))
