#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         (only-in "../core/binary-nat.rkt"
                  raw-nat-less)
         (only-in "../core/byte.rkt"
                  raw-bytes-to-chars
                  raw-chars-to-bytes)
         (only-in "../core/list-nat.rkt"
                  raw-list-length)
         (only-in "../core/errors.rkt"
                  NIL
                  raw-error-kind-equal
                  raw-error-root
                  raw-error-root-kind
                  raw-make-root-error)
         "../core/fix.rkt"
         (only-in "../core/lists.rkt"
                  raw-cons
                  raw-list-is-nil)
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
   ((raw-cons rat-type)
    ((raw-cons string-type)
     ((raw-cons rat-type)
      ((raw-cons string-type)
       ((raw-cons string-type) NIL)))))))

(def two-rats-signature =
  ((raw-cons rat-type)
   ((raw-cons rat-type) NIL)))

;; Applying the first five arguments yields the ordinary unary request
;; handler. Only the selected status/body branch reaches the pure renderer.
(def raw-rat-object payload =
  ((raw-make-object rat-type) payload))

(def raw-render-selected-http-response status-payload body-payload =
  ((render-http-response
    (raw-rat-object status-payload))
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

;; A hostile peer can open one connection and stream bytes that never form a
;; complete request header (and never close). Without a bound, the read loop
;; below would buffer without limit and re-parse the whole buffer after every
;; partial read, so one client could exhaust process memory. This caps the
;; accumulated request size; 8192 (2^13, one then thirteen zero bits) is far
;; larger than any request this bodyless GET server needs. The size is checked
;; before each parse, so no parse ever runs on more than this many bytes and
;; the peak buffer is this cap plus at most one read. The loop therefore always
;; terminates and memory is bounded.
;;
;; Residual, deliberately not closed here: within the cap the whole buffer is
;; still re-parsed after every partial read, so a peer that dribbles tiny
;; chunks pays O(cap^2) interpreter work on its one connection before rejection.
;; That is bounded work with no new capability beyond this deliberately blocking
;; single-connection server's already-documented "one client can tie it up"
;; behavior; fully removing it needs an incremental parser (a redesign of the
;; read/parse loop), tracked in PLAN.md, not a spot fix.
(def raw-max-request-bytes-bits =
  ((raw-cons raw-true) ((raw-cons raw-false) ((raw-cons raw-false) ((raw-cons raw-false) ((raw-cons raw-false) ((raw-cons raw-false) ((raw-cons raw-false) ((raw-cons raw-false) ((raw-cons raw-false) ((raw-cons raw-false) ((raw-cons raw-false) ((raw-cons raw-false) ((raw-cons raw-false) ((raw-cons raw-false) NIL)))))))))))))))

(def raw-request-too-large? combined =
  ((raw-nat-less raw-max-request-bytes-bits)
   (raw-list-length combined)))

;; An over-limit request is a rejected expected outcome, reported as the same
;; malformed-request Result the parser already produces; the caller then closes
;; the connection exactly as it does for any other parse failure.
(def raw-request-too-large-result =
  (raw-make-err
   (raw-make-root-error malformed-http-request-kind)))

;; TCP reads may split a request anywhere. Accumulation, the incomplete check,
;; and reparsing all remain String/List/lambda computation. The buffer is
;; bounded above so a never-completing request cannot grow without limit or be
;; parsed at unbounded size.
(def raw-read-http-request-step recur host connection maximum accumulated =
  (lambda-let read-result =
    (((make-tcp-read host)
      connection)
     maximum)
    ((raw-bind-result read-result)
     (lambda (chunk)
       (lambda-let chunk-chars =
         (raw-bytes-to-chars chunk)
        (lambda-let combined =
         ((raw-string-append accumulated)
          chunk-chars)
         (((raw-if
            (raw-request-too-large? combined))
           raw-request-too-large-result)
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
                  (raw-list-is-nil chunk))
                 parsed)
                ((((recur host)
                   connection)
                  maximum)
                 combined)))
              parsed))))))))))

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
             (raw-chars-to-bytes
              (raw-string-value response)))))))
      (((raw-complete-http-connection host)
        connection)
       outcome))))

;; The caller owns the listener. This operation owns exactly the connection it
;; accepts and closes that connection on every completed path.
(def raw-http-serve-one host handler listener-payload maximum-payload =
  ((raw-bind-result
    ((make-tcp-accept host)
     (raw-rat-object listener-payload)))
   (lambda (connection)
     ((((raw-handle-http-connection host)
        handler)
       connection)
      (raw-rat-object maximum-payload)))))

(def make-http-serve-one host handler =
  ((((make-typed-function
      ((raw-http-serve-one host) handler))
     http-serve-one-function-name)
    two-rats-signature)
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
    two-rats-signature)
   raw-keep-return))
