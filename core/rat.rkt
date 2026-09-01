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
         "int.rkt"
         "logic.rkt"
         "pair.rkt")

(provide raw-make-rat
         raw-rat-numerator
         raw-rat-denominator
         raw-rat-zero
         raw-rat-one)

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
