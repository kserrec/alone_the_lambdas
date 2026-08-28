#lang racket/base

(require rackunit
         racket/file
         racket/path
         racket/runtime-path
         "helpers/fresh-language.rkt")

(define-runtime-path project-root-path "..")

(define project-root
  (simplify-path project-root-path #f))

(define expected-help
  #"Usage:\n  atl run FILE.atl\n  atl --help\n  atl --version\n")

(define (check-runner-failure result expected-status expected-message)
  (check-false (command-result-timed-out? result)
               (result-diagnostic result))
  (check-equal? (command-result-status result)
                expected-status
                (result-diagnostic result))
  (check-equal? (command-result-stdout result)
                #""
                (result-diagnostic result))
  (check-true
   (regexp-match? expected-message
                  (bytes->string/utf-8
                   (command-result-stderr result)
                   #\?))
   (result-diagnostic result)))

(define (write-exact-bytes path content)
  (call-with-output-file path
    #:exists 'truncate
    #:mode 'binary
    (lambda (output)
      (write-bytes content output))))

(call-with-fresh-language-install
 project-root
 (lambda (installation)
   (define temporary-root
     (fresh-language-install-temporary-root installation))
   (define environment
     (fresh-language-install-environment installation))
   (define package-source
     (build-path temporary-root "package-source"))
   (define runner
     (build-path package-source "runner" "atl.rkt"))
   (define working-directory
     (build-path temporary-root "runner-work"))
   (make-directory working-directory)

   (define (run arguments
                #:current-directory [directory working-directory])
     (run-command environment
                  racket-executable
                  (cons (path->string runner) arguments)
                  20
                  #:current-directory directory))

   ;; The complete initial command surface is exact.
   (check-command-success (run '("--help")) expected-help)
   (check-command-success
    (run '("--version"))
    #"Alone the Lambdas 0.2.0-dev\n")

   (for ([arguments
          (in-list '(()
                     ("run")
                     ("unknown")
                     ("--help" "extra")
                     ("--version" "extra")
                     ("run" "program.atl" "extra")))])
     (check-runner-failure
      (run arguments)
      64
      #rx"Alone the Lambdas: usage:"))

   ;; VERSION remains the sole CLI version source. Expansion embeds only an
   ;; approved state so the future native executable needs no runtime copy.
   (define product-version-file
     (build-path package-source "VERSION"))
   (write-exact-bytes product-version-file #"0.2.0-rc.1\n")
   (check-command-success
    (run '("--version"))
    #"Alone the Lambdas 0.2.0-rc.1\n")
   (write-exact-bytes product-version-file #"0.2.0\n")
   (check-command-success
    (run '("--version"))
    #"Alone the Lambdas 0.2.0\n")
   (write-exact-bytes product-version-file #"unsupported\n")
   (define invalid-version-build
     (run '("--version")))
   (check-false (command-result-timed-out? invalid-version-build)
                (result-diagnostic invalid-version-build))
   (check-not-equal? (command-result-status invalid-version-build)
                     0
                     (result-diagnostic invalid-version-build))
   (check-equal? (command-result-stdout invalid-version-build)
                 #""
                 (result-diagnostic invalid-version-build))
   (check-true
    (regexp-match? #rx"invalid product version metadata"
                   (bytes->string/utf-8
                    (command-result-stderr invalid-version-build)
                    #\?))
    (result-diagnostic invalid-version-build))
   (write-exact-bytes product-version-file #"0.2.0-dev\n")

   ;; Validation precedence rejects names and metadata before source content.
   ;; None of the dotenv-spelled paths below is created or opened.
   (check-runner-failure
    (run '("run" "program.env.rkt"))
    66
    #rx"dotenv paths are refused")
   (check-runner-failure
    (run '("run" ".ENV.local/program.atl"))
    66
    #rx"dotenv paths are refused")
   (check-runner-failure
    (run '("run" "missing.rkt"))
    65
    #rx"source must end in [. ]?atl")
   (check-runner-failure
    (run '("run" "missing.ATL"))
    65
    #rx"source must end in [. ]?atl")
   (check-runner-failure
    (run '("run" "missing.atl"))
    66
    #rx"source is unavailable")

   (define directory-source
     (build-path working-directory "directory.atl"))
   (make-directory directory-source)
   (check-runner-failure
    (run (list "run" (path->string directory-source)))
    66
    #rx"source is unavailable")

   (define malformed-header
     (build-path working-directory "malformed.atl"))
   (write-source malformed-header
                 " #lang alone_the_lambdas\n(stdout \"no\")\n")
   (check-runner-failure
    (run (list "run" (path->string malformed-header)))
    65
    #rx"first line must be #lang alone_the_lambdas")

   (define bare-carriage-return-header
     (build-path working-directory "bare-carriage-return.atl"))
   (write-exact-bytes
    bare-carriage-return-header
    #"#lang alone_the_lambdas\r(stdout \"no\")\n")
   (check-runner-failure
    (run (list "run" (path->string bare-carriage-return-header)))
    65
    #rx"first line must be #lang alone_the_lambdas")

   (for ([malformed-case
          (in-list
           (list
            (cons "byte-order-mark.atl"
                  #"\357\273\277#lang alone_the_lambdas\n")
            (cons "trailing-space.atl"
                  #"#lang alone_the_lambdas \n")))])
     (define malformed-path
       (build-path working-directory (car malformed-case)))
     (write-exact-bytes malformed-path (cdr malformed-case))
     (check-runner-failure
      (run (list "run" (path->string malformed-path)))
      65
      #rx"first line must be #lang alone_the_lambdas"))

   (define linked-target
     (build-path working-directory "linked-target.atl"))
   (define linked-source
     (build-path working-directory "linked.atl"))
   (write-source linked-target
                 "#lang alone_the_lambdas\n(stdout \"target ran\")\n")
   (make-file-or-directory-link linked-target linked-source)
   (check-runner-failure
    (run (list "run" (path->string linked-source)))
    66
    #rx"symbolic links are refused")

   (define dotenv-parent
     (build-path working-directory "private.env.local"))
   (define ordinary-parent-link
     (build-path working-directory "ordinary-parent"))
   (make-directory dotenv-parent)
   (write-source
    (build-path dotenv-parent "program.atl")
    "#lang alone_the_lambdas\n(stdout \"resolved target ran\")\n")
   (make-file-or-directory-link dotenv-parent ordinary-parent-link)
   (check-runner-failure
    (run (list "run"
               (path->string
                (build-path ordinary-parent-link "program.atl"))))
    66
    #rx"dotenv paths are refused")

   (define allowed-parent-target
     (build-path working-directory "allowed-parent-target"))
   (define allowed-parent-link
     (build-path working-directory "allowed-parent"))
   (make-directory allowed-parent-target)
   (write-source
    (build-path allowed-parent-target "program.atl")
    "#lang alone_the_lambdas\n(stdout \"parent link allowed\")\n")
   (make-file-or-directory-link allowed-parent-target allowed-parent-link)
   (check-command-success
    (run (list "run"
               (path->string
                (build-path allowed-parent-link "program.atl"))))
    #"parent link allowed")

   ;; Paths containing spaces and non-ASCII characters retain the existing
   ;; reader/expander semantics, including CRLF declarations and UTF-8 String
   ;; lowering.
   (define unicode-directory
     (build-path working-directory "source space lambda-λ"))
   (make-directory unicode-directory)
   (define unicode-source
     (build-path unicode-directory "héllo λ.atl"))
   (write-source
    unicode-source
    (string-append
     "#lang alone_the_lambdas\r\n"
     "(def choose first second = first)\r\n"
     "(stdout (choose \"héllo λ\\n\" \"ignored\"))\r\n"))
   (check-command-success
    (run (list "run" (path->string unicode-source)))
    (string->bytes/utf-8 "héllo λ\n"))

   (define relative-source
     (build-path working-directory "relative.atl"))
   (write-source relative-source
                 "#lang alone_the_lambdas\n(stdout \"relative path\")\n")
   (check-command-success
    (run '("run" "relative.atl"))
    #"relative path")

   (define header-only-source
     (build-path working-directory "header-only.atl"))
   (write-exact-bytes header-only-source #"#lang alone_the_lambdas")
   (check-command-success
    (run (list "run" (path->string header-only-source)))
    #"")

   ;; This is the checked-in hello program, loaded outside the installed
   ;; collection by the runner's one dynamic-require call.
   (define hello-source
     (build-path package-source "examples" "hello.atl"))
   (check-command-success
    (run (list "run" (path->string hello-source)))
    #"Hello from Alone the Lambdas.\n")

   ;; Unsupported identifiers still fail in the existing ATL expander. The
   ;; runner has no alternate parser, evaluator, or Racket namespace surface.
   (define unbound-source
     (build-path working-directory "unbound.atl"))
   (write-source unbound-source
                 "#lang alone_the_lambdas\n(display \"escape\")\n")
   (check-runner-failure
    (run (list "run" (path->string unbound-source)))
    65
    #rx"source")

   ;; Object-language Error and expected Result Err values are successful
   ;; completed values. The runner neither observes nor reclassifies them.
   (define object-error-source
     (build-path working-directory "object-error.atl"))
   (write-source object-error-source
                 "#lang alone_the_lambdas\n(stdout 0)\n")
   (check-command-success
    (run (list "run" (path->string object-error-source)))
    #"")

   (define result-error-source
     (build-path working-directory "result-error.atl"))
   (write-source result-error-source
                 "#lang alone_the_lambdas\n(read-file \"absent.txt\")\n")
   (check-command-success
    (run (list "run" (path->string result-error-source)))
    #"")))
