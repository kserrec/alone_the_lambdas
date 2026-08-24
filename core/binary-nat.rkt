#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "fix.rkt"
         "lists.rkt"
         "logic.rkt"
         "objects.rkt"
         "tags.rkt")

(provide raw-normalize-nat
         raw-nat-is-zero
         raw-nat-succ
         raw-nat-add
         raw-nat-sub
         raw-nat-mult
         raw-nat-equal
         raw-nat-less
         raw-nat-less-equal
         raw-nat-greater
         raw-nat-greater-equal
         raw-make-nat
         raw-nat-value
         ZERO
         ONE
         TWO
         THREE
         FOUR
         FIVE
         SIX
         SEVEN
         EIGHT
         NINE
         TEN)

(def raw-zero-bits =
  ((raw-cons raw-false) NIL))

(def raw-one-bits =
  ((raw-cons raw-true) NIL))

(def raw-normalize-nat-step recur bits =
  (((raw-if
     (raw-list-is-nil bits))
    raw-zero-bits)
   (((raw-if
      (raw-list-head bits))
     bits)
    (recur (raw-list-tail bits)))))

(def raw-normalize-nat bits =
  ((raw-fix raw-normalize-nat-step) bits))

(def raw-nat-is-zero-step recur bits =
  (((raw-if
     (raw-list-is-nil bits))
    raw-true)
   (((raw-if
      (raw-list-head bits))
     raw-false)
    (recur (raw-list-tail bits)))))

(def raw-nat-is-zero bits =
  ((raw-fix raw-nat-is-zero-step) bits))

(def raw-bit-equal left right =
  (raw-not
   ((raw-xor left) right)))

(def raw-bit-list-equal-step recur left right =
  (((raw-if
     (raw-list-is-nil left))
    (raw-list-is-nil right))
   (((raw-if
      (raw-list-is-nil right))
     raw-false)
    (((raw-if
       ((raw-bit-equal
         (raw-list-head left))
        (raw-list-head right)))
      ((recur
        (raw-list-tail left))
       (raw-list-tail right)))
     raw-false))))

(def raw-bit-list-length-equal-step recur left right =
  (((raw-if
     (raw-list-is-nil left))
    (raw-list-is-nil right))
   (((raw-if
      (raw-list-is-nil right))
     raw-false)
    ((recur
      (raw-list-tail left))
     (raw-list-tail right)))))

(def raw-bit-list-length-less-step recur left right =
  (((raw-if
     (raw-list-is-nil left))
    (raw-not
     (raw-list-is-nil right)))
   (((raw-if
      (raw-list-is-nil right))
     raw-false)
    ((recur
      (raw-list-tail left))
     (raw-list-tail right)))))

(def raw-bit-list-lex-less-step recur left right =
  (((raw-if
     (raw-list-is-nil left))
    raw-false)
   (((raw-if
      ((raw-bit-equal
        (raw-list-head left))
       (raw-list-head right)))
     ((recur
       (raw-list-tail left))
      (raw-list-tail right)))
    (raw-not
     (raw-list-head left)))))

(def raw-nat-equal left right =
  (lambda-let normalized-left = (raw-normalize-nat left)
    (lambda-let normalized-right = (raw-normalize-nat right)
      (((raw-fix raw-bit-list-equal-step)
        normalized-left)
       normalized-right))))

(def raw-nat-less left right =
  (lambda-let normalized-left = (raw-normalize-nat left)
    (lambda-let normalized-right = (raw-normalize-nat right)
      (lambda-let shorter =
        (((raw-fix raw-bit-list-length-less-step)
          normalized-left)
         normalized-right)
        (((raw-if shorter)
          raw-true)
         (((raw-if
            (((raw-fix raw-bit-list-length-equal-step)
              normalized-left)
             normalized-right))
           (((raw-fix raw-bit-list-lex-less-step)
             normalized-left)
            normalized-right))
          raw-false))))))

(def raw-nat-less-equal left right =
  (raw-not
   ((raw-nat-less right) left)))

(def raw-nat-greater left right =
  ((raw-nat-less right) left))

(def raw-nat-greater-equal left right =
  (raw-not
   ((raw-nat-less left) right)))

(def raw-full-adder-sum carry left right =
  ((raw-xor carry)
   ((raw-xor left) right)))

(def raw-full-adder-carry carry left right =
  ((raw-or
    ((raw-and left) right))
   ((raw-and carry)
    ((raw-or left) right))))

(def raw-add-rest-step recur bits carry =
  (((raw-if
     (raw-list-is-nil bits))
    (((raw-if carry)
      raw-one-bits)
     NIL))
   ((raw-cons
     ((raw-xor
       (raw-list-head bits))
      carry))
    ((recur
      (raw-list-tail bits))
     ((raw-and
       (raw-list-head bits))
      carry)))))

(def raw-add-reversed-step recur left right carry =
  (((raw-if
     (raw-list-is-nil left))
    (((raw-fix raw-add-rest-step)
      right)
     carry))
   (((raw-if
      (raw-list-is-nil right))
     (((raw-fix raw-add-rest-step)
       left)
      carry))
    ((raw-cons
      (((raw-full-adder-sum carry)
        (raw-list-head left))
       (raw-list-head right)))
     (((recur
        (raw-list-tail left))
       (raw-list-tail right))
      (((raw-full-adder-carry carry)
        (raw-list-head left))
       (raw-list-head right)))))))

(def raw-nat-add left right =
  (raw-normalize-nat
   (raw-reverse
    ((((raw-fix raw-add-reversed-step)
       (raw-reverse left))
      (raw-reverse right))
     raw-false))))

(def raw-nat-succ bits =
  ((raw-nat-add bits) raw-one-bits))

(def raw-full-subtractor-difference borrow left right =
  ((raw-xor borrow)
   ((raw-xor left) right)))

(def raw-full-subtractor-borrow borrow left right =
  ((raw-or
    ((raw-and
      (raw-not left))
     ((raw-or right) borrow)))
   ((raw-and right) borrow)))

(def raw-sub-reversed-step recur left right borrow =
  (((raw-if
     (raw-list-is-nil left))
    NIL)
   (lambda-let right-empty = (raw-list-is-nil right)
     (lambda-let right-bit =
       (((raw-if right-empty)
         raw-false)
        (raw-list-head right))
       (lambda-let right-tail =
         (((raw-if right-empty)
           NIL)
          (raw-list-tail right))
         ((raw-cons
           (((raw-full-subtractor-difference borrow)
             (raw-list-head left))
            right-bit))
          (((recur
             (raw-list-tail left))
            right-tail)
           (((raw-full-subtractor-borrow borrow)
             (raw-list-head left))
            right-bit))))))))

(def raw-nat-sub left right =
  (lambda-let normalized-left = (raw-normalize-nat left)
    (lambda-let normalized-right = (raw-normalize-nat right)
      (((raw-if
         ((raw-nat-less normalized-left)
          normalized-right))
        raw-zero-bits)
       (raw-normalize-nat
        (raw-reverse
         ((((raw-fix raw-sub-reversed-step)
            (raw-reverse normalized-left))
           (raw-reverse normalized-right))
          raw-false)))))))

(def raw-nat-double bits =
  (lambda-let normalized = (raw-normalize-nat bits)
    (((raw-if
       (raw-nat-is-zero normalized))
      raw-zero-bits)
     ((raw-append normalized) raw-zero-bits))))

(def raw-nat-mult-step recur multiplicand multiplier accumulated =
  (((raw-if
     (raw-list-is-nil multiplier))
    accumulated)
   (lambda-let shifted = (raw-nat-double accumulated)
     (lambda-let next =
       (((raw-if
          (raw-list-head multiplier))
         ((raw-nat-add shifted) multiplicand))
        shifted)
       (((recur multiplicand)
         (raw-list-tail multiplier))
        next)))))

(def raw-nat-mult left right =
  ((((raw-fix raw-nat-mult-step)
     (raw-normalize-nat left))
    (raw-normalize-nat right))
   raw-zero-bits))

(def raw-make-nat bits =
  ((raw-make-object nat-type)
   (raw-normalize-nat bits)))

(def raw-nat-value nat =
  (raw-object-value nat))

(def ZERO =
  (raw-make-nat raw-zero-bits))

(def ONE =
  (raw-make-nat raw-one-bits))

(def TWO =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value ONE))))

(def THREE =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value TWO))))

(def FOUR =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value THREE))))

(def FIVE =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value FOUR))))

(def SIX =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value FIVE))))

(def SEVEN =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value SIX))))

(def EIGHT =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value SEVEN))))

(def NINE =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value EIGHT))))

(def TEN =
  (raw-make-nat
   (raw-nat-succ
    (raw-nat-value NINE))))
