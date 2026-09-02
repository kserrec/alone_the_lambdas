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
         raw-int-abs
         raw-int-succ
         raw-int-pred
         raw-int-add
         raw-int-sub
         raw-int-mult
         raw-int-equal
         raw-int-less
         raw-int-less-equal
         raw-int-greater
         raw-int-greater-equal
         raw-int-odd
         raw-int-even)

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

(def raw-sign-equal left right =
  (raw-not
   ((raw-xor left) right)))

(def raw-int-add left right =
  (lambda-let left-sign = (raw-int-sign left)
    (lambda-let right-sign = (raw-int-sign right)
      (lambda-let left-magnitude = (raw-int-magnitude left)
        (lambda-let right-magnitude = (raw-int-magnitude right)
          (((raw-if
             ((raw-sign-equal left-sign) right-sign))
            ((raw-make-int left-sign)
             ((raw-nat-add left-magnitude) right-magnitude)))
           (((raw-if
              ((raw-nat-greater-equal left-magnitude) right-magnitude))
             ((raw-make-int left-sign)
              ((raw-nat-sub left-magnitude) right-magnitude)))
            ((raw-make-int right-sign)
             ((raw-nat-sub right-magnitude) left-magnitude)))))))))

(def raw-int-sub left right =
  ((raw-int-add left)
   (raw-int-negate right)))

(def raw-int-succ int =
  ((raw-int-add int) raw-int-one))

(def raw-int-pred int =
  ((raw-int-sub int) raw-int-one))

(def raw-int-mult left right =
  ((raw-make-int
    ((raw-sign-equal
      (raw-int-sign left))
     (raw-int-sign right)))
   ((raw-nat-mult
     (raw-int-magnitude left))
    (raw-int-magnitude right))))

(def raw-int-equal left right =
  ((raw-and
    ((raw-sign-equal
      (raw-int-sign left))
     (raw-int-sign right)))
   ((raw-nat-equal
     (raw-int-magnitude left))
    (raw-int-magnitude right))))

(def raw-int-less left right =
  (lambda-let left-sign = (raw-int-sign left)
    (lambda-let right-sign = (raw-int-sign right)
      (((raw-if
         ((raw-sign-equal left-sign) right-sign))
        (((raw-if left-sign)
          ((raw-nat-less
            (raw-int-magnitude left))
           (raw-int-magnitude right)))
         ((raw-nat-less
           (raw-int-magnitude right))
          (raw-int-magnitude left))))
       (raw-not left-sign)))))

(def raw-int-less-equal left right =
  (raw-not
   ((raw-int-less right) left)))

(def raw-int-greater left right =
  ((raw-int-less right) left))

(def raw-int-greater-equal left right =
  (raw-not
   ((raw-int-less left) right)))

(def raw-int-odd int =
  (raw-nat-odd
   (raw-int-magnitude int)))

(def raw-int-even int =
  (raw-nat-even
   (raw-int-magnitude int)))
