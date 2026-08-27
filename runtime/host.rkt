#lang racket/base

;; The one production bridge to the outside world. The closed dispatcher
;; contains exactly the stdout and file operations approved through Phase 15.

(require (only-in racket/file file->bytes)
         racket/promise
         (only-in "../core/errors.rkt" NIL)
         (only-in "../core/strings.rkt" EMPTY-STRING)
         (only-in "../effects/protocol.rkt"
                  invalid-path-code
                  invalid-text-code
                  io-failure-code
                  make-host-bridge
                  make-host-failure
                  make-invalid-host-request
                  not-found-code
                  out-of-range-reason
                  permission-denied-code
                  read-file-operation
                  resource-exhausted-code
                  stdout-operation
                  timed-out-code
                  unknown-operation-reason
                  write-file-operation
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

(define (host-failure operation code)
  (object-err
   (lazy-apply2 make-host-failure
                operation
                code)))

(define (errno-in? errno domain numbers)
  (and (pair? errno)
       (eq? (cdr errno) domain)
       (memv (car errno) numbers)))

;; Racket exposes stable OS error data as (number . domain). Keep the mapping
;; closed and return only approved lambda String codes; exception text, errno,
;; and paths never enter an object-language Error.
(define (filesystem-failure-code failure)
  (cond
    [(exn:fail:out-of-memory? failure)
     resource-exhausted-code]
    [(exn:fail:contract? failure)
     invalid-path-code]
    [(not (exn:fail:filesystem:errno? failure))
     io-failure-code]
    [else
     (define errno
       (exn:fail:filesystem:errno-errno failure))
     (cond
       [(or (errno-in? errno 'posix '(2))
            (errno-in? errno 'windows '(2 3)))
        not-found-code]
       [(or (errno-in? errno 'posix '(1 13 30))
            (errno-in? errno 'windows '(5)))
        permission-denied-code]
       [(or (errno-in? errno 'posix '(20 21 22 36 40))
            (errno-in? errno 'windows '(123 206 267)))
        invalid-path-code]
       [(or (errno-in? errno 'posix '(12 23 24 28 122))
            (errno-in? errno 'windows '(4 8 14 112)))
        resource-exhausted-code]
       [(or (errno-in? errno 'posix '(110))
            (errno-in? errno 'windows '(121)))
        timed-out-code]
       [else io-failure-code])]))

(define (file-failure operation failure)
  (host-failure operation
                (filesystem-failure-code failure)))

(define (perform-stdout payload)
  (with-handlers ([exn:fail?
                   (lambda (failure)
                     (host-failure stdout-operation
                                   io-failure-code))])
    (define output (current-output-port))
    (write-bytes payload output)
    (flush-output output)
    (object-ok NIL)))

(define (decode-path operation payload)
  (with-handlers ([exn:fail:out-of-memory?
                   (lambda (failure)
                     (host-failure operation
                                   resource-exhausted-code))]
                  [exn:fail:contract?
                   (lambda (failure)
                     (host-failure operation
                                   invalid-text-code))]
                  [exn:fail?
                   (lambda (failure)
                     (host-failure operation
                                   io-failure-code))])
    (bytes->string/utf-8 payload #f)))

(define (perform-read-file path-payload)
  (define path
    (decode-path read-file-operation path-payload))
  (if (string? path)
      (with-handlers ([exn:fail?
                       (lambda (failure)
                         (file-failure read-file-operation failure))])
        (object-ok
         (bytes->object-string
          (file->bytes path))))
      path))

(define (perform-write-file path-payload payload)
  (define path
    (decode-path write-file-operation path-payload))
  (if (string? path)
      (with-handlers ([exn:fail?
                       (lambda (failure)
                         (file-failure write-file-operation failure))])
        (call-with-output-file path
          #:exists 'truncate/replace
          (lambda (output)
            (write-bytes payload output)))
        (object-ok NIL))
      path))

(define (dispatch-one-string operation decoded-request performer)
  (if (not (= (length decoded-request) 2))
      (invalid-request operation wrong-arity-reason)
      (let ([payload
             (object-string->bytes
              (cadr decoded-request))])
        (if (codec-failure? payload)
            (invalid-codec-request operation payload)
            (performer payload)))))

(define (dispatch-two-strings operation decoded-request performer)
  (if (not (= (length decoded-request) 3))
      (invalid-request operation wrong-arity-reason)
      (let ([first
             (object-string->bytes
              (cadr decoded-request))])
        (if (codec-failure? first)
            (invalid-codec-request operation first)
            (let ([second
                   (object-string->bytes
                    (caddr decoded-request))])
              (if (codec-failure? second)
                  (invalid-codec-request operation second)
                  (performer first second)))))))

(define (dispatch-request request)
  (define decoded-request
    (object-list->host-list request))
  (cond
    [(codec-failure? decoded-request)
     (invalid-codec-request EMPTY-STRING decoded-request)]
    [(null? decoded-request)
     (invalid-request EMPTY-STRING wrong-arity-reason)]
    [else
     (define operation-value (car decoded-request))
     (define operation-bytes
       (object-string->bytes operation-value))
     (cond
       [(codec-failure? operation-bytes)
        (invalid-codec-request EMPTY-STRING operation-bytes)]
       [(bytes=? operation-bytes #"stdout")
        (dispatch-one-string stdout-operation
                             decoded-request
                             perform-stdout)]
       [(bytes=? operation-bytes #"read-file")
        (dispatch-one-string read-file-operation
                             decoded-request
                             perform-read-file)]
       [(bytes=? operation-bytes #"write-file")
        (dispatch-two-strings write-file-operation
                              decoded-request
                              perform-write-file)]
       [else
        (invalid-request
         (bytes->object-string operation-bytes)
         unknown-operation-reason)])]))

(define host
  (lazy-apply make-host-bridge dispatch-request))
