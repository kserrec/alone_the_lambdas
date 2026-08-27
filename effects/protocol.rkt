#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         (only-in "../core/errors.rkt"
                  NIL
                  raw-make-error
                  raw-make-error-root)
         (only-in "../core/lists.rkt"
                  raw-cons
                  raw-list-head
                  raw-list-is-nil
                  raw-list-tail)
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/pair.rkt"
         "../core/strings.rkt"
         "../core/tags.rkt"
         "../core/typecheck.rkt")

(provide invalid-host-request-kind
         host-failure-kind
         host-function-name
         stdout-function-name
         read-file-function-name
         write-file-function-name
         stdout-operation
         read-file-operation
         write-file-operation
         unknown-operation-reason
         wrong-arity-reason
         wrong-type-reason
         out-of-range-reason
         not-found-code
         permission-denied-code
         invalid-path-code
         invalid-text-code
         resource-exhausted-code
         timed-out-code
         io-failure-code
         make-invalid-host-request
         make-host-failure
         make-host-bridge)

;; Error kinds 0 through 6 are owned by the completed core. Host protocol
;; failures extend only the approved tiny metadata namespace; they do not add
;; object-language types or ordinary numeric values.
(def invalid-host-request-kind =
  (church-succ church-six))

(def host-failure-kind =
  (church-succ invalid-host-request-kind))

(def raw-name-char bits =
  ((raw-make-object char-type) bits))

(def raw-name-string chars =
  ((raw-make-object string-type) chars))

(define-function-name host-function-name host)
(define-function-name stdout-function-name stdout)
(define-function-name read-file-function-name read-file)
(define-function-name write-file-function-name write-file)
(define-function-name stdout-operation stdout)
(define-function-name read-file-operation read-file)
(define-function-name write-file-operation write-file)

(define-function-name unknown-operation-reason unknown-operation)
(define-function-name wrong-arity-reason wrong-arity)
(define-function-name wrong-type-reason wrong-type)
(define-function-name out-of-range-reason out-of-range)

(define-function-name not-found-code not-found)
(define-function-name permission-denied-code permission-denied)
(define-function-name invalid-path-code invalid-path)
(define-function-name invalid-text-code invalid-text)
(define-function-name resource-exhausted-code resource-exhausted)
(define-function-name timed-out-code timed-out)
(define-function-name io-failure-code io-failure)

(def raw-make-host-protocol-error kind operation detail =
  ((raw-make-error
    ((raw-make-error-root kind)
     ((raw-pair operation) detail)))
   NIL))

(def make-invalid-host-request operation reason =
  (((raw-make-host-protocol-error invalid-host-request-kind)
    operation)
   reason))

(def make-host-failure operation code =
  (((raw-make-host-protocol-error host-failure-kind)
    operation)
   code))

(def raw-list-object payload =
  ((raw-make-object list-type) payload))

(def host-list-signature =
  ((raw-cons list-type) NIL))

(def raw-invalid-request operation reason =
  ((make-invalid-host-request operation) reason))

(def raw-dispatch-one-string dispatcher request operation arguments =
  (((raw-if
     ((raw-is-type list-type) arguments))
    (((raw-if
       (raw-list-is-nil arguments))
      ((raw-invalid-request operation)
       wrong-arity-reason))
     (lambda-let bytes =
       (raw-list-head arguments)
       (((raw-if
          ((raw-is-type string-type) bytes))
         (lambda-let trailing =
           (raw-list-tail arguments)
           (((raw-if
              ((raw-is-type list-type) trailing))
             (((raw-if
                (raw-list-is-nil trailing))
               (dispatcher request))
              ((raw-invalid-request operation)
               wrong-arity-reason)))
            ((raw-invalid-request operation)
             wrong-type-reason))))
        ((raw-invalid-request operation)
         wrong-type-reason)))))
   ((raw-invalid-request operation)
    wrong-type-reason)))

(def raw-dispatch-two-strings dispatcher request operation arguments =
  (((raw-if
     ((raw-is-type list-type) arguments))
    (((raw-if
       (raw-list-is-nil arguments))
      ((raw-invalid-request operation)
       wrong-arity-reason))
     (lambda-let first =
       (raw-list-head arguments)
       (((raw-if
          ((raw-is-type string-type) first))
         (lambda-let remaining =
           (raw-list-tail arguments)
           (((raw-if
              ((raw-is-type list-type) remaining))
             (((raw-if
                (raw-list-is-nil remaining))
               ((raw-invalid-request operation)
                wrong-arity-reason))
              (lambda-let second =
                (raw-list-head remaining)
                (((raw-if
                   ((raw-is-type string-type) second))
                  (lambda-let trailing =
                    (raw-list-tail remaining)
                    (((raw-if
                       ((raw-is-type list-type) trailing))
                      (((raw-if
                         (raw-list-is-nil trailing))
                        (dispatcher request))
                       ((raw-invalid-request operation)
                        wrong-arity-reason)))
                     ((raw-invalid-request operation)
                      wrong-type-reason))))
                 ((raw-invalid-request operation)
                  wrong-type-reason)))))
            ((raw-invalid-request operation)
             wrong-type-reason))))
        ((raw-invalid-request operation)
         wrong-type-reason)))))
   ((raw-invalid-request operation)
    wrong-type-reason)))

(def raw-dispatch-known-operation dispatcher request operation arguments =
  (((raw-if
     ((raw-string-equal
       (raw-string-value operation))
      (raw-string-value stdout-operation)))
    ((((raw-dispatch-one-string dispatcher)
       request)
      operation)
     arguments))
   (((raw-if
      ((raw-string-equal
        (raw-string-value operation))
       (raw-string-value read-file-operation)))
     ((((raw-dispatch-one-string dispatcher)
        request)
       operation)
      arguments))
    (((raw-if
       ((raw-string-equal
         (raw-string-value operation))
        (raw-string-value write-file-operation)))
      ((((raw-dispatch-two-strings dispatcher)
         request)
        operation)
       arguments))
     ((raw-invalid-request operation)
      unknown-operation-reason)))))

(def raw-validate-host-request dispatcher request =
  (((raw-if
     (raw-list-is-nil request))
    ((raw-invalid-request EMPTY-STRING)
     wrong-arity-reason))
   (lambda-let operation =
     (raw-list-head request)
     (((raw-if
        ((raw-is-type string-type) operation))
       (lambda-let arguments =
         (raw-list-tail request)
         (((raw-if
            ((raw-is-type list-type) arguments))
           ((((raw-dispatch-known-operation dispatcher)
              request)
             operation)
            arguments))
          ((raw-invalid-request operation)
           wrong-type-reason))))
      ((raw-invalid-request EMPTY-STRING)
       wrong-type-reason)))))

(def raw-host-function dispatcher request-payload =
  ((raw-validate-host-request dispatcher)
   (raw-list-object request-payload)))

;; The resulting value is the sole unary object-language boundary. Validation
;; above is ordinary lambda computation; only a schema-valid request reaches
;; the injected strict dispatcher.
(def make-host-bridge dispatcher =
  ((((make-typed-function
      (raw-host-function dispatcher))
     host-function-name)
    host-list-signature)
   raw-keep-return))
