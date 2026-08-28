#lang racket/base

(require rackunit
         racket/file
         racket/list
         racket/path
         racket/runtime-path
         "helpers/fresh-language.rkt")

(define-runtime-path project-root-path "..")
(define project-root
  (simplify-path project-root-path #f))
(define build-script
  (build-path project-root "tooling" "build-linux-distribution.sh"))
(define consumer-script
  (build-path project-root "tooling" "test-linux-distribution.sh"))
(define distribution-directory
  (build-path project-root "distribution"))
(define bash-executable
  (find-executable-path "bash"))

(check-not-false bash-executable)

(define environment
  (environment-variables-copy (current-environment-variables)))

(define (run-bash arguments)
  (run-command environment bash-executable arguments 20))

(define (check-exact-result result status stdout stderr)
  (check-false (command-result-timed-out? result)
               (result-diagnostic result))
  (check-equal? (command-result-status result)
                status
                (result-diagnostic result))
  (check-equal? (command-result-stdout result)
                stdout
                (result-diagnostic result))
  (check-equal? (command-result-stderr result)
                stderr
                (result-diagnostic result)))

(for ([script (in-list (list build-script consumer-script))])
  (check-true (file-exists? script))
  (check-not-false
   (member 'execute (file-or-directory-permissions script)))
  (check-exact-result
   (run-bash (list "-n" (path->string script)))
   0 #"" #""))

(check-exact-result
 (run-bash (list (path->string build-script) "--help"))
 0
 (string->bytes/utf-8
  (string-append
   "Usage:\n"
   "  tooling/build-linux-distribution.sh [--allow-dirty] OUTPUT_DIRECTORY\n"
   "\n"
   "Build the unpublished Linux x86-64 archive with Racket CS 9.3. The output\n"
   "directory must be outside the source checkout and must not already contain the\n"
   "versioned archive or SHA256SUMS.\n"))
 #"")

(check-exact-result
 (run-bash (list (path->string consumer-script) "--help"))
 0
 (string->bytes/utf-8
  (string-append
   "Usage:\n"
   "  tooling/test-linux-distribution.sh OUTPUT_DIRECTORY\n"
   "\n"
   "Transfer the unpublished Linux archive and its checksum into a locked-down\n"
   "Ubuntu 24.04 container with no Racket installation, then run the Phase 24\n"
   "consumer and relocation acceptance checks.\n"))
 #"")

(check-exact-result
 (run-bash (list (path->string build-script) (path->string project-root)))
 2
 #""
 #"build-linux-distribution: OUTPUT_DIRECTORY must be outside the source checkout\n")

(define (dotenv-name? name)
  (regexp-match? #px"(^|[.])env($|[.])" (string-downcase name)))

(define asset-names
  (sort
   (for/list ([entry (in-list (directory-list distribution-directory))]
              #:unless (dotenv-name? (path->string entry)))
     (path->string entry))
   string<?))
(check-equal?
 asset-names
 '("GETTING_STARTED.md.in"
   "THIRD_PARTY_NOTICES.md.in"
   "UNPUBLISHED-DEVELOPMENT-ARTIFACT.txt"))

(for ([asset-name (in-list asset-names)])
  (define asset-path
    (build-path distribution-directory asset-name))
  (check-true (file-exists? asset-path))
  (check-false (link-exists? asset-path)))

(define build-source
  (file->string build-script))
(check-true (regexp-match? #rx"[+][+]lang alone_the_lambdas" build-source))
(check-true (regexp-match? #rx"raco_executable.*distribute" build-source))
(check-true (regexp-match? #rx"PLTUSERHOME=" build-source))
(check-true (regexp-match? #rx"gzip -n -9" build-source))
(check-true (regexp-match? #rx"SHA256SUMS" build-source))

(define consumer-source
  (file->string consumer-script))
(check-true
 (regexp-match?
  #px"ubuntu:24[.]04@sha256:[0-9a-f]{64}"
  consumer-source))
(check-true (regexp-match? #rx"--network none" consumer-source))
(check-true (regexp-match? #rx"--read-only" consumer-source))

(for ([template-name
       (in-list '("GETTING_STARTED.md.in"
                  "THIRD_PARTY_NOTICES.md.in"))])
  (define template-content
    (file->string (build-path distribution-directory template-name)))
  (check-false (regexp-match? #rx"0[.]2[.]0-dev" template-content)))

(check-false
 (or (file-exists? (build-path distribution-directory "LICENSE"))
     (link-exists? (build-path distribution-directory "LICENSE"))))
