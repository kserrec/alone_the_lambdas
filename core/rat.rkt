#lang s-exp "../macros/lazy-with-macros.rkt"

;; Private exact rationals: a raw untagged pair of a private Int numerator
;; and a positive normalized binary Nat denominator. Every supported
;; construction routes through raw-make-rat, which reduces by the greatest
;; common divisor and forces every zero to positive 0/1, so equal rational
;; values have exactly one stored representation. A zero denominator is an
;; internal invariant failure, never a value: like raw division, the raw
;; constructor's contract requires a nonzero denominator, and every
;; supported entry path guards zero before construction. The strict layer
;; added in Phase 35 owns the public zero policy.

(require "../macros/macros.rkt"
         "binary-nat.rkt"
         (only-in "errors.rkt"
                  divide-by-zero-error
                  non-whole-exponent-error)
         "int.rkt"
         "logic.rkt"
         "pair.rkt"
         (only-in "result.rkt"
                  raw-make-ok
                  raw-make-err))

(provide raw-make-rat
         raw-rat-numerator
         raw-rat-denominator
         raw-rat-zero
         raw-rat-one
         raw-rat-negate
         raw-rat-abs
         raw-rat-succ
         raw-rat-add
         raw-rat-sub
         raw-rat-mult
         raw-rat-equal
         raw-rat-less
         raw-rat-less-equal
         raw-rat-greater
         raw-rat-greater-equal
         raw-rat-is-zero
         raw-rat-is-whole
         raw-rat-is-nonnegative-whole
         raw-rat-floor
         raw-rat-recip
         raw-rat-div
         raw-rat-exp)

(def raw-make-rat numerator denominator =
  (lambda-let normalized-denominator = (raw-normalize-nat denominator)
    (lambda-let magnitude = (raw-int-magnitude numerator)
      (lambda-let common-divisor =
        ((raw-nat-gcd magnitude) normalized-denominator)
        ((raw-pair
          ((raw-make-int
            (raw-int-sign numerator))
           ((raw-nat-div magnitude) common-divisor)))
         ((raw-nat-div normalized-denominator) common-divisor))))))

(def raw-rat-numerator rat =
  (raw-first rat))

(def raw-rat-denominator rat =
  (raw-second rat))

(def raw-rat-zero =
  ((raw-pair raw-int-zero) raw-one-bits))

(def raw-rat-one =
  ((raw-pair raw-int-one) raw-one-bits))

(def raw-rat-denominator-int rat =
  ((raw-make-int raw-true)
   (raw-rat-denominator rat)))

(def raw-rat-negate rat =
  ((raw-make-rat
    (raw-int-negate
     (raw-rat-numerator rat)))
   (raw-rat-denominator rat)))

(def raw-rat-abs rat =
  ((raw-make-rat
    (raw-int-abs
     (raw-rat-numerator rat)))
   (raw-rat-denominator rat)))

(def raw-rat-add left right =
  ((raw-make-rat
    ((raw-int-add
      ((raw-int-mult
        (raw-rat-numerator left))
       (raw-rat-denominator-int right)))
     ((raw-int-mult
       (raw-rat-numerator right))
      (raw-rat-denominator-int left))))
   ((raw-nat-mult
     (raw-rat-denominator left))
    (raw-rat-denominator right))))

(def raw-rat-sub left right =
  ((raw-rat-add left)
   (raw-rat-negate right)))

(def raw-rat-succ rat =
  ((raw-rat-add rat) raw-rat-one))

(def raw-rat-mult left right =
  ((raw-make-rat
    ((raw-int-mult
      (raw-rat-numerator left))
     (raw-rat-numerator right)))
   ((raw-nat-mult
     (raw-rat-denominator left))
    (raw-rat-denominator right))))

(def raw-rat-equal left right =
  ((raw-and
    ((raw-int-equal
      (raw-rat-numerator left))
     (raw-rat-numerator right)))
   ((raw-nat-equal
     (raw-rat-denominator left))
    (raw-rat-denominator right))))

(def raw-rat-less left right =
  ((raw-int-less
    ((raw-int-mult
      (raw-rat-numerator left))
     (raw-rat-denominator-int right)))
   ((raw-int-mult
     (raw-rat-numerator right))
    (raw-rat-denominator-int left))))

(def raw-rat-less-equal left right =
  (raw-not
   ((raw-rat-less right) left)))

(def raw-rat-greater left right =
  ((raw-rat-less right) left))

(def raw-rat-greater-equal left right =
  (raw-not
   ((raw-rat-less left) right)))

(def raw-rat-is-zero rat =
  (raw-int-is-zero
   (raw-rat-numerator rat)))

(def raw-rat-is-whole rat =
  ((raw-nat-equal
    (raw-rat-denominator rat))
   raw-one-bits))

(def raw-rat-is-nonnegative-whole rat =
  ((raw-and
    (raw-rat-is-whole rat))
   (raw-int-sign
    (raw-rat-numerator rat))))

(def raw-rat-floor rat =
  (lambda-let numerator = (raw-rat-numerator rat)
    (lambda-let division =
      ((raw-nat-div-rem
        (raw-int-magnitude numerator))
       (raw-rat-denominator rat))
      (lambda-let quotient-int =
        ((raw-make-int
          (raw-int-sign numerator))
         (raw-first division))
        ((raw-make-rat
          (((raw-if
             ((raw-or
               (raw-int-sign numerator))
              (raw-nat-is-zero
               (raw-second division))))
            quotient-int)
           (raw-int-pred quotient-int)))
         raw-one-bits)))))

(def raw-rat-flip rat =
  ((raw-make-rat
    ((raw-make-int
      (raw-int-sign
       (raw-rat-numerator rat)))
     (raw-rat-denominator rat)))
   (raw-int-magnitude
    (raw-rat-numerator rat))))

(def raw-rat-recip rat =
  (((raw-if
     (raw-rat-is-zero rat))
    (raw-make-err divide-by-zero-error))
   (raw-make-ok
    (raw-rat-flip rat))))

(def raw-rat-div left right =
  (((raw-if
     (raw-rat-is-zero right))
    (raw-make-err divide-by-zero-error))
   (raw-make-ok
    ((raw-rat-mult left)
     (raw-rat-flip right)))))

(def raw-rat-whole-power rat magnitude =
  ((raw-make-rat
    ((raw-make-int
      ((raw-or
        (raw-int-sign
         (raw-rat-numerator rat)))
       (raw-nat-even magnitude)))
     ((raw-nat-exp
       (raw-int-magnitude
        (raw-rat-numerator rat)))
      magnitude)))
   ((raw-nat-exp
     (raw-rat-denominator rat))
    magnitude)))

(def raw-rat-exp base exponent =
  (((raw-if
     (raw-not
      (raw-rat-is-whole exponent)))
    (raw-make-err non-whole-exponent-error))
   (lambda-let exponent-int = (raw-rat-numerator exponent)
     (lambda-let magnitude = (raw-int-magnitude exponent-int)
       (((raw-if
          (raw-int-sign exponent-int))
         (raw-make-ok
          ((raw-rat-whole-power base) magnitude)))
        (((raw-if
           (raw-rat-is-zero base))
          (raw-make-err divide-by-zero-error))
         (raw-make-ok
          (raw-rat-flip
           ((raw-rat-whole-power base) magnitude)))))))))
