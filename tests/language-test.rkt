#lang racket/base

(require rackunit
         racket/file
         racket/path
         racket/port
         racket/runtime-path)

(define-runtime-path project-root-path "..")
(define-runtime-path canonical-program
  "fixtures/language-canonical.rkt")

(define project-root
  (simplify-path project-root-path #f))

(struct command-result (status stdout stderr timed-out?)
  #:transparent)

(define racket-executable
  (find-executable-path "racket"))

(define raco-executable
  (find-executable-path "raco"))

(define (run-command environment executable arguments timeout-seconds)
  (define-values (process child-output child-input child-error)
    (parameterize ([current-environment-variables environment])
      (apply subprocess
             #f
             #f
             #f
             executable
             arguments)))
  (close-output-port child-input)
  (define captured-output
    (box #f))
  (define captured-error
    (box #f))
  (define output-reader
    (thread
     (lambda ()
       (set-box! captured-output
                 (port->bytes child-output)))))
  (define error-reader
    (thread
     (lambda ()
       (set-box! captured-error
                 (port->bytes child-error)))))
  (define completed
    (sync/timeout timeout-seconds process))
  (unless completed
    (subprocess-kill process #t)
    (sync process))
  (sync output-reader)
  (sync error-reader)
  (command-result
   (and completed (subprocess-status process))
   (unbox captured-output)
   (unbox captured-error)
   (not completed)))

(define (result-diagnostic result)
  (format "status: ~s\nstdout: ~s\nstderr: ~a"
          (command-result-status result)
          (command-result-stdout result)
          (bytes->string/utf-8
           (command-result-stderr result)
           #\?)))

(define (check-command-success result expected-output)
  (check-false (command-result-timed-out? result)
               (result-diagnostic result))
  (check-equal? (command-result-status result)
                0
                (result-diagnostic result))
  (check-equal? (command-result-stdout result)
                expected-output
                (result-diagnostic result))
  (check-equal? (command-result-stderr result)
                #""
                (result-diagnostic result)))

(define (check-command-failure result expected-message)
  (check-false (command-result-timed-out? result)
               (result-diagnostic result))
  (check-not-equal? (command-result-status result)
                    0
                    (result-diagnostic result))
  (check-true
   (regexp-match? expected-message
                  (bytes->string/utf-8
                   (command-result-stderr result)
                   #\?))
   (result-diagnostic result)))

(define (write-source path source)
  (call-with-output-file path
    #:exists 'truncate
    (lambda (output)
      (display source output))))

(define (dotenv-name? path)
  (define name
    (file-name-from-path path))
  (and name
       (regexp-match?
        #px"(^|\\.)env($|\\.)"
        (string-downcase (path->string name)))))

(define (excluded-package-entry? path)
  (define name
    (file-name-from-path path))
  (or (dotenv-name? path)
      (and name
           (member (path->string name)
                   '(".git" "compiled")))))

(define (copy-package-source source target)
  (cond
    [(link-exists? source)
     (error 'language-test
            "package source contains a symlink: ~a"
            source)]
    [(directory-exists? source)
     (make-directory target)
     (for ([entry (in-list (directory-list source))]
           #:unless (excluded-package-entry? entry))
       (copy-package-source (build-path source entry)
                            (build-path target entry)))]
    [(file-exists? source)
     (copy-file source target)]
    [else
     (error 'language-test
            "package source entry disappeared: ~a"
            source)]))

(define temporary-root
  (make-temporary-file
   "alone-the-lambdas-language-~a"
   'directory
   (if (directory-exists? "/tmp")
       (string->path "/tmp")
       (find-system-path 'temp-dir))))

(dynamic-wind
  void
  (lambda ()
    (define isolated-home
      (build-path temporary-root "racket-home"))
    (make-directory isolated-home)

    (define isolated-environment
      (environment-variables-copy
       (current-environment-variables)))
    (environment-variables-set!
     isolated-environment
     #"PLTUSERHOME"
     (path->bytes isolated-home))
    (environment-variables-set!
     isolated-environment
     #"TMPDIR"
     (path->bytes temporary-root))

    (define package-source
      (build-path temporary-root "package-source"))
    (make-directory package-source)
    (copy-file (build-path project-root "info.rkt")
               (build-path package-source "info.rkt"))
    (for ([directory
           (in-list '("core" "effects" "lang" "macros" "runtime"))])
      (copy-package-source
       (build-path project-root directory)
       (build-path package-source directory)))

    ;; The copy install proves that language resolution comes from package
    ;; metadata, not from the working directory or a source-tree link. The
    ;; explicit staging walk excludes every dotenv spelling before content is
    ;; accessed and omits VCS/compiled state.
    (define install-result
      (run-command
       isolated-environment
       raco-executable
       (list "pkg" "install"
             "--batch"
             "--scope" "user"
             "--copy"
             "--name" "alone_the_lambdas"
             "--deps" "fail"
             "--no-docs"
             "--fail-fast"
             (path->string package-source))
       180))
    (check-false (command-result-timed-out? install-result)
                 (result-diagnostic install-result))
    (check-equal? (command-result-status install-result)
                  0
                  (result-diagnostic install-result))
    (unless (and (not (command-result-timed-out? install-result))
                 (equal? (command-result-status install-result) 0))
      (error 'language-test
             "fresh package installation failed\n~a"
             (result-diagnostic install-result)))

    (check-command-success
     (run-command isolated-environment
                  racket-executable
                  (list (path->string canonical-program))
                  20)
     (string->bytes/utf-8 "λ🙂"))

    (define currying-program
      (build-path temporary-root "currying.rkt"))
    (write-source
     currying-program
     #<<PROGRAM
#lang alone_the_lambdas

(def add-two left right =
  (ADD left right))

(def add-two-to-two =
  (add-two 2))

(stdout
 (let identity = (lambda (value) value)
   (if (EQ (add-two-to-two 2) 4)
       (identity "curried")
       "wrong")))
PROGRAM
     )
    (check-command-success
     (run-command isolated-environment
                  racket-executable
                  (list (path->string currying-program))
                  20)
     #"curried")

    (define lazy-branch-program
      (build-path temporary-root "lazy-branch.rkt"))
    (write-source
     lazy-branch-program
     #<<PROGRAM
#lang alone_the_lambdas

(def loop value =
  (loop value))

(stdout
 (if FALSE
     (loop NIL)
     "lazy"))
PROGRAM
     )
    (check-command-success
     (run-command isolated-environment
                  racket-executable
                  (list (path->string lazy-branch-program))
                  20)
     #"lazy")

    ;; Test tooling crosses the module boundary only to prove that expansion
    ;; produced canonical lambda values. None of this observation API is
    ;; exported by the object language.
    (define representation-program
      (build-path temporary-root "representations.rkt"))
    (write-source
     representation-program
     #<<PROGRAM
#lang alone_the_lambdas

(def nat-zero = 0)
(def nat-one = 1)
(def nat-byte = 255)
(def nat-next-byte = 256)
(def nat-large = 65536)
(def string-value = "λ🙂")
(def saved-host = host)
PROGRAM
     )

    (define representation-probe
      (build-path temporary-root "representation-probe.rkt"))
    (write-source
     representation-probe
     #<<PROBE
#lang racket/base

(require alone_the_lambdas/runtime/codec)

(define target
  (string->path
   (vector-ref (current-command-line-arguments) 0)))
(dynamic-require target #f)
(define target-namespace
  (module->namespace target))

(define (target-value name)
  (parameterize ([current-namespace target-namespace])
    (eval name)))

(write
 (map object-nat->integer
      (map target-value
           '(nat-zero nat-one nat-byte nat-next-byte nat-large))))
(newline)
(void
 (write-bytes
  (object-string->bytes
   (target-value 'string-value))))
PROBE
     )
    (check-command-success
     (run-command isolated-environment
                  racket-executable
                  (list (path->string representation-probe)
                        (path->string representation-program))
                  20)
     (bytes-append
      #"(0 1 255 256 65536)\n"
      (string->bytes/utf-8 "λ🙂")))

    (for ([case
           (in-list
            '(("#t" #rx"only nonnegative Nat and String literals are supported")
              ("#f" #rx"only nonnegative Nat and String literals are supported")
              ("-1" #rx"only nonnegative Nat and String literals are supported")
              ("1/2" #rx"only nonnegative Nat and String literals are supported")
              ("1.0" #rx"only nonnegative Nat and String literals are supported")
              ("1+2i" #rx"only nonnegative Nat and String literals are supported")
              ("#\\a" #rx"only nonnegative Nat and String literals are supported")
              ("#\"bytes\"" #rx"only nonnegative Nat and String literals are supported")
              ("#:keyword" #rx"missing argument expression after keyword")
              ("#(1)" #rx"only nonnegative Nat and String literals are supported")))]
          [index (in-naturals)])
      (define literal (car case))
      (define expected-message (cadr case))
      (define unsupported-program
        (build-path temporary-root
                    (format "unsupported-~a.rkt" index)))
      (write-source
       unsupported-program
       (string-append "#lang alone_the_lambdas\n" literal "\n"))
      (check-command-failure
       (run-command isolated-environment
                    racket-executable
                    (list (path->string unsupported-program))
                    20)
       expected-message))

    (define multi-lambda-program
      (build-path temporary-root "multi-lambda.rkt"))
    (write-source
     multi-lambda-program
     "#lang alone_the_lambdas\n(lambda (left right) left)\n")
    (check-command-failure
     (run-command isolated-environment
                  racket-executable
                  (list (path->string multi-lambda-program))
                  20)
     #rx"expected \\(lambda \\(argument\\) body\\)")

    (for ([source
           (in-list
            '("(define leaked 1)"
              "(require racket/base)"
              "(+ 1 2)"
              "(display \"leak\")"
              "(raw-cons 1 NIL)"
              "(typed-if TRUE \"yes\" \"no\")"
              "(_if TRUE \"yes\" \"no\")"
              "'quoted"))]
          [index (in-naturals)])
      (define isolated-program
        (build-path temporary-root
                    (format "isolated-~a.rkt" index)))
      (write-source
       isolated-program
       (string-append "#lang alone_the_lambdas\n" source "\n"))
      (check-command-failure
       (run-command isolated-environment
                    racket-executable
                    (list (path->string isolated-program))
                    20)
       #rx"unbound identifier|not allowed in an expression")))
  (lambda ()
    (delete-directory/files temporary-root)))
