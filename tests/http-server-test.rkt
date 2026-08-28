#lang racket/base

(require rackunit
         net/http-client
         racket/port
         racket/promise
         "../core/errors.rkt"
         "../core/lists.rkt"
         "../core/objects.rkt"
         "../core/result.rkt"
         "../core/strings.rkt"
         "../core/tags.rkt"
         (only-in "../core/typed-logic.rkt"
                  TRUE)
         "../effects/http-response.rkt"
         "../effects/http-server.rkt"
         "../effects/tcp.rkt"
         "../readers/bool.rkt"
         "../readers/raw-boolean.rkt"
         "../readers/type-tag.rkt"
         "../runtime/codec.rkt"
         "../runtime/host.rkt"
         "helpers/lazy.rkt")

(define (apply2 function first second)
  (lazy-apply
   (lazy-apply function first)
   second))

(define (apply3 function first second third)
  (lazy-apply
   (apply2 function first second)
   third))

(define (apply-arguments function arguments)
  (if (null? arguments)
      function
      (apply-arguments
       (lazy-apply function (car arguments))
       (cdr arguments))))

(define (typed-value? type value)
  (raw-boolean->boolean
   (apply2 raw-is-type type value)))

(define (error-kind-integer error)
  (type-tag->integer
   (lazy-apply raw-error-root-kind
               (lazy-apply raw-error-root error))))

(define (first-error-frame error)
  (car
   (object-list->host-list
    (lazy-apply raw-error-frames error))))

(define (check-contract-error value expected-name position expected-type)
  (check-true (typed-value? error-type value))
  (check-equal? (error-kind-integer value) 0)
  (define frame (first-error-frame value))
  (check-equal?
   (object-string->bytes
    (lazy-apply raw-error-frame-function-name frame))
   expected-name)
  (check-equal?
   (type-tag->integer
    (lazy-apply raw-error-frame-argument-position frame))
   position)
  (check-equal?
   (type-tag->integer
    (lazy-apply raw-error-frame-expected-type frame))
   expected-type))

(define (check-ok-nil value)
  (check-true (typed-value? result-type value))
  (check-true (bool->boolean
               (lazy-apply is-ok value)))
  (check-true (bool->boolean
               (lazy-apply typed-is-nil
                           (lazy-apply unwrap-ok value)))))

(define (check-result-err-kind value expected-kind)
  (check-true (typed-value? result-type value))
  (check-true (bool->boolean
               (lazy-apply is-err value)))
  (define failure
    (lazy-apply unwrap-err value))
  (check-true (typed-value? error-type failure))
  (check-equal? (error-kind-integer failure)
                expected-kind))

(define (check-response-bytes value expected)
  (check-true (typed-value? result-type value))
  (check-true (bool->boolean
               (lazy-apply is-ok value)))
  (check-equal?
   (object-string->bytes
    (lazy-apply unwrap-ok value))
   expected))

(define route-target
  (bytes->object-string #"/lambda"))
(define matched-body
  (bytes->object-string #"lambda says hello"))
(define fallback-body
  (bytes->object-string #"missing"))
(define listener-handle
  (integer->object-nat 1))
(define connection-handle
  (integer->object-nat 2))
(define maximum
  (integer->object-nat 65536))

(define (make-path-handler matched-status fallback-status)
  (apply-arguments
   make-http-path-handler
   (list route-target
         matched-status
         matched-body
         fallback-status
         fallback-body)))

(define handler
  (make-path-handler HTTP-STATUS-OK
                     HTTP-STATUS-NOT-FOUND))

;; The first five applications construct a pure unary request handler. It
;; routes by the parsed target and renders only its selected status/body.
(check-equal? (procedure-arity (lazy-force handler)) 1)
(check-response-bytes
 (lazy-apply handler route-target)
 #"HTTP/1.1 200 OK\r\nContent-Length: 17\r\nConnection: close\r\n\r\nlambda says hello")
(check-response-bytes
 (lazy-apply handler
             (bytes->object-string #"/elsewhere"))
 #"HTTP/1.1 404 Not Found\r\nContent-Length: 7\r\nConnection: close\r\n\r\nmissing")

;; An unsupported unselected status is not rendered. Selecting it preserves
;; the renderer's expected Result Err instead of introducing a host failure.
(define lazy-branch-handler
  (make-path-handler HTTP-STATUS-OK
                     (integer->object-nat 201)))
(check-response-bytes
 (lazy-apply lazy-branch-handler route-target)
 #"HTTP/1.1 200 OK\r\nContent-Length: 17\r\nConnection: close\r\n\r\nlambda says hello")
(check-result-err-kind
 (lazy-apply lazy-branch-handler
             (bytes->object-string #"/other"))
 12)

;; The handler factory uses the generalized checker across all six curried
;; positions, including the final target accepted by the produced handler.
(define wrong-handler-first
  (lazy-apply make-http-path-handler TRUE))
(define absorbed-handler-first
  (apply-arguments
   wrong-handler-first
   (list HTTP-STATUS-OK
         matched-body
         HTTP-STATUS-NOT-FOUND
         fallback-body
         route-target)))
(check-contract-error absorbed-handler-first
                      #"http-path-handler"
                      1
                      6)

(check-contract-error
 (lazy-apply handler TRUE)
 #"http-path-handler"
 6
 6)

(define incoming-handler-error
  (apply-arguments
   (lazy-apply make-http-path-handler invalid-nat-error)
   (list HTTP-STATUS-OK
         matched-body
         HTTP-STATUS-NOT-FOUND
         fallback-body
         route-target)))
(check-true (typed-value? error-type incoming-handler-error))
(check-equal? (error-kind-integer incoming-handler-error) 2)

;; Fake hosts return a scripted response for each forced TCP request and retain
;; the exact object-language trace for later decoding.
(define (make-scripted-host responses)
  (define remaining responses)
  (define traces '())
  (define calls 0)
  (values
   (lambda (request)
     (set! calls (add1 calls))
     (set! traces (cons request traces))
     (when (null? remaining)
       (error 'scripted-host "unexpected request"))
     (define response (car remaining))
     (set! remaining (cdr remaining))
     response)
   (lambda () (reverse traces))
   (lambda () calls)
   (lambda () remaining)))

(define (decode-tcp-request request)
  (define parts
    (object-list->host-list request))
  (check-false (codec-failure? parts))
  (define operation
    (object-string->bytes (car parts)))
  (cond
    [(bytes=? operation #"tcp-accept")
     (list operation
           (object-nat->integer (cadr parts)))]
    [(bytes=? operation #"tcp-read")
     (list operation
           (object-nat->integer (cadr parts))
           (object-nat->integer (caddr parts)))]
    [(bytes=? operation #"tcp-write")
     (list operation
           (object-nat->integer (cadr parts))
           (object-string->bytes (caddr parts)))]
    [(bytes=? operation #"tcp-close")
     (list operation
           (object-nat->integer (cadr parts)))]
    [else
     (error 'decode-tcp-request
            "unexpected operation: ~s"
            operation)]))

(define (decoded-traces get-traces)
  (map decode-tcp-request (get-traces)))

(define (configure-serve-one fake-host request-handler)
  (lazy-apply
   (lazy-apply make-http-serve-one fake-host)
   request-handler))

(define (configure-server fake-host request-handler)
  (lazy-apply
   (lazy-apply make-http-server fake-host)
   request-handler))

(define valid-request-one
  #"GET /lambda HTTP/1.1\r\nHo")
(define valid-request-two
  #"st: localhost\r\n\r\n")
(define expected-ok-response
  #"HTTP/1.1 200 OK\r\nContent-Length: 17\r\nConnection: close\r\n\r\nlambda says hello")
(define expected-not-found-response
  #"HTTP/1.1 404 Not Found\r\nContent-Length: 7\r\nConnection: close\r\n\r\nmissing")

;; A fragmented success performs only accept, bounded reads, one complete
;; write, and connection close. Construction is pure and forcing is cached.
(define-values (success-host success-traces success-calls success-remaining)
  (make-scripted-host
   (list (object-ok connection-handle)
         (object-ok (bytes->object-string valid-request-one))
         (object-ok (bytes->object-string valid-request-two))
         (object-ok NIL)
         (object-ok NIL))))
(define success-serve-one
  (configure-serve-one success-host handler))
(check-equal? (procedure-arity
               (lazy-force success-serve-one))
              1)
(define pending-success
  (apply2 success-serve-one
          listener-handle
          maximum))
(check-equal? (success-calls) 0)
(check-ok-nil pending-success)
(check-equal? (success-calls) 5)
(check-ok-nil pending-success)
(check-equal? (success-calls) 5)
(check-equal? (success-remaining) '())
(check-equal?
 (decoded-traces success-traces)
 (list (list #"tcp-accept" 1)
       (list #"tcp-read" 2 65536)
       (list #"tcp-read" 2 65536)
       (list #"tcp-write" 2 expected-ok-response)
       (list #"tcp-close" 2)))

;; Complete parse failures and incomplete EOF both close the acquired
;; connection and perform no write.
(define-values (malformed-host malformed-traces malformed-calls
                               malformed-remaining)
  (make-scripted-host
   (list (object-ok connection-handle)
         (object-ok
          (bytes->object-string
           #"GET / HTTP/1.1\nHost: x\r\n\r\n"))
         (object-ok NIL))))
(define malformed-result
  (apply2 (configure-serve-one malformed-host handler)
          listener-handle
          maximum))
(check-result-err-kind malformed-result 10)
(check-equal?
 (decoded-traces malformed-traces)
 (list (list #"tcp-accept" 1)
       (list #"tcp-read" 2 65536)
       (list #"tcp-close" 2)))
(check-equal? (malformed-calls) 3)
(check-equal? (malformed-remaining) '())

(define-values (eof-host eof-traces eof-calls eof-remaining)
  (make-scripted-host
   (list (object-ok connection-handle)
         (object-ok
          (bytes->object-string
           #"GET /lambda HTTP/1.1\r\nHost: x\r\n"))
         (object-ok EMPTY-STRING)
         (object-ok NIL))))
(define eof-result
  (apply2 (configure-serve-one eof-host handler)
          listener-handle
          maximum))
(check-result-err-kind eof-result 9)
(check-equal?
 (decoded-traces eof-traces)
 (list (list #"tcp-accept" 1)
       (list #"tcp-read" 2 65536)
       (list #"tcp-read" 2 65536)
       (list #"tcp-close" 2)))
(check-equal? (eof-calls) 4)
(check-equal? (eof-remaining) '())

;; Expected read/write failures remain primary Results while cleanup is still
;; forced. A close failure becomes the result only after a successful write.
(define-values (read-failure-host read-failure-traces read-failure-calls
                                  read-failure-remaining)
  (make-scripted-host
   (list (object-ok connection-handle)
         (object-err invalid-nat-error)
         (object-ok NIL))))
(check-result-err-kind
 (apply2 (configure-serve-one read-failure-host handler)
         listener-handle
         maximum)
 2)
(check-equal?
 (decoded-traces read-failure-traces)
 (list (list #"tcp-accept" 1)
       (list #"tcp-read" 2 65536)
       (list #"tcp-close" 2)))
(check-equal? (read-failure-calls) 3)
(check-equal? (read-failure-remaining) '())

(define-values (double-failure-host double-failure-traces
                                    double-failure-calls
                                    double-failure-remaining)
  (make-scripted-host
   (list (object-ok connection-handle)
         (object-err invalid-nat-error)
         (object-err invalid-char-error))))
(check-result-err-kind
 (apply2 (configure-serve-one double-failure-host handler)
         listener-handle
         maximum)
 2)
(check-equal?
 (decoded-traces double-failure-traces)
 (list (list #"tcp-accept" 1)
       (list #"tcp-read" 2 65536)
       (list #"tcp-close" 2)))
(check-equal? (double-failure-calls) 3)
(check-equal? (double-failure-remaining) '())

(define complete-request
  (bytes->object-string
   #"GET /lambda HTTP/1.1\r\nHost: localhost\r\n\r\n"))
(define-values (write-failure-host write-failure-traces write-failure-calls
                                   write-failure-remaining)
  (make-scripted-host
   (list (object-ok connection-handle)
         (object-ok complete-request)
         (object-err invalid-nat-error)
         (object-ok NIL))))
(check-result-err-kind
 (apply2 (configure-serve-one write-failure-host handler)
         listener-handle
         maximum)
 2)
(check-equal?
 (decoded-traces write-failure-traces)
 (list (list #"tcp-accept" 1)
       (list #"tcp-read" 2 65536)
       (list #"tcp-write" 2 expected-ok-response)
       (list #"tcp-close" 2)))
(check-equal? (write-failure-calls) 4)
(check-equal? (write-failure-remaining) '())

(define-values (close-failure-host close-failure-traces close-failure-calls
                                   close-failure-remaining)
  (make-scripted-host
   (list (object-ok connection-handle)
         (object-ok complete-request)
         (object-ok NIL)
         (object-err invalid-nat-error))))
(check-result-err-kind
 (apply2 (configure-serve-one close-failure-host handler)
         listener-handle
         maximum)
 2)
(check-equal?
 (decoded-traces close-failure-traces)
 (list (list #"tcp-accept" 1)
       (list #"tcp-read" 2 65536)
       (list #"tcp-write" 2 expected-ok-response)
       (list #"tcp-close" 2)))
(check-equal? (close-failure-calls) 4)
(check-equal? (close-failure-remaining) '())

;; Handler Results and contract Errors never reach tcp-write. A wrong tagged
;; handler return becomes the dedicated invariant Error after close.
(define unsupported-handler
  (make-path-handler (integer->object-nat 201)
                     HTTP-STATUS-NOT-FOUND))
(define-values (handler-err-host handler-err-traces handler-err-calls
                                 handler-err-remaining)
  (make-scripted-host
   (list (object-ok connection-handle)
         (object-ok complete-request)
         (object-ok NIL))))
(check-result-err-kind
 (apply2 (configure-serve-one handler-err-host unsupported-handler)
         listener-handle
         maximum)
 12)
(check-equal?
 (decoded-traces handler-err-traces)
 (list (list #"tcp-accept" 1)
       (list #"tcp-read" 2 65536)
       (list #"tcp-close" 2)))
(check-equal? (handler-err-calls) 3)
(check-equal? (handler-err-remaining) '())

(define-values (handler-error-host handler-error-traces handler-error-calls
                                   handler-error-remaining)
  (make-scripted-host
   (list (object-ok connection-handle)
         (object-ok complete-request)
         (object-ok NIL))))
(define handler-error-result
  (apply2
   (configure-serve-one
    handler-error-host
    (lambda (target) invalid-char-error))
   listener-handle
   maximum))
(check-true (typed-value? error-type handler-error-result))
(check-equal? (error-kind-integer handler-error-result) 4)
(check-equal?
 (decoded-traces handler-error-traces)
 (list (list #"tcp-accept" 1)
       (list #"tcp-read" 2 65536)
       (list #"tcp-close" 2)))
(check-equal? (handler-error-calls) 3)
(check-equal? (handler-error-remaining) '())

(define-values (invalid-handler-host invalid-handler-traces
                                     invalid-handler-calls
                                     invalid-handler-remaining)
  (make-scripted-host
   (list (object-ok connection-handle)
         (object-ok complete-request)
         (object-ok NIL))))
(define invalid-handler-result
  (apply2
   (configure-serve-one
    invalid-handler-host
    (lambda (target) HTTP-STATUS-OK))
   listener-handle
   maximum))
(check-true (typed-value? error-type invalid-handler-result))
(check-equal? (error-kind-integer invalid-handler-result) 13)
(check-equal?
 (decoded-traces invalid-handler-traces)
 (list (list #"tcp-accept" 1)
       (list #"tcp-read" 2 65536)
       (list #"tcp-close" 2)))
(check-equal? (invalid-handler-calls) 3)
(check-equal? (invalid-handler-remaining) '())

;; Accept failure acquires no connection and therefore performs no close.
(define-values (accept-failure-host accept-failure-traces
                                    accept-failure-calls
                                    accept-failure-remaining)
  (make-scripted-host
   (list (object-err invalid-nat-error))))
(check-result-err-kind
 (apply2 (configure-serve-one accept-failure-host handler)
         listener-handle
         maximum)
 2)
(check-equal?
 (decoded-traces accept-failure-traces)
 (list (list #"tcp-accept" 1)))
(check-equal? (accept-failure-calls) 1)
(check-equal? (accept-failure-remaining) '())

;; The public serving boundaries are unary and strict in both Nat arguments.
;; Contract failures happen before any host request and preserve absorber depth.
(define-values (contract-host contract-traces contract-calls
                              contract-remaining)
  (make-scripted-host '()))
(define contract-serve-one
  (configure-serve-one contract-host handler))
(define wrong-listener-partial
  (lazy-apply contract-serve-one TRUE))
(check-equal? (procedure-arity
               (lazy-force wrong-listener-partial))
              1)
(check-contract-error
 (lazy-apply wrong-listener-partial maximum)
 #"http-serve-one"
 1
 3)
(check-contract-error
 (apply2 contract-serve-one listener-handle TRUE)
 #"http-serve-one"
 2
 3)
(define incoming-server-error
  (apply2 contract-serve-one invalid-nat-error maximum))
(check-true (typed-value? error-type incoming-server-error))
(check-equal? (error-kind-integer incoming-server-error) 2)
(check-equal? (contract-calls) 0)
(check-equal? (contract-traces) '())
(check-equal? (contract-remaining) '())

;; The long-running server handles completed connections serially. This fake
;; permits two successes, then ends the otherwise nonterminating loop with an
;; expected accept Err. Each new accept follows the prior connection close.
(define second-connection-handle
  (integer->object-nat 3))
(define second-request
  (bytes->object-string
   #"GET /missing HTTP/1.1\r\nHost: localhost\r\n\r\n"))
(define-values (loop-host loop-traces loop-calls loop-remaining)
  (make-scripted-host
   (list (object-ok connection-handle)
         (object-ok complete-request)
         (object-ok NIL)
         (object-ok NIL)
         (object-ok second-connection-handle)
         (object-ok second-request)
         (object-ok NIL)
         (object-ok NIL)
         (object-err invalid-nat-error))))
(define configured-loop
  (configure-server loop-host handler))
(check-equal? (procedure-arity
               (lazy-force configured-loop))
              1)
(define pending-loop
  (apply2 configured-loop listener-handle maximum))
(check-equal? (loop-calls) 0)
(check-result-err-kind pending-loop 2)
(check-equal? (loop-calls) 9)
(check-equal?
 (decoded-traces loop-traces)
 (list (list #"tcp-accept" 1)
       (list #"tcp-read" 2 65536)
       (list #"tcp-write" 2 expected-ok-response)
       (list #"tcp-close" 2)
       (list #"tcp-accept" 1)
       (list #"tcp-read" 3 65536)
       (list #"tcp-write" 3 expected-not-found-response)
       (list #"tcp-close" 3)
       (list #"tcp-accept" 1)))
(check-equal? (loop-remaining) '())

;; Real acceptance uses Racket's external HTTP client only in the test layer.
;; The production server still sees solely the documented TCP host requests.
(define real-listen
  (lazy-apply make-tcp-listen host))
(define real-close
  (lazy-apply make-tcp-close host))
(define real-serve-one
  (configure-serve-one host handler))
(define listener-result
  (apply3 real-listen
          (bytes->object-string #"127.0.0.1")
          (integer->object-nat 0)
          (integer->object-nat 4)))
(check-true (bool->boolean
             (lazy-apply is-ok listener-result)))
(define listener-parts
  (object-list->host-list
   (lazy-apply unwrap-ok listener-result)))
(define real-listener
  (car listener-parts))
(define bound-port
  (object-nat->integer (cadr listener-parts)))
(check-true (and (exact-positive-integer? bound-port)
                 (<= bound-port 65535)))

(define test-custodian
  (make-custodian))
(define listener-closed? #f)

(define (start-worker thunk)
  (define result (box #f))
  (define worker
    (parameterize ([current-custodian test-custodian])
      (thread
       (lambda ()
         (with-handlers ([exn:fail?
                          (lambda (failure)
                            (set-box! result failure))])
           (set-box! result (thunk)))))))
  (values worker result))

(define (finish-worker worker result)
  (unless (sync/timeout 5 worker)
    (error 'http-server-test "worker timed out"))
  (define value (unbox result))
  (when (exn:fail? value)
    (raise value))
  value)

(dynamic-wind
  void
  (lambda ()
    (define-values (server-worker server-result)
      (start-worker
       (lambda ()
         (define result
           (apply2 real-serve-one
                   real-listener
                   maximum))
         ;; Demand the Result tag inside the worker so serving cannot remain a
         ;; suspended lazy computation after the thread exits.
         (unless (typed-value? result-type result)
           (error 'http-server-test "server returned a non-Result"))
         result)))
    (define-values (client-worker client-result)
      (start-worker
       (lambda ()
         (define-values (status headers body)
           (http-sendrecv #"127.0.0.1"
                          #"/lambda"
                          #:port bound-port
                          #:headers
                          (list #"User-Agent: AttaLambda-phase-18")
                          #:content-decode '()))
         (list status headers (port->bytes body)))))
    (define response
      (finish-worker client-worker client-result))
    (check-equal? (car response)
                  #"HTTP/1.1 200 OK")
    (check-not-false
     (member #"Content-Length: 17" (cadr response)))
    (check-not-false
     (member #"Connection: close" (cadr response)))
    (check-equal? (caddr response)
                  #"lambda says hello")
    (check-ok-nil
     (finish-worker server-worker server-result))
    (check-ok-nil
     (lazy-apply real-close real-listener))
    (set! listener-closed? #t))
  (lambda ()
    (custodian-shutdown-all test-custodian)
    (unless listener-closed?
      ;; Best-effort cleanup remains test infrastructure; the Result is forced
      ;; so the real host removes the listener even after an earlier assertion.
      (with-handlers ([exn:fail? (lambda (failure) (void))])
        (typed-value?
         result-type
         (lazy-apply real-close real-listener))))))
