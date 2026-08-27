#lang racket/base

;; The one production bridge to the outside world. Phase 14 deliberately
;; implements only stdout; later approved phases extend this closed dispatcher.

(require racket/promise
         (only-in "../core/errors.rkt" NIL)
         (only-in "../core/strings.rkt" EMPTY-STRING)
         (only-in "../effects/protocol.rkt"
                  io-failure-code
                  make-host-bridge
                  make-host-failure
                  make-invalid-host-request
                  out-of-range-reason
                  stdout-operation
                  unknown-operation-reason
                  wrong-arity-reason
                  wrong-type-reason)
         (only-in "codec.rkt"
                  bytes->object-string
                  codec-failure-reason
                  codec-failure?
                  object-err
                  object-list->host-list
                  object-ok
                  object-string->bytes))

(provide host)

(define (lazy-apply function argument)
  ((force function) argument))

(define (lazy-apply2 function first second)
  (lazy-apply (lazy-apply function first) second))

(define (reason->object reason)
  (case reason
    [(out-of-range) out-of-range-reason]
    [else wrong-type-reason]))

(define (invalid-request operation reason)
  (lazy-apply2 make-invalid-host-request operation reason))

(define (invalid-codec-request operation failure)
  (invalid-request operation
                   (reason->object
                    (codec-failure-reason failure))))

(define (stdout-failure)
  (object-err
   (lazy-apply2 make-host-failure
                stdout-operation
                io-failure-code)))

(define (perform-stdout payload)
  (with-handlers ([exn:fail?
                   (lambda (failure)
                     (stdout-failure))])
    (define output (current-output-port))
    (write-bytes payload output)
    (flush-output output)
    (object-ok NIL)))

(define (dispatch-request request)
  (define decoded-request
    (object-list->host-list request))
  (cond
    [(codec-failure? decoded-request)
     (invalid-codec-request EMPTY-STRING decoded-request)]
    [(not (= (length decoded-request) 2))
     (invalid-request EMPTY-STRING wrong-arity-reason)]
    [else
     (define operation-value (car decoded-request))
     (define operation-bytes
       (object-string->bytes operation-value))
     (cond
       [(codec-failure? operation-bytes)
        (invalid-codec-request EMPTY-STRING operation-bytes)]
       [(not (bytes=? operation-bytes #"stdout"))
        (invalid-request
         (bytes->object-string operation-bytes)
         unknown-operation-reason)]
       [else
        (define payload
          (object-string->bytes
           (cadr decoded-request)))
        (if (codec-failure? payload)
            (invalid-codec-request stdout-operation payload)
            (perform-stdout payload))])]))

(define host
  (lazy-apply make-host-bridge dispatch-request))
