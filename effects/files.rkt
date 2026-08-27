#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         (only-in "../core/errors.rkt" NIL)
         (only-in "../core/lists.rkt" raw-cons)
         "../core/strings.rkt"
         "../core/tags.rkt"
         "../core/typecheck.rkt"
         "protocol.rkt")

(provide make-read-file-request
         make-write-file-request
         make-read-file
         make-write-file)

(def file-path-signature =
  ((raw-cons string-type) NIL))

(def file-path-and-bytes-signature =
  ((raw-cons string-type)
   ((raw-cons string-type) NIL)))

(def raw-make-read-file-request path-payload =
  ((raw-cons read-file-operation)
   ((raw-cons
     (raw-make-string path-payload))
    NIL)))

(def raw-make-write-file-request path-payload bytes-payload =
  ((raw-cons write-file-operation)
   ((raw-cons
     (raw-make-string path-payload))
    ((raw-cons
      (raw-make-string bytes-payload))
     NIL))))

(def make-read-file-request =
  ((((make-typed-function raw-make-read-file-request)
     read-file-function-name)
    file-path-signature)
   raw-keep-return))

(def make-write-file-request =
  ((((make-typed-function raw-make-write-file-request)
     write-file-function-name)
    file-path-and-bytes-signature)
   raw-keep-return))

(def raw-call-read-file host path-payload =
  (host
   (raw-make-read-file-request path-payload)))

(def raw-call-write-file host path-payload bytes-payload =
  (host
   ((raw-make-write-file-request path-payload)
    bytes-payload)))

;; The real host is injected only by the future language facade. Tests can
;; inject deterministic unary fakes without adding another privileged value.
(def make-read-file host =
  ((((make-typed-function
      (raw-call-read-file host))
     read-file-function-name)
    file-path-signature)
   raw-keep-return))

(def make-write-file host =
  ((((make-typed-function
      (raw-call-write-file host))
     write-file-function-name)
    file-path-and-bytes-signature)
   raw-keep-return))
