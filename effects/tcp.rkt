#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         (only-in "../core/typed-nat.rkt" raw-make-nat)
         (only-in "../core/errors.rkt" NIL)
         (only-in "../core/lists.rkt" raw-cons)
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

(def string-and-nat-signature =
  ((raw-cons string-type)
   ((raw-cons nat-type) NIL)))

(def string-and-two-nats-signature =
  ((raw-cons string-type)
   ((raw-cons nat-type)
    ((raw-cons nat-type) NIL))))

(def nat-signature =
  ((raw-cons nat-type) NIL))

(def two-nats-signature =
  ((raw-cons nat-type)
   ((raw-cons nat-type) NIL)))

(def nat-and-string-signature =
  ((raw-cons nat-type)
   ((raw-cons string-type) NIL)))

(def raw-make-tcp-connect-request remote-payload port-payload =
  ((raw-cons tcp-connect-operation)
   ((raw-cons
     (raw-make-string remote-payload))
    ((raw-cons
      (raw-make-nat port-payload))
     NIL))))

(def raw-make-tcp-listen-request local-payload port-payload backlog-payload =
  ((raw-cons tcp-listen-operation)
   ((raw-cons
     (raw-make-string local-payload))
    ((raw-cons
      (raw-make-nat port-payload))
     ((raw-cons
       (raw-make-nat backlog-payload))
      NIL)))))

(def raw-make-tcp-accept-request listener-payload =
  ((raw-cons tcp-accept-operation)
   ((raw-cons
     (raw-make-nat listener-payload))
    NIL)))

(def raw-make-tcp-read-request connection-payload maximum-payload =
  ((raw-cons tcp-read-operation)
   ((raw-cons
     (raw-make-nat connection-payload))
    ((raw-cons
      (raw-make-nat maximum-payload))
     NIL))))

(def raw-make-tcp-write-request connection-payload bytes-payload =
  ((raw-cons tcp-write-operation)
   ((raw-cons
     (raw-make-nat connection-payload))
    ((raw-cons
      (raw-make-string bytes-payload))
     NIL))))

(def raw-make-tcp-close-request handle-payload =
  ((raw-cons tcp-close-operation)
   ((raw-cons
     (raw-make-nat handle-payload))
    NIL)))

(def make-tcp-connect-request =
  ((((make-typed-function raw-make-tcp-connect-request)
     tcp-connect-function-name)
    string-and-nat-signature)
   raw-keep-return))

(def make-tcp-listen-request =
  ((((make-typed-function raw-make-tcp-listen-request)
     tcp-listen-function-name)
    string-and-two-nats-signature)
   raw-keep-return))

(def make-tcp-accept-request =
  ((((make-typed-function raw-make-tcp-accept-request)
     tcp-accept-function-name)
    nat-signature)
   raw-keep-return))

(def make-tcp-read-request =
  ((((make-typed-function raw-make-tcp-read-request)
     tcp-read-function-name)
    two-nats-signature)
   raw-keep-return))

(def make-tcp-write-request =
  ((((make-typed-function raw-make-tcp-write-request)
     tcp-write-function-name)
    nat-and-string-signature)
   raw-keep-return))

(def make-tcp-close-request =
  ((((make-typed-function raw-make-tcp-close-request)
     tcp-close-function-name)
    nat-signature)
   raw-keep-return))

(def raw-call-tcp-connect host remote-payload port-payload =
  (host
   ((raw-make-tcp-connect-request remote-payload)
    port-payload)))

(def raw-call-tcp-listen host local-payload port-payload backlog-payload =
  (host
   (((raw-make-tcp-listen-request local-payload)
     port-payload)
    backlog-payload)))

(def raw-call-tcp-accept host listener-payload =
  (host
   (raw-make-tcp-accept-request listener-payload)))

(def raw-call-tcp-read host connection-payload maximum-payload =
  (host
   ((raw-make-tcp-read-request connection-payload)
    maximum-payload)))

(def raw-call-tcp-write host connection-payload bytes-payload =
  (host
   ((raw-make-tcp-write-request connection-payload)
    bytes-payload)))

(def raw-call-tcp-close host handle-payload =
  (host
   (raw-make-tcp-close-request handle-payload)))

;; Each public wrapper remains ordinary lambda computation. The standalone
;; language will inject the sole real host; tests inject deterministic fakes.
(def make-tcp-connect host =
  ((((make-typed-function
      (raw-call-tcp-connect host))
     tcp-connect-function-name)
    string-and-nat-signature)
   raw-keep-return))

(def make-tcp-listen host =
  ((((make-typed-function
      (raw-call-tcp-listen host))
     tcp-listen-function-name)
    string-and-two-nats-signature)
   raw-keep-return))

(def make-tcp-accept host =
  ((((make-typed-function
      (raw-call-tcp-accept host))
     tcp-accept-function-name)
    nat-signature)
   raw-keep-return))

(def make-tcp-read host =
  ((((make-typed-function
      (raw-call-tcp-read host))
     tcp-read-function-name)
    two-nats-signature)
   raw-keep-return))

(def make-tcp-write host =
  ((((make-typed-function
      (raw-call-tcp-write host))
     tcp-write-function-name)
    nat-and-string-signature)
   raw-keep-return))

(def make-tcp-close host =
  ((((make-typed-function
      (raw-call-tcp-close host))
     tcp-close-function-name)
    nat-signature)
   raw-keep-return))
