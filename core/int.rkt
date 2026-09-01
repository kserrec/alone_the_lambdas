#lang s-exp "../macros/lazy-with-macros.rkt"

;; Private signed integers: a raw untagged pair of a raw Boolean sign
;; (raw-true means nonnegative) and a normalized binary Nat magnitude.
;; Every supported construction routes through raw-make-int, which turns
;; any attempted negative zero into positive zero, so Int zero has exactly
;; one representation. Int is Rat's numerator machinery only: it has no
;; type tag, no typed layer, no literal, and no language export.

(require "../macros/macros.rkt"
         "binary-nat.rkt"
         "logic.rkt"
         "pair.rkt")

(provide raw-make-int
         raw-int-sign
         raw-int-magnitude
         raw-int-zero
         raw-int-one
         raw-int-is-zero
         raw-int-negate
         raw-int-abs)

(def raw-make-int sign magnitude =
  (lambda-let normalized = (raw-normalize-nat magnitude)
    (((raw-if
       (raw-nat-is-zero normalized))
      ((raw-pair raw-true) raw-zero-bits))
     ((raw-pair sign) normalized))))

(def raw-int-sign int =
  (raw-first int))

(def raw-int-magnitude int =
  (raw-second int))

(def raw-int-zero =
  ((raw-pair raw-true) raw-zero-bits))

(def raw-int-one =
  ((raw-pair raw-true) raw-one-bits))

(def raw-int-is-zero int =
  (raw-nat-is-zero
   (raw-int-magnitude int)))

(def raw-int-negate int =
  ((raw-make-int
    (raw-not (raw-int-sign int)))
   (raw-int-magnitude int)))

(def raw-int-abs int =
  ((raw-make-int raw-true)
   (raw-int-magnitude int)))
