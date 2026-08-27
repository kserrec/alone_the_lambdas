#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         (only-in "../core/binary-nat.rkt"
                  raw-make-nat)
         (only-in "../core/errors.rkt"
                  NIL
                  raw-error-kind-equal
                  raw-error-root
                  raw-error-root-kind
                  raw-make-root-error)
         "../core/fix.rkt"
         (only-in "../core/lists.rkt"
                  raw-cons)
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/result.rkt"
         "../core/strings.rkt"
         "../core/tags.rkt"
         "../core/typecheck.rkt"
         "http.rkt"
         "http-response.rkt"
         "tcp.rkt")

(provide invalid-http-handler-result-kind
         make-http-path-handler
         make-http-serve-one
         make-http-server)

;; Handler contract:
;;
;;   String target -> Result String
;;
;; The Ok String is the complete response produced by render-http-response.
;; Keeping that contract at the lambda layer prevents either the server or the
;; host from interpreting routes, statuses, bodies, or HTTP framing.
(def invalid-http-handler-result-kind =
  (church-succ unsupported-http-status-kind))

(def invalid-http-handler-result-error =
  (raw-make-root-error invalid-http-handler-result-kind))

(def raw-name-char bits =
  ((raw-make-object char-type) bits))

(def raw-name-string chars =
  ((raw-make-object string-type) chars))

(define-function-name http-path-handler-function-name http-path-handler)
(define-function-name http-serve-one-function-name http-serve-one)
(define-function-name http-server-function-name http-server)

(def http-path-handler-signature =
  ((raw-cons string-type)
   ((raw-cons nat-type)
    ((raw-cons string-type)
     ((raw-cons nat-type)
      ((raw-cons string-type)
       ((raw-cons string-type) NIL)))))))

(def two-nats-signature =
  ((raw-cons nat-type)
   ((raw-cons nat-type) NIL)))

;; Applying the first five arguments yields the ordinary unary request
;; handler. Only the selected status/body branch reaches the pure renderer.
(def raw-render-selected-http-response status-payload body-payload =
  ((render-http-response
    (raw-make-nat status-payload))
   (raw-make-string body-payload)))

(def raw-make-http-path-handler expected-target-payload
                                matched-status-payload
                                matched-body-payload
                                fallback-status-payload
                                fallback-body-payload
                                target-payload =
  (((raw-if
     ((raw-string-equal target-payload)
      expected-target-payload))
    ((raw-render-selected-http-response
      matched-status-payload)
     matched-body-payload))
   ((raw-render-selected-http-response
     fallback-status-payload)
    fallback-body-payload)))

(def make-http-path-handler =
  ((((make-typed-function raw-make-http-path-handler)
     http-path-handler-function-name)
    http-path-handler-signature)
   raw-keep-return))

;; Internal Result sequencing is ordinary lambda control flow. Every internal
;; producer is either a strict wrapper, parser, renderer, or this module's
;; validated handler boundary, so a non-Error value here is a Result.
(def raw-bind-result result on-ok =
  (((raw-if
     ((raw-is-type error-type) result))
    result)
   (((raw-if
      (raw-result-is-ok
       (raw-object-value result)))
     (on-ok
      (raw-result-value
       (raw-object-value result))))
    result)))

(def raw-http-parse-incomplete? result =
  ((raw-error-kind-equal
    (raw-error-root-kind
     (raw-error-root
      (raw-result-value
       (raw-object-value result)))))
   incomplete-http-request-kind))

;; TCP reads may split a request anywhere. Accumulation, the incomplete check,
;; and reparsing all remain String/List/lambda computation.
(def raw-read-http-request-step recur host connection maximum accumulated =
  (lambda-let read-result =
    (((make-tcp-read host)
      connection)
     maximum)
    ((raw-bind-result read-result)
     (lambda (chunk)
       (lambda-let combined =
         ((raw-string-append accumulated)
          (raw-string-value chunk))
         (lambda-let parsed =
           (parse-http-request
            (raw-make-string combined))
           (((raw-if
              (raw-result-is-ok
               (raw-object-value parsed)))
             parsed)
            (((raw-if
               (raw-http-parse-incomplete? parsed))
              (((raw-if
                 (raw-string-empty?
                  (raw-string-value chunk)))
                parsed)
               ((((recur host)
                  connection)
                 maximum)
                combined)))
             parsed))))))))

(def raw-read-http-request =
  (raw-fix raw-read-http-request-step))

;; A handler may propagate a contract Error, return an expected Err, or return
;; Ok response bytes. Any other tagged shape is an invariant failure and never
;; reaches tcp-write.
(def raw-use-http-handler-result handler-result on-response =
  (((raw-if
     ((raw-is-type error-type) handler-result))
    handler-result)
   (((raw-if
      ((raw-is-type result-type) handler-result))
     (lambda-let payload =
       (raw-result-value
        (raw-object-value handler-result))
       (((raw-if
          (raw-result-is-ok
           (raw-object-value handler-result)))
         (((raw-if
            ((raw-is-type string-type) payload))
           (on-response payload))
          invalid-http-handler-result-error))
        (((raw-if
           ((raw-is-type error-type) payload))
          handler-result)
         invalid-http-handler-result-error))))
    invalid-http-handler-result-error)))

;; Inspecting cleanup-result forces the close request. The caller's original
;; failure remains primary when both the operation and cleanup fail.
(def raw-preserve-after-cleanup cleanup-result original =
  (((raw-if
     ((raw-is-type error-type) cleanup-result))
    original)
   (((raw-if
      (raw-result-is-ok
       (raw-object-value cleanup-result)))
     original)
    original)))

(def raw-complete-http-connection host connection outcome =
  (lambda-let close-result =
    ((make-tcp-close host) connection)
    (((raw-if
       ((raw-is-type error-type) outcome))
      ((raw-preserve-after-cleanup close-result)
       outcome))
     (((raw-if
        (raw-result-is-ok
         (raw-object-value outcome)))
       close-result)
      ((raw-preserve-after-cleanup close-result)
       outcome)))))

(def raw-handle-http-connection host handler connection maximum =
  (lambda-let request-result =
    ((((raw-read-http-request host)
       connection)
      maximum)
     NIL)
    (lambda-let outcome =
      ((raw-bind-result request-result)
       (lambda (target)
         ((raw-use-http-handler-result
           (handler target))
          (lambda (response)
            (((make-tcp-write host)
              connection)
             response)))))
      (((raw-complete-http-connection host)
        connection)
       outcome))))

;; The caller owns the listener. This operation owns exactly the connection it
;; accepts and closes that connection on every completed path.
(def raw-http-serve-one host handler listener-payload maximum-payload =
  ((raw-bind-result
    ((make-tcp-accept host)
     (raw-make-nat listener-payload)))
   (lambda (connection)
     ((((raw-handle-http-connection host)
        handler)
       connection)
      (raw-make-nat maximum-payload)))))

(def make-http-serve-one host handler =
  ((((make-typed-function
      ((raw-http-serve-one host) handler))
     http-serve-one-function-name)
    two-nats-signature)
   raw-keep-return))

;; Successful connections are processed one at a time. The first accept,
;; network, parse, rendering, handler, or cleanup failure ends the loop with
;; that Error/Result; successful serving intentionally does not terminate.
(def raw-http-server-step recur host handler listener-payload maximum-payload =
  ((raw-bind-result
    ((((raw-http-serve-one host)
       handler)
      listener-payload)
     maximum-payload))
   (lambda (ignored)
     ((((recur host)
        handler)
       listener-payload)
      maximum-payload))))

(def raw-http-server =
  (raw-fix raw-http-server-step))

(def make-http-server host handler =
  ((((make-typed-function
      ((raw-http-server host) handler))
     http-server-function-name)
    two-nats-signature)
   raw-keep-return))
