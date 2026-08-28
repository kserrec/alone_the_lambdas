#lang racket/base

(require rackunit
         net/http-client
         racket/file
         racket/list
         racket/port
         racket/runtime-path
         "../tooling/check-boundaries.rkt"
         "helpers/fresh-language.rkt")

(define-runtime-path project-root-path "..")
(define-runtime-path stdout-example "../examples/stdout.atl")
(define-runtime-path file-example "../examples/file-round-trip.atl")
(define-runtime-path http-example "../examples/http-server.atl")

(define project-root
  (simplify-path project-root-path #f))

;; The runnable proof is paired with the structural proof: there is one
;; privileged host-class source, and the complete class/dependency/capability
;; gate accepts the repository before any real-host application is launched.
(check-equal? (project-boundary-violations project-root) '())
(check-equal?
 (count (lambda (classification)
          (eq? (source-classification-class classification) 'host))
        (project-source-classifications project-root))
 1)

(define (call-with-timeout timeout-seconds name procedure)
  (define result
    (box #f))
  (define worker
    (thread
     (lambda ()
       (with-handlers ([exn:fail?
                        (lambda (failure)
                          (set-box! result failure))])
         (set-box! result (procedure))))))
  (unless (sync/timeout timeout-seconds worker)
    (kill-thread worker)
    (error name "timed out after ~a seconds" timeout-seconds))
  (define value
    (unbox result))
  (when (exn:fail? value)
    (raise value))
  value)

(define (check-http-example environment runner working-directory)
  (define process #f)
  (define child-output #f)
  (define child-error #f)
  (define stderr-reader #f)
  (define captured-error
    (box #f))
  (dynamic-wind
    void
    (lambda ()
      (define-values
        (started-process started-output child-input started-error)
        (parameterize
            ([current-environment-variables environment]
             [current-directory working-directory])
          (subprocess #f
                      #f
                      #f
                      racket-executable
                      (path->string runner)
                      "run"
                      (path->string http-example))))
      (set! process started-process)
      (set! child-output started-output)
      (set! child-error started-error)
      (close-output-port child-input)
      (set!
       stderr-reader
       (thread
        (lambda ()
          (set-box! captured-error
                    (port->bytes child-error)))))

      (define announcement
        (call-with-timeout
         20
         'http-example-announcement
         (lambda ()
           (read-bytes-line child-output 'any))))
      (define matched-announcement
        (and (bytes? announcement)
             (regexp-match
              #rx#"^Listening on http://127[.]0[.]0[.]1:([0-9]+)/lambda$"
              announcement)))
      (check-not-false matched-announcement
                       (format "unexpected announcement: ~s" announcement))
      (unless matched-announcement
        (error 'http-example "could not recover the bound port"))
      (define bound-port
        (string->number
         (bytes->string/utf-8 (cadr matched-announcement))))
      (check-true (and (exact-positive-integer? bound-port)
                       (<= bound-port 65535)))

      (define response
        (call-with-timeout
         20
         'http-example-client
         (lambda ()
           (define-values (status headers body)
             (http-sendrecv #"127.0.0.1"
                            #"/lambda"
                            #:port bound-port
                            #:headers
                            (list #"User-Agent: ATL-phase-20")
                            #:content-decode '()))
           (list status headers (port->bytes body)))))
      (check-equal? (car response)
                    #"HTTP/1.1 200 OK")
      (check-not-false
       (member #"Content-Length: 30" (cadr response)))
      (check-not-false
       (member #"Connection: close" (cadr response)))
      (check-equal? (caddr response)
                    #"Hello from Alone the Lambdas.\n")

      (unless (sync/timeout 20 process)
        (error 'http-example "server process did not exit"))
      (sync stderr-reader)
      (check-equal? (subprocess-status process) 0)
      (check-equal? (port->bytes child-output) #"")
      (check-equal? (unbox captured-error) #""))
    (lambda ()
      (when (and process
                 (eq? (subprocess-status process) 'running))
        (subprocess-kill process #t)
        (sync process))
      (when (and stderr-reader
                 (not (thread-dead? stderr-reader)))
        (kill-thread stderr-reader))
      (when (input-port? child-output)
        (close-input-port child-output))
      (when (input-port? child-error)
        (close-input-port child-error)))))

(call-with-fresh-language-install
 project-root
 (lambda (installation)
   (define temporary-root
     (fresh-language-install-temporary-root installation))
   (define environment
     (fresh-language-install-environment installation))
   (define runner
     (build-path temporary-root "package-source" "runner" "atl.rkt"))

   (define stdout-directory
     (build-path temporary-root "stdout-example"))
   (make-directory stdout-directory)
   (check-command-success
    (run-command environment
                 racket-executable
                 (list (path->string runner)
                       "run"
                       (path->string stdout-example))
                 20
                 #:current-directory stdout-directory)
    #"Hello from Alone the Lambdas.\n")

   (define file-directory
     (build-path temporary-root "file-example"))
   (make-directory file-directory)
   (check-command-success
    (run-command environment
                 racket-executable
                 (list (path->string runner)
                       "run"
                       (path->string file-example))
                 20
                 #:current-directory file-directory)
    #"Alone the Lambdas file round trip.\n")
   (check-equal?
    (file->bytes
     (build-path file-directory
                 "alone-the-lambdas-round-trip.txt"))
    #"Alone the Lambdas file round trip.\n")

   (define http-directory
     (build-path temporary-root "http-example"))
   (make-directory http-directory)
   (check-http-example environment runner http-directory)))
