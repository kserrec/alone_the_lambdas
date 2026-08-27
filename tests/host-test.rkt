#lang racket/base

(require rackunit
         racket/promise
         "../core/errors.rkt"
         "../core/lists.rkt"
         "../core/objects.rkt"
         "../core/pair.rkt"
         "../core/result.rkt"
         "../core/strings.rkt"
         "../core/tags.rkt"
         (only-in "../core/typed-logic.rkt"
                  FALSE
                  TRUE
                  typed-if)
         "../effects/protocol.rkt"
         "../effects/stdout.rkt"
         "../readers/bool.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/type-tag.rkt"
         "../runtime/codec.rkt"
         "../runtime/host.rkt"
         "helpers/lazy.rkt")

(define (apply2 function first second)
  (lazy-apply (lazy-apply function first) second))

(define (apply3 function first second third)
  (lazy-apply (apply2 function first second) third))

(define (typed-value? type value)
  (raw-boolean->boolean
   (apply2 raw-is-type type value)))

(define (error-kind-integer error)
  (type-tag->integer
   (lazy-apply raw-error-root-kind
               (lazy-apply raw-error-root error))))

(define (error-detail-strings error)
  (define details
    (lazy-apply
     raw-error-root-details
     (lazy-apply raw-error-root error)))
  (list
   (object-string->bytes
    (lazy-apply raw-first details))
   (object-string->bytes
    (lazy-apply raw-second details))))

(define (check-invalid-request value operation reason)
  (check-true (typed-value? error-type value))
  (check-equal? (error-kind-integer value) 7)
  (check-equal? (error-detail-strings value)
                (list operation reason)))

(define stdout-request
  (lazy-apply make-stdout-request
              (bytes->object-string #"A\0\377")))

(check-equal? (procedure-arity (lazy-force host)) 1)

;; Applying host is lazy. The effect happens once when the Result is forced,
;; and forcing that same promise again reuses the cached Result.
(define output (open-output-bytes))
(define pending
  (parameterize ([current-output-port output])
    (lazy-apply host stdout-request)))

(check-equal? (get-output-bytes output) #"")
(parameterize ([current-output-port output])
  (check-true (bool->boolean
               (lazy-apply is-ok pending))))
(check-equal? (get-output-bytes output)
              #"A\0\377")
(parameterize ([current-output-port output])
  (check-true (bool->boolean
               (lazy-apply is-ok pending))))
(check-equal? (get-output-bytes output)
              #"A\0\377")
(check-true (bool->boolean
             (lazy-apply typed-is-nil
                         (lazy-apply unwrap-ok pending))))

;; A host application in an unselected object-language branch remains
;; unforced and performs no output.
(define skipped-output (open-output-bytes))
(define skipped-host-call
  (lazy-apply host stdout-request))
(define selected-fallback
  (apply3 typed-if
          FALSE
          skipped-host-call
          (object-ok NIL)))
(parameterize ([current-output-port skipped-output])
  (check-true (bool->boolean
               (lazy-apply is-ok selected-fallback))))
(check-equal? (get-output-bytes skipped-output) #"")

;; Empty output is still a successful, flushed acknowledgement.
(define empty-output (open-output-bytes))
(define empty-result
  (parameterize ([current-output-port empty-output])
    (lazy-force
     (lazy-apply
      host
      (lazy-apply make-stdout-request
                  (bytes->object-string #""))))))
(check-true (bool->boolean
             (lazy-apply is-ok empty-result)))
(check-equal? (get-output-bytes empty-output) #"")

;; A valid request whose output port fails maps to Result Err HostFailure.
(define closed-output (open-output-bytes))
(close-output-port closed-output)
(define failed-output
  (parameterize ([current-output-port closed-output])
    (lazy-force
     (lazy-apply
      host
      (lazy-apply make-stdout-request
                  (bytes->object-string #"failure"))))))

(check-true (typed-value? result-type failed-output))
(check-true (bool->boolean
             (lazy-apply is-err failed-output)))
(define host-failure
  (lazy-apply unwrap-err failed-output))
(check-equal? (error-kind-integer host-failure) 8)
(check-equal? (error-detail-strings host-failure)
              (list #"stdout" #"io-failure"))

;; The outer strict List contract remains the generalized core contract.
(define non-list-output (open-output-bytes))
(define non-list-result
  (parameterize ([current-output-port non-list-output])
    (lazy-force (lazy-apply host TRUE))))
(check-true (typed-value? error-type non-list-result))
(check-equal? (error-kind-integer non-list-result) 0)
(check-equal? (get-output-bytes non-list-output) #"")

(define incoming-error-output (open-output-bytes))
(define incoming-error-result
  (parameterize ([current-output-port incoming-error-output])
    (lazy-force (lazy-apply host invalid-nat-error))))
(check-true (typed-value? error-type incoming-error-result))
(check-equal? (error-kind-integer incoming-error-result) 2)
(check-equal? (get-output-bytes incoming-error-output) #"")

(check-invalid-request
 (lazy-force (lazy-apply host NIL))
 #""
 #"wrong-arity")

(check-invalid-request
 (lazy-force
  (lazy-apply host
              (host-list->object-list
               (list TRUE
                     (bytes->object-string #"bytes")))))
 #""
 #"wrong-type")

(check-invalid-request
 (lazy-force
  (lazy-apply host
              (host-list->object-list
               (list (bytes->object-string #"unknown")
                     (bytes->object-string #"bytes")))))
 #"unknown"
 #"unknown-operation")

(check-invalid-request
 (lazy-force
  (lazy-apply host
              (host-list->object-list
               (list stdout-operation))))
 #"stdout"
 #"wrong-arity")

(check-invalid-request
 (lazy-force
  (lazy-apply host
              (host-list->object-list
               (list stdout-operation TRUE))))
 #"stdout"
 #"wrong-type")

(check-invalid-request
 (lazy-force
  (lazy-apply host
              (host-list->object-list
               (list stdout-operation
                     (bytes->object-string #"bytes")
                     TRUE))))
 #"stdout"
 #"wrong-arity")

;; A forged String tag passes the pure schema type test, then the defensive
;; codec rejects its non-Char element before stdout is touched.
(define malformed-string
  (lazy-apply
   raw-make-string
   (host-list->object-list (list TRUE))))
(define untouched-output (open-output-bytes))
(define malformed-result
  (parameterize ([current-output-port untouched-output])
    (lazy-force
     (lazy-apply host
                 (host-list->object-list
                  (list stdout-operation malformed-string))))))
(check-invalid-request malformed-result
                       #"stdout"
                       #"wrong-type")
(check-equal? (get-output-bytes untouched-output) #"")
