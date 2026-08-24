#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt")

(provide raw-fix)

(def raw-fix function =
  ((lambda (self)
     (function (self self)))
   (lambda (self)
     (function (self self)))))
