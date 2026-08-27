#lang racket/base

(require rackunit
         racket/file
         racket/list
         racket/runtime-path
         "../tooling/check-boundaries.rkt")

(define-runtime-path project-root "..")

(define (write-datum path datum)
  (call-with-output-file path
    #:exists 'truncate
    (lambda (output)
      (write datum output))))

(define (kinds findings)
  (map boundary-violation-kind findings))

(define (temporary-project procedure)
  (define root
    (make-temporary-file "alone-the-lambdas-boundary-~a"
                         'directory
                         (current-directory)))
  (dynamic-wind
    (lambda ()
      (for ([directory (in-list '("core" "effects" "macros" "runtime"))])
        (make-directory (build-path root directory)))
      (write-datum
       (build-path root "macros" "macros.rkt")
       '(module macros racket/base
          (#%module-begin
           (provide def lambda-let define-function-name))))
      (write-datum
       (build-path root "core" "dependency.rkt")
       '(module dependency racket/base
          (#%module-begin
           (provide identity))))
      (write-datum
       (build-path root "effects" "protocol.rkt")
       '(module protocol "../macros/lazy-with-macros.rkt"
          (#%module-begin
           (require "../macros/macros.rkt"
                    (only-in "../core/dependency.rkt" identity))
           (provide bridge)
           (def bridge value =
             (identity value)))))
      (write-datum
       (build-path root "runtime" "codec.rkt")
       '(module codec racket/base
          (#%module-begin
           (provide (struct-out codec-failure)
                    object-list->host-list
                    host-list->object-list
                    object-string->bytes
                    bytes->object-string
                    object-ok
                    object-err))))
      (write-datum
       (build-path root "runtime" "host.rkt")
       '(module host racket/base
          (#%module-begin
           (require (only-in "../effects/protocol.rkt" bridge)
                    (only-in "codec.rkt" object-ok))
           (provide host)
           (define (host request) request)))))
    (lambda () (procedure root))
    (lambda () (delete-directory/files root))))

(check-equal? (project-boundary-violations project-root)
              '())

(temporary-project
 (lambda (root)
   (define effect (build-path root "effects" "example.rkt"))
   (define (check-effect datum expected)
     (write-datum effect datum)
     (check-equal? (kinds (file-boundary-violations effect 'effect root))
                   expected))

   (check-effect
    '(module example "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (require "../macros/macros.rkt"
                 (only-in "../core/dependency.rkt" identity))
        (provide use)
        (def use value =
          (identity value))))
    '())

   ;; An unknown Lazy Racket binding cannot bypass the gate merely because it
   ;; was omitted from a blacklist.
   (check-effect
    '(module example "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (require "../macros/macros.rkt")
        (provide use)
        (def use value =
          (current-seconds value))))
    '(unapproved-effect-identifier))

   (check-effect
    '(module example "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (provide current-seconds)))
    '(unapproved-effect-export))

   (check-effect
    '(module example "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (require "../macros/macros.rkt"
                 (only-in "../core/dependency.rkt" identity))
        (provide use)
        (def use value =
          (identity value value))))
    '(non-unary-effect-application))

   (check-effect
    '(module example "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (require "../macros/macros.rkt")
        (provide use)
        (def use value =
          (lambda (left right) left))))
    '(non-unary-effect-lambda))

   (check-effect
    '(module example "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (require "../macros/macros.rkt")
        (provide host)
        (def host request = request)))
    '(forbidden-host-export forbidden-host-definition))

   (check-effect
    '(module example "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (require (only-in "../runtime/codec.rkt" object-ok))
        (provide use)
        (def use value =
          (object-ok value))))
    '(disallowed-effect-import))

   (define codec (build-path root "runtime" "candidate-codec.rkt"))
   (define (codec-datum extra)
     `(module codec racket/base
        (#%module-begin
         (provide (struct-out codec-failure)
                  object-list->host-list
                  host-list->object-list
                  object-string->bytes
                  bytes->object-string
                  object-ok
                  object-err)
         ,extra)))

   (write-datum codec
                (codec-datum '(define leak (display "effect"))))
   (check-equal?
    (kinds (file-boundary-violations codec 'codec root))
    '(forbidden-codec-capability))

   (write-datum codec
                (codec-datum
                 '(define (mutate value)
                    (set-car! value value))))
   (check-equal?
    (kinds (file-boundary-violations codec 'codec root))
    '(forbidden-codec-capability))

   (write-datum codec
                (codec-datum '(define handle-registry '())))
   (check-equal?
    (kinds (file-boundary-violations codec 'codec root))
    '(forbidden-codec-capability))

   (define host-file (build-path root "runtime" "candidate-host.rkt"))
   (define (host-datum provide-form body)
     `(module host racket/base
        (#%module-begin
         (require (only-in "../effects/protocol.rkt" bridge)
                  (only-in "codec.rkt" object-ok))
         ,provide-form
         (define (host request) ,body))))

   (write-datum host-file
                (host-datum '(provide host) 'request))
   (check-equal? (file-boundary-violations host-file 'host root)
                 '())

   (write-datum host-file
                (host-datum '(provide host leak) 'request))
   (check-equal?
    (kinds (file-boundary-violations host-file 'host root))
    '(invalid-host-export))

   (write-datum host-file
                (host-datum '(provide host) '(eval request)))
   (check-equal?
    (kinds (file-boundary-violations host-file 'host root))
    '(forbidden-host-capability))

   ;; The exact runtime vocabularies reject capabilities not covered by a
   ;; finite blacklist, including a clock from racket/base.
   (define production-host (build-path root "runtime" "host.rkt"))
   (write-datum production-host
                (host-datum '(provide host) '(current-seconds)))
   (check-not-false
    (member 'unapproved-host-identifier
            (kinds (project-boundary-violations root))))
   (write-datum
    production-host
    '(module host racket/base
       (#%module-begin
        (require (only-in "../effects/protocol.rkt" bridge)
                 (only-in "codec.rkt" object-ok))
        (provide host)
        (define (host request) request))))

   ;; Project-wide scanning catches a second production importer of the
   ;; internal codec even when its own module class also rejects that import.
   (write-datum
    effect
    '(module example "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (require (only-in "../runtime/codec.rkt" object-ok))
        (provide use)
        (def use value =
          (object-ok value)))))
   (check-not-false
    (member 'unauthorized-codec-import
            (kinds (project-boundary-violations root))))))
