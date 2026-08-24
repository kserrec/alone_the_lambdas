#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "logic.rkt")

(provide church-zero
         church-succ
         church-one
         church-two
         church-three
         church-four
         church-five
         church-six
         error-type
         bool-type
         list-type
         nat-type
         result-type
         char-type
         string-type
         raw-tag-equal)

(def church-zero step seed =
  seed)

(def church-succ numeral step seed =
  (step ((numeral step) seed)))

(def church-one =
  (church-succ church-zero))

(def church-two =
  (church-succ church-one))

(def church-three =
  (church-succ church-two))

(def church-four =
  (church-succ church-three))

(def church-five =
  (church-succ church-four))

(def church-six =
  (church-succ church-five))

(def error-type = church-zero)
(def bool-type = church-one)
(def list-type = church-two)
(def nat-type = church-three)
(def result-type = church-four)
(def char-type = church-five)
(def string-type = church-six)

(def raw-church-is-zero numeral =
  ((numeral
    (lambda (ignored)
      raw-false))
   raw-true))

(def raw-church-predecessor numeral step seed =
  (((numeral
     (lambda (next)
       (lambda (previous)
         (previous (next step)))))
    (lambda (ignored)
      seed))
   (lambda (value)
     value)))

(def raw-church-subtract left right =
  ((right raw-church-predecessor) left))

(def raw-tag-equal left right =
  ((raw-and
    (raw-church-is-zero
     ((raw-church-subtract left) right)))
   (raw-church-is-zero
    ((raw-church-subtract right) left))))
