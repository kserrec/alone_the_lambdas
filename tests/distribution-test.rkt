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
(define macos-build-script
  (build-path project-root "tooling" "build-macos-distribution.sh"))
(define macos-consumer-script
  (build-path project-root "tooling" "test-macos-distribution.sh"))
(define windows-build-script
  (build-path project-root "tooling" "build-windows-distribution.ps1"))
(define windows-consumer-script
  (build-path project-root "tooling" "test-windows-distribution.ps1"))
(define workflow-file
  (build-path project-root ".github" "workflows" "tests.yml"))
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

(for ([script (in-list (list build-script
                             consumer-script
                             macos-build-script
                             macos-consumer-script))])
  (check-true (file-exists? script))
  (check-not-false
   (member 'execute (file-or-directory-permissions script)))
  (check-exact-result
   (run-bash (list "-n" (path->string script)))
   0 #"" #""))

(for ([script (in-list (list windows-build-script
                             windows-consumer-script))])
  (check-true (file-exists? script))
  (check-false (link-exists? script)))

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
 (run-bash (list (path->string macos-build-script) "--help"))
 0
 (string->bytes/utf-8
  (string-append
   "Usage:\n"
   "  tooling/build-macos-distribution.sh [--allow-dirty] TARGET_IDENTIFIER OUTPUT_DIRECTORY\n"
   "\n"
   "Build one unpublished native macOS archive with Racket CS 9.3.\n"
   "TARGET_IDENTIFIER must be macos-x86_64 or macos-arm64. OUTPUT_DIRECTORY must\n"
   "already exist outside the source checkout and must not contain the versioned\n"
   "archive or SHA256SUMS.\n"))
 #"")

(check-exact-result
 (run-bash (list (path->string macos-consumer-script) "--help"))
 0
 (string->bytes/utf-8
  (string-append
   "Usage:\n"
   "  tooling/test-macos-distribution.sh OUTPUT_DIRECTORY TARGET_IDENTIFIER\n"
   "\n"
   "Test one transferred unpublished macOS archive on clean native hardware with\n"
   "no Racket installation or source checkout. TARGET_IDENTIFIER must be\n"
   "macos-x86_64 or macos-arm64.\n"))
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

(define macos-build-source
  (file->string macos-build-script))
(check-true (regexp-match? #rx"macos-x86_64" macos-build-source))
(check-true (regexp-match? #rx"macos-arm64" macos-build-source))
(check-true (regexp-match? #rx"uname -s.*Darwin" macos-build-source))
(check-true (regexp-match? #rx"[+][+]lang alone_the_lambdas" macos-build-source))
(check-true (regexp-match? #rx"raco_executable.*distribute" macos-build-source))
(check-true (regexp-match? #rx"mkdir -m 0755 \"[$]artifact_root/lib\"" macos-build-source))
(check-true (regexp-match? #rx"PLTUSERHOME=" macos-build-source))
(check-true (regexp-match? #rx"otool -L" macos-build-source))
(check-true (regexp-match? #rx"lipo -archs" macos-build-source))
(check-true (regexp-match? #rx"gtar" macos-build-source))
(check-true (regexp-match? #rx"gzip -n -9" macos-build-source))
(check-true (regexp-match? #rx"SHA256SUMS" macos-build-source))
(check-false (regexp-match? #rx"--launcher" macos-build-source))

(define macos-consumer-source
  (file->string macos-consumer-script))
(check-true (regexp-match? #rx"consumer unexpectedly has a racket command" macos-consumer-source))
(check-true (regexp-match? #rx"consumer unexpectedly has a source checkout" macos-consumer-source))
(check-true (regexp-match? #rx"generated-after-packaging[.]atl" macos-consumer-source))
(check-true (regexp-match? #rx"decoy-collections" macos-consumer-source))
(check-true (regexp-match? #rx"/dev/tcp/127[.]0[.]0[.]1" macos-consumer-source))
(check-true (regexp-match? #rx"second relocated path" macos-consumer-source))
(check-true (regexp-match? #rx"sw_vers -productVersion" macos-consumer-source))

(define windows-build-source
  (file->string windows-build-script))
(check-true (regexp-match? #rx"windows-x86_64" windows-build-source))
(check-true (regexp-match? #rx"--embed-dlls" windows-build-source))
(check-true (regexp-match? #rx"[+][+]lang.*alone_the_lambdas" windows-build-source))
(check-true (regexp-match? #rx"'distribute'.*rawDistribution" windows-build-source))
(check-true (regexp-match? #rx"PE32[+] machine 0x8664" windows-build-source))
(check-true (regexp-match? #rx"dumpbin[.]exe" windows-build-source))
(check-true (regexp-match? #rx"Get-AuthenticodeSignature" windows-build-source))
(check-true (regexp-match? #rx"1980, 1, 1" windows-build-source))
(check-true (regexp-match? #rx"SHA256SUMS" windows-build-source))
(check-true (regexp-match? #rx"PLTUSERHOME" windows-build-source))
(check-true (regexp-match? #rx"Get-SafeTreeEntries.*-SkipCompiled" windows-build-source))
(check-false (regexp-match? #rx"--launcher" windows-build-source))

(define windows-consumer-source
  (file->string windows-consumer-script))
(check-true (regexp-match? #rx"consumer unexpectedly has a racket command" windows-consumer-source))
(check-true (regexp-match? #rx"consumer unexpectedly has a source checkout" windows-consumer-source))
(check-true (regexp-match? #rx"generated-after-packaging[.]atl" windows-consumer-source))
(check-true (regexp-match? #rx"decoy-collections" windows-consumer-source))
(check-true (regexp-match? #rx"TcpClient" windows-consumer-source))
(check-true (regexp-match? #rx"LocalApplicationData" windows-consumer-source))
(check-true (regexp-match? #rx"relocation_drives=different" windows-consumer-source))
(check-true (regexp-match? #rx"Get-AuthenticodeSignature" windows-consumer-source))
(check-true (regexp-match? #rx"Assert-ProcessResult.*64" windows-consumer-source))
(check-true (regexp-match? #rx"Assert-ProcessResult.*65" windows-consumer-source))
(check-true (regexp-match? #rx"Assert-ProcessResult.*66" windows-consumer-source))

(define workflow-source
  (file->string workflow-file))
(check-true (regexp-match? #rx"runner: macos-15-intel" workflow-source))
(check-true (regexp-match? #rx"runner: macos-15" workflow-source))
(check-true (regexp-match? #rx"racket-architecture: x64" workflow-source))
(check-true (regexp-match? #rx"racket-architecture: arm64" workflow-source))
(check-true
 (regexp-match?
  #rx"actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a"
  workflow-source))
(check-true
 (regexp-match?
  #rx"actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c"
  workflow-source))
(check-true (regexp-match? #rx"retention-days: 1" workflow-source))
(check-true (regexp-match? #rx"actions: write" workflow-source))
(check-true (regexp-match? #rx"gh api --method DELETE" workflow-source))
(check-true (regexp-match? #rx"windows-distribution-build" workflow-source))
(check-true (regexp-match? #rx"windows-distribution-consumer" workflow-source))
(check-true (regexp-match? #rx"windows-distribution-artifact-cleanup" workflow-source))
(check-true (regexp-match? #rx"runs-on: windows-2025" workflow-source))
(check-true (regexp-match? #rx"architecture: x64" workflow-source))
(check-true (regexp-match? #rx"atl-windows-x86_64-[$][{][{] github[.]sha [}][}]" workflow-source))

(for ([template-name
       (in-list '("GETTING_STARTED.md.in"
                  "THIRD_PARTY_NOTICES.md.in"))])
  (define template-content
    (file->string (build-path distribution-directory template-name)))
  (check-false (regexp-match? #rx"0[.]2[.]0-dev" template-content)))

(check-false
 (or (file-exists? (build-path distribution-directory "LICENSE"))
     (link-exists? (build-path distribution-directory "LICENSE"))))
