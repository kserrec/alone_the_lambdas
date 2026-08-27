#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         (only-in "../core/errors.rkt" NIL)
         (only-in "../core/lists.rkt" raw-cons)
         "../core/strings.rkt"
         "../core/tags.rkt"
         "../core/typecheck.rkt"
         "protocol.rkt")

(provide make-stdout-request
         make-stdout)

(def stdout-string-signature =
  ((raw-cons string-type) NIL))

(def raw-make-stdout-request string-payload =
  ((raw-cons stdout-operation)
   ((raw-cons
     (raw-make-string string-payload))
    NIL)))

(def make-stdout-request =
  ((((make-typed-function raw-make-stdout-request)
     stdout-function-name)
    stdout-string-signature)
   raw-keep-return))

(def raw-call-stdout host string-payload =
  (host
   (raw-make-stdout-request string-payload)))

;; The real host is injected only by the future language facade. Tests inject
;; a deterministic unary fake without granting another privileged primitive.
(def make-stdout host =
  ((((make-typed-function
      (raw-call-stdout host))
     stdout-function-name)
    stdout-string-signature)
   raw-keep-return))
