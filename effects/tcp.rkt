#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         (only-in "../core/byte.rkt" raw-byte-list-valid?)
         (only-in "../core/errors.rkt"
                  NIL
                  raw-add-result-frame
                  invalid-count-error
                  invalid-byte-error)
         (only-in "../core/lists.rkt" raw-cons raw-list-is-nil)
         (only-in "../core/logic.rkt" raw-if raw-and)
         (only-in "../core/objects.rkt" raw-is-type raw-make-object)
         (only-in "../core/rat.rkt" raw-rat-is-nonnegative-whole)
         "../core/strings.rkt"
         "../core/tags.rkt"
         "../core/typecheck.rkt"
         "protocol.rkt")

(provide make-tcp-connect-request
         make-tcp-listen-request
         make-tcp-accept-request
         make-tcp-read-request
         make-tcp-write-request
         make-tcp-close-request
         make-tcp-connect
         make-tcp-listen
         make-tcp-accept
         make-tcp-read
         make-tcp-write
         make-tcp-close)

;; Rat-based request constructors and wrappers (the Step 35.5 public
;; switch). Ports, backlog sizes, read limits, and handles arrive as
;; Rat objects; pure lambda computation verifies each is a nonnegative
;; whole number before any request exists, so an invalid field is an
;; INVALID-COUNT Error and the host is never applied. Numeric request
;; fields carry tagged Rat values for the deterministic codec boundary.

(def string-and-rat-signature =
  ((raw-cons string-type)
   ((raw-cons rat-type) NIL)))

(def string-and-two-rats-signature =
  ((raw-cons string-type)
   ((raw-cons rat-type)
    ((raw-cons rat-type) NIL))))

(def rat-signature =
  ((raw-cons rat-type) NIL))

(def two-rats-signature =
  ((raw-cons rat-type)
   ((raw-cons rat-type) NIL)))

(def rat-and-list-signature =
  ((raw-cons rat-type)
   ((raw-cons list-type) NIL)))

(def raw-rebuild-list payload =
  (lambda-let rebuilt = ((raw-make-object list-type) payload)
    (((raw-if
       (raw-list-is-nil rebuilt))
      NIL)
     rebuilt)))

(def raw-rat-field payload =
  ((raw-make-object rat-type) payload))

(def raw-make-tcp-connect-request remote-payload port-payload =
  (((raw-if
     (raw-rat-is-nonnegative-whole port-payload))
    ((raw-cons tcp-connect-operation)
     ((raw-cons
       (raw-make-string remote-payload))
      ((raw-cons
        (raw-rat-field port-payload))
       NIL))))
   ((raw-add-result-frame invalid-count-error)
    tcp-connect-function-name)))

(def raw-make-tcp-listen-request local-payload port-payload backlog-payload =
  (((raw-if
     ((raw-and
       (raw-rat-is-nonnegative-whole port-payload))
      (raw-rat-is-nonnegative-whole backlog-payload)))
    ((raw-cons tcp-listen-operation)
     ((raw-cons
       (raw-make-string local-payload))
      ((raw-cons
        (raw-rat-field port-payload))
       ((raw-cons
         (raw-rat-field backlog-payload))
        NIL)))))
   ((raw-add-result-frame invalid-count-error)
    tcp-listen-function-name)))

(def raw-make-tcp-accept-request listener-payload =
  (((raw-if
     (raw-rat-is-nonnegative-whole listener-payload))
    ((raw-cons tcp-accept-operation)
     ((raw-cons
       (raw-rat-field listener-payload))
      NIL)))
   ((raw-add-result-frame invalid-count-error)
    tcp-accept-function-name)))

(def raw-make-tcp-read-request connection-payload maximum-payload =
  (((raw-if
     ((raw-and
       (raw-rat-is-nonnegative-whole connection-payload))
      (raw-rat-is-nonnegative-whole maximum-payload)))
    ((raw-cons tcp-read-operation)
     ((raw-cons
       (raw-rat-field connection-payload))
      ((raw-cons
        (raw-rat-field maximum-payload))
       NIL))))
   ((raw-add-result-frame invalid-count-error)
    tcp-read-function-name)))

;; The byte List is validated in pure lambda computation before any
;; request value exists, so a non-Byte element never reaches the host.
(def raw-make-tcp-write-request connection-payload list-payload =
  (((raw-if
     (raw-rat-is-nonnegative-whole connection-payload))
    (lambda-let bytes = (raw-rebuild-list list-payload)
      (((raw-if
         (raw-byte-list-valid? bytes))
        ((raw-cons tcp-write-operation)
         ((raw-cons
           (raw-rat-field connection-payload))
          ((raw-cons bytes)
           NIL))))
       ((raw-add-result-frame invalid-byte-error)
        tcp-write-function-name))))
   ((raw-add-result-frame invalid-count-error)
    tcp-write-function-name)))

(def raw-make-tcp-close-request handle-payload =
  (((raw-if
     (raw-rat-is-nonnegative-whole handle-payload))
    ((raw-cons tcp-close-operation)
     ((raw-cons
       (raw-rat-field handle-payload))
      NIL)))
   ((raw-add-result-frame invalid-count-error)
    tcp-close-function-name)))

(def make-tcp-connect-request =
  ((((make-typed-function raw-make-tcp-connect-request)
     tcp-connect-function-name)
    string-and-rat-signature)
   raw-keep-return))

(def make-tcp-listen-request =
  ((((make-typed-function raw-make-tcp-listen-request)
     tcp-listen-function-name)
    string-and-two-rats-signature)
   raw-keep-return))

(def make-tcp-accept-request =
  ((((make-typed-function raw-make-tcp-accept-request)
     tcp-accept-function-name)
    rat-signature)
   raw-keep-return))

(def make-tcp-read-request =
  ((((make-typed-function raw-make-tcp-read-request)
     tcp-read-function-name)
    two-rats-signature)
   raw-keep-return))

(def make-tcp-write-request =
  ((((make-typed-function raw-make-tcp-write-request)
     tcp-write-function-name)
    rat-and-list-signature)
   raw-keep-return))

(def make-tcp-close-request =
  ((((make-typed-function raw-make-tcp-close-request)
     tcp-close-function-name)
    rat-signature)
   raw-keep-return))

(def raw-dispatch-or-bubble host request =
  (((raw-if
     ((raw-is-type error-type) request))
    request)
   (host request)))

(def raw-call-tcp-connect host remote-payload port-payload =
  ((raw-dispatch-or-bubble host)
   ((raw-make-tcp-connect-request remote-payload)
    port-payload)))

(def raw-call-tcp-listen host local-payload port-payload backlog-payload =
  ((raw-dispatch-or-bubble host)
   (((raw-make-tcp-listen-request local-payload)
     port-payload)
    backlog-payload)))

(def raw-call-tcp-accept host listener-payload =
  ((raw-dispatch-or-bubble host)
   (raw-make-tcp-accept-request listener-payload)))

(def raw-call-tcp-read host connection-payload maximum-payload =
  ((raw-dispatch-or-bubble host)
   ((raw-make-tcp-read-request connection-payload)
    maximum-payload)))

(def raw-call-tcp-write host connection-payload bytes-payload =
  ((raw-dispatch-or-bubble host)
   ((raw-make-tcp-write-request connection-payload)
    bytes-payload)))

(def raw-call-tcp-close host handle-payload =
  ((raw-dispatch-or-bubble host)
   (raw-make-tcp-close-request handle-payload)))

(def make-tcp-connect host =
  ((((make-typed-function
      (raw-call-tcp-connect host))
     tcp-connect-function-name)
    string-and-rat-signature)
   raw-keep-return))

(def make-tcp-listen host =
  ((((make-typed-function
      (raw-call-tcp-listen host))
     tcp-listen-function-name)
    string-and-two-rats-signature)
   raw-keep-return))

(def make-tcp-accept host =
  ((((make-typed-function
      (raw-call-tcp-accept host))
     tcp-accept-function-name)
    rat-signature)
   raw-keep-return))

(def make-tcp-read host =
  ((((make-typed-function
      (raw-call-tcp-read host))
     tcp-read-function-name)
    two-rats-signature)
   raw-keep-return))

(def make-tcp-write host =
  ((((make-typed-function
      (raw-call-tcp-write host))
     tcp-write-function-name)
    rat-and-list-signature)
   raw-keep-return))

(def make-tcp-close host =
  ((((make-typed-function
      (raw-call-tcp-close host))
     tcp-close-function-name)
    rat-signature)
   raw-keep-return))
