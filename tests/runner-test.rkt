#lang racket/base

(require rackunit
         racket/file
         racket/path
         racket/runtime-path
         racket/string
         "helpers/fresh-language.rkt")

(define-runtime-path project-root-path "..")

(define project-root
  (simplify-path project-root-path #f))

(define expected-help
  #"Usage:\n  atl run FILE.atl\n  atl --help\n  atl --version\n")

(define (check-runner-failure result expected-status expected-stderr)
  (check-false (command-result-timed-out? result)
               (result-diagnostic result))
  (check-equal? (command-result-status result)
                expected-status
                (result-diagnostic result))
  (check-equal? (command-result-stdout result)
                #""
                (result-diagnostic result))
  (check-equal? (command-result-stderr result)
                expected-stderr
                (result-diagnostic result)))

(define (command-diagnostic reason)
  (string->bytes/utf-8
   (format "Alone the Lambdas: ~a\n" reason)))

(define (source-diagnostic source reason
                           #:line [line #f]
                           #:column [column #f])
  (string->bytes/utf-8
   (if (and line column)
       (format "Alone the Lambdas: ~s:~a:~a: ~a\n"
               source line column reason)
       (format "Alone the Lambdas: ~s: ~a\n"
               source reason))))

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
      (command-diagnostic
       "expected atl run FILE.atl, atl --help, or atl --version")))

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
    (source-diagnostic
     "program.env.rkt"
     "refused source path because dotenv files are never read"))
   (check-runner-failure
    (run '("run" ".ENV.local/program.atl"))
    66
    (source-diagnostic
     ".ENV.local/program.atl"
     "refused source path because dotenv files are never read"))
   (check-runner-failure
    (run '("run" "missing.rkt"))
    65
    (source-diagnostic
     "missing.rkt"
     "source file name must end in lowercase .atl"))
   (check-runner-failure
    (run '("run" "missing.ATL"))
    65
    (source-diagnostic
     "missing.ATL"
     "source file name must end in lowercase .atl"))
   (check-runner-failure
    (run '("run" "missing.atl"))
    66
    (source-diagnostic
     "missing.atl"
     "source file was not found"))

   (define directory-source
     (build-path working-directory "directory.atl"))
   (make-directory directory-source)
   (check-runner-failure
    (run (list "run" (path->string directory-source)))
    66
    (source-diagnostic
     (path->string directory-source)
     "source path is not a regular file"))

   (define unreadable-source
     (build-path working-directory "unreadable.atl"))
   (write-source unreadable-source
                 "#lang alone_the_lambdas\n(stdout \"no\")\n")
   (define unreadable-result
     (dynamic-wind
       (lambda ()
         (file-or-directory-permissions unreadable-source #o000))
       (lambda ()
         (run '("run" "unreadable.atl")))
       (lambda ()
         (file-or-directory-permissions unreadable-source #o600))))
   (check-runner-failure
    unreadable-result
    66
    (source-diagnostic
     "unreadable.atl"
     "source file could not be read"))

   (define malformed-header
     (build-path working-directory "malformed.atl"))
   (write-source malformed-header
                 " #lang alone_the_lambdas\n(stdout \"no\")\n")
   (check-runner-failure
    (run (list "run" (path->string malformed-header)))
    65
    (source-diagnostic
     (path->string malformed-header)
     "line 1 must be exactly #lang alone_the_lambdas"))

   (define bare-carriage-return-header
     (build-path working-directory "bare-carriage-return.atl"))
   (write-exact-bytes
    bare-carriage-return-header
    #"#lang alone_the_lambdas\r(stdout \"no\")\n")
   (check-runner-failure
    (run (list "run" (path->string bare-carriage-return-header)))
    65
    (source-diagnostic
     (path->string bare-carriage-return-header)
     "line 1 must be exactly #lang alone_the_lambdas"))

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
      (source-diagnostic
       (path->string malformed-path)
       "line 1 must be exactly #lang alone_the_lambdas")))

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
    (source-diagnostic
     (path->string linked-source)
     "refused symbolic-link source; choose a regular .atl file"))

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
    (source-diagnostic
     (path->string
      (build-path ordinary-parent-link "program.atl"))
     "refused source path because dotenv files are never read"))

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

   (define unicode-failure-name
     (path->string
      (build-path "source space lambda-λ" "unknown λ.atl")))
   (define unicode-failure-source
     (build-path working-directory unicode-failure-name))
   (write-source unicode-failure-source
                 "#lang alone_the_lambdas\n(display \"escape\")\n")
   (check-runner-failure
    (run (list "run" unicode-failure-name))
    65
    (source-diagnostic
     unicode-failure-name
     "unknown ATL name: display"
     #:line 2
     #:column 1))

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
   ;; runner reports only the original spelling and source position, never the
   ;; resolved temporary/package path or Racket exception rendering.
   (define unbound-source
     (build-path working-directory "unbound.atl"))
   (write-source unbound-source
                 "#lang alone_the_lambdas\n(display \"escape\")\n")
   (define unbound-result
     (run '("run" "unbound.atl")))
   (check-runner-failure
    unbound-result
    65
    (source-diagnostic
     "unbound.atl"
     "unknown ATL name: display"
     #:line 2
     #:column 1))
   (check-false
    (regexp-match?
     (regexp (regexp-quote (path->string temporary-root)))
     (bytes->string/utf-8 (command-result-stderr unbound-result)))
    (result-diagnostic unbound-result))

   (define wrong-public-name-source
     (build-path working-directory "wrong-public-name.atl"))
   (write-source
    wrong-public-name-source
    "#lang alone_the_lambdas\n(_if TRUE \"yes\" \"no\")\n")
   (check-runner-failure
    (run '("run" "wrong-public-name.atl"))
    65
    (source-diagnostic
     "wrong-public-name.atl"
     "unknown ATL name: _if"
     #:line 2
     #:column 1))

   (define unsupported-datum-source
     (build-path working-directory "unsupported-datum.atl"))
   (write-source unsupported-datum-source
                 "#lang alone_the_lambdas\n#t\n")
   (check-runner-failure
    (run '("run" "unsupported-datum.atl"))
    65
    (source-diagnostic
     "unsupported-datum.atl"
     "unsupported literal; only nonnegative Nat and String literals are supported"
     #:line 2
     #:column 0))

   (define reader-failure-source
     (build-path working-directory "reader-failure.atl"))
   (write-source reader-failure-source
                 "#lang alone_the_lambdas\n(stdout \"unterminated\"\n")
   (check-runner-failure
    (run '("run" "reader-failure.atl"))
    65
    (source-diagnostic
     "reader-failure.atl"
     "source could not be read; check delimiters and UTF-8 encoding"
     #:line 2
     #:column 0))

   (define invalid-encoding-source
     (build-path working-directory "invalid-encoding.atl"))
   (write-exact-bytes
    invalid-encoding-source
    #"#lang alone_the_lambdas\n\377\n")
   (check-runner-failure
    (run '("run" "invalid-encoding.atl"))
    65
    (source-diagnostic
     "invalid-encoding.atl"
     "source is not valid UTF-8"))

   ;; A disposable copy replaces only the runner's one loader expression with
   ;; a host failure containing raw detail. The production catch path must
   ;; classify it as status 70 and discard every raw detail byte.
   (define runner-source
     (file->string runner))
   (define loader-expression
     "(dynamic-require source-path #f)")
   (check-equal?
    (length
     (regexp-match* #rx"[(]dynamic-require source-path #f[)]"
                    runner-source))
    1)
   (define fault-runner
     (build-path package-source "runner" "atl-phase-23-fault.rkt"))
   (write-source
    fault-runner
    (string-replace
     runner-source
     loader-expression
     "(error 'phase-23-test \"raw host detail: ~s\" car)"))
   (define internal-failure-result
     (run-command environment
                  racket-executable
                  (list (path->string fault-runner)
                        "run"
                        "header-only.atl")
                  20
                  #:current-directory working-directory))
   (check-runner-failure
    internal-failure-result
    70
    (source-diagnostic
     "header-only.atl"
     "unexpected launcher failure; verify the ATL installation"))
   (check-false
    (regexp-match? #rx"raw host detail|#<procedure|package-source"
                   (bytes->string/utf-8
                    (command-result-stderr internal-failure-result)))
    (result-diagnostic internal-failure-result))

   ;; Object-language Error, pure Result Err, and real-host Result Err values
   ;; are three distinct successful completions. The runner neither observes
   ;; nor reclassifies any of them.
   (define object-error-source
     (build-path working-directory "object-error.atl"))
   (write-source object-error-source
                 "#lang alone_the_lambdas\n(stdout 0)\n")
   (check-command-success
    (run '("run" "object-error.atl"))
    #"")

   (define pure-result-error-source
     (build-path working-directory "pure-result-error.atl"))
   (write-source pure-result-error-source
                 "#lang alone_the_lambdas\n(DIV ONE ZERO)\n")
   (check-command-success
    (run '("run" "pure-result-error.atl"))
    #"")

   (define host-result-error-source
     (build-path working-directory "host-result-error.atl"))
   (write-source host-result-error-source
                 "#lang alone_the_lambdas\n(read-file \"absent.txt\")\n")
   (check-command-success
    (run '("run" "host-result-error.atl"))
    #"")))
