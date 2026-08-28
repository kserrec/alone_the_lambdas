#lang racket/base

(require rackunit
         racket/file
         racket/list
         racket/path
         racket/runtime-path
         "../tooling/check-boundaries.rkt")

(define-runtime-path project-root "..")

(define clean-macro-shell-datum
  '(module lazy-with-macros racket/base
     (#%module-begin
      (require lazy/lazy)
      (provide (all-from-out lazy/lazy)
               #%module-begin
               #%app
               #%datum
               #%top))))

(define clean-macro-datum
  '(module macros lazy
     (#%module-begin
      (require (for-syntax racket/base))
      (provide def lambda-let define-function-name))))

(define (write-datum path datum)
  (call-with-output-file path
    #:exists 'truncate
    (lambda (output)
      (write datum output))))

(define (read-datum path)
  (call-with-input-file path
    (lambda (input)
      (parameterize ([read-accept-reader #t]
                     [current-load-relative-directory (path-only path)])
        (read input)))))

(define (append-module-form datum form)
  (list 'module
        (cadr datum)
        (caddr datum)
        (append (cadddr datum) (list form))))

(define (kinds findings)
  (map boundary-violation-kind findings))

(define (normalized path)
  (simplify-path (path->complete-path path) #f))

(define (observe-source-operations watched relevant? procedure)
  (define normalized-watched
    (map normalized watched))
  (define operation-count 0)
  (define guard
    (make-security-guard
     (current-security-guard)
     (lambda (who path permissions)
       (when (and (relevant? permissions)
                  (member (normalized path)
                          normalized-watched
                          equal?))
         (set! operation-count (add1 operation-count))))
     (lambda (who host-name port mode)
       (void))))
  (define result
    (parameterize ([current-security-guard guard])
      (procedure)))
  (values result operation-count))

(define (observe-source-reads watched procedure)
  (observe-source-operations watched
                             (lambda (permissions)
                               (memq 'read permissions))
                             procedure))

(define (observe-source-accesses watched procedure)
  (observe-source-operations
   watched
   (lambda (permissions)
     (or (memq 'exists permissions)
         (memq 'read permissions)))
   procedure))

(define (check-rejected-root-without-traversal unsafe-root)
  (define-values (findings access-count)
    (observe-source-accesses
     (list (build-path unsafe-root "effects")
           (build-path unsafe-root "macros")
           (build-path unsafe-root "runtime")
           (build-path unsafe-root "core"))
     (lambda ()
       (project-boundary-violations unsafe-root))))
  (check-equal? (kinds findings) '(disallowed-boundary-root))
  (check-equal? access-count 0))

(define (temporary-project procedure)
  (define root
    (make-temporary-file "alone-the-lambdas-boundary-~a"
                         'directory
                         (current-directory)))
  (dynamic-wind
    (lambda ()
      (for ([directory
             (in-list '("core" "effects" "macros" "runtime" "lang"))])
        (make-directory (build-path root directory)))
      (copy-file (build-path project-root "lang" "expander.rkt")
                 (build-path root "lang" "expander.rkt"))
      (copy-file (build-path project-root "lang" "reader.rkt")
                 (build-path root "lang" "reader.rkt"))
      (copy-file (build-path project-root "info.rkt")
                 (build-path root "info.rkt"))
      (write-datum
       (build-path root "macros" "lazy-with-macros.rkt")
       clean-macro-shell-datum)
      (write-datum
       (build-path root "macros" "macros.rkt")
       clean-macro-datum)
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
           (provide make-host-bridge)
           (def make-host-bridge value =
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
                    object-nat->integer
                    integer->object-nat
                    object-ok
                    object-err))))
      (write-datum
       (build-path root "runtime" "host.rkt")
       '(module host racket/base
          (#%module-begin
           (require (only-in "../effects/protocol.rkt" make-host-bridge)
                    (only-in "codec.rkt" object-ok))
           (provide host)
           (define (host request) request)))))
    (lambda () (procedure root))
    (lambda () (delete-directory/files root))))

(check-equal? (project-boundary-violations project-root)
              '())

(temporary-project
 (lambda (root)
   (check-equal? (project-boundary-violations root) '())

   ;; The authorization anchor is checked before project discovery. Neither a
   ;; symlink supplied as the root nor one in an ancestor component can make
   ;; the checker traverse the linked project tree.
   (define root-link (build-path root "linked-project-root"))
   (make-file-or-directory-link root root-link)
   (check-rejected-root-without-traversal root-link)
   (delete-file root-link)

   (define parent-link (build-path root "linked-project-parent"))
   (make-file-or-directory-link (path-only root) parent-link)
   (check-rejected-root-without-traversal
    (build-path parent-link (file-name-from-path root)))
   (delete-file parent-link)

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

   ;; Phase 17 HTTP computation remains in the same closed pure class. Host
   ;; String, regex, arithmetic, and HTTP-library helpers are each rejected.
   (check-effect
    '(module example "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (require "../macros/macros.rkt")
        (provide use)
        (def use value =
          (string-length value))))
    '(unapproved-effect-identifier))

   (check-effect
    '(module example "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (require "../macros/macros.rkt")
        (provide use)
        (def use value =
          (regexp-match? value))))
    '(unapproved-effect-identifier))

   (check-effect
    '(module example "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (require "../macros/macros.rkt")
        (provide use)
        (def use value =
          (+ value))))
    '(unapproved-effect-identifier))

   (check-effect
    '(module example "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (require "../macros/macros.rkt"
                 net/http-client)
        (provide use)
        (def use value =
          (http-sendrecv value))))
    '(disallowed-effect-import
      unapproved-effect-identifier))

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
    '(disallowed-effect-import
      unapproved-effect-identifier))

   ;; Filesystem access happens only after import authorization. A rejected
   ;; full import is reported without touching even an ordinary regular
   ;; target's metadata or content.
   (define unapproved-directory (build-path root "unapproved"))
   (define unapproved-target
     (build-path unapproved-directory "plain.rkt"))
   (make-directory unapproved-directory)
   (write-datum
    unapproved-target
    '(module plain racket/base
       (#%module-begin
        (provide external-value))))
   (write-datum
    effect
    '(module example "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (require "../unapproved/plain.rkt")
        (provide use)
        (def use value =
          (external-value value)))))
   (define-values (disallowed-import-findings disallowed-target-accesses)
     (observe-source-accesses
      (list unapproved-target)
      (lambda ()
        (file-boundary-violations effect 'effect root))))
   (check-not-false
    (member 'disallowed-effect-import
            (kinds disallowed-import-findings)))
   (check-equal? disallowed-target-accesses 0)
   (delete-file unapproved-target)
   (delete-directory unapproved-directory)

   (define codec (build-path root "runtime" "candidate-codec.rkt"))
   (define (codec-datum extra)
     `(module codec racket/base
        (#%module-begin
         (provide (struct-out codec-failure)
                  object-list->host-list
                  host-list->object-list
                  object-string->bytes
                  bytes->object-string
                  object-nat->integer
                  integer->object-nat
                  object-ok
                  object-err)
         ,extra)))

   (write-datum codec
                (codec-datum '(define leak (display "effect"))))
   (check-equal?
    (kinds (file-boundary-violations codec 'codec root))
    '(forbidden-codec-capability))

   ;; File conversion remains privileged even after the host gains the
   ;; approved read-file operation.
   (write-datum codec
                (codec-datum '(define leak (file->bytes "path"))))
   (check-equal?
    (kinds (file-boundary-violations codec 'codec root))
    '(forbidden-codec-capability))

   ;; Deterministic conversion never gains network authority.
   (write-datum codec
                (codec-datum '(define leak (tcp-connect "host" 80))))
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
         (require (only-in "../effects/protocol.rkt" make-host-bridge)
                  (only-in "codec.rkt" object-ok))
         ,provide-form
         (define (host request) ,body))))

   (write-datum host-file
                (host-datum '(provide host) 'request))
   (check-equal? (file-boundary-violations host-file 'host root)
                 '())

   ;; Phase 16 admits exactly the five TCP bindings used by the sole host.
   (write-datum
    host-file
    '(module host racket/base
       (#%module-begin
        (require (only-in racket/tcp
                          tcp-accept
                          tcp-addresses
                          tcp-close
                          tcp-connect
                          tcp-listen)
                 (only-in "../effects/protocol.rkt" make-host-bridge)
                 (only-in "codec.rkt" object-ok))
        (provide host)
        (define (host request) request))))
   (check-equal? (file-boundary-violations host-file 'host root)
                 '())

   (write-datum
    host-file
    '(module host racket/base
       (#%module-begin
        (require racket/tcp
                 (only-in "../effects/protocol.rkt" make-host-bridge)
                 (only-in "codec.rkt" object-ok))
        (provide host)
        (define (host request) request))))
   (check-equal?
    (kinds (file-boundary-violations host-file 'host root))
    '(disallowed-host-import))

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

   ;; Deletion and broad racket/file imports remain outside the closed host
   ;; capability set.
   (write-datum host-file
                (host-datum '(provide host) '(delete-file request)))
   (check-equal?
    (kinds (file-boundary-violations host-file 'host root))
    '(forbidden-host-capability))

   (write-datum
    host-file
    '(module host racket/base
       (#%module-begin
        (require (only-in racket/file file->bytes directory-list)
                 (only-in "../effects/protocol.rkt" make-host-bridge)
                 (only-in "codec.rkt" object-ok))
        (provide host)
        (define (host request) request))))
   (define broad-file-findings
     (kinds (file-boundary-violations host-file 'host root)))
   (check-not-false (member 'disallowed-host-import broad-file-findings))
   (check-not-false (member 'forbidden-host-capability broad-file-findings))

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
        (require (only-in "../effects/protocol.rkt" make-host-bridge)
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
            (kinds (project-boundary-violations root))))

   (delete-file codec)
   (delete-file host-file)
   (write-datum
    effect
    '(module example "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (require "../macros/macros.rkt"
                 (only-in "../core/dependency.rkt" identity))
        (provide use)
        (def use value =
          (identity value)))))
   (check-equal? (project-boundary-violations root) '())

   (define (project-kinds)
     (kinds (project-boundary-violations root)))

   (define (check-project-kind kind)
     (check-not-false (member kind (project-kinds))))

   ;; Require wrappers cannot hide either privileged runtime module from the
   ;; project-wide scan. These core fixtures isolate the global detector from
   ;; the stricter effect and macro module classes.
   (define core-bridge (build-path root "core" "bridge.rkt"))
   (write-datum
    core-bridge
    '(module bridge racket/base
       (#%module-begin
        (require (rename-in "../runtime/codec.rkt"
                            [object-ok bridge]))
        (provide bridge))))
   (check-project-kind 'unauthorized-codec-import)
   (delete-file core-bridge)

   (write-datum
    core-bridge
    '(module bridge racket/base
       (#%module-begin
        (require (combine-in "../runtime/codec.rkt"
                             "dependency.rkt")))))
   (check-project-kind 'unauthorized-codec-import)
   (delete-file core-bridge)

   ;; A require transformer that has not been explicitly classified fails
   ;; closed instead of becoming a new way to conceal a privileged path.
   (write-datum
    core-bridge
    '(module bridge racket/base
       (#%module-begin
        (require (relative-in "../runtime" "codec.rkt")))))
   (check-project-kind 'unclassified-production-import)
   (delete-file core-bridge)

   (write-datum
    core-bridge
    '(module bridge racket/base
       (#%module-begin
        (require (prefix-in codec: "../runtime/codec.rkt")))))
   (check-project-kind 'unauthorized-codec-import)
   (delete-file core-bridge)

   (write-datum
    core-bridge
    '(module bridge racket/base
       (#%module-begin
        (require (rename-in "../runtime/host.rkt" [host bridge]))
        (provide bridge))))
   (check-project-kind 'unauthorized-host-import)
   (delete-file core-bridge)

   ;; The sole-host rule is global: even a class not otherwise inspected by
   ;; this checker cannot become a second filesystem or TCP importer.
   (write-datum
    core-bridge
    '(module bridge racket/base
       (#%module-begin
        (require (only-in racket/tcp tcp-connect)))))
   (check-project-kind 'unauthorized-host-capability-import)
   (delete-file core-bridge)

   (write-datum
    core-bridge
    '(module bridge racket/base
       (#%module-begin
        (require (only-in racket/file file->bytes)))))
   (check-project-kind 'unauthorized-host-capability-import)
   (delete-file core-bridge)

   ;; A symlinked directory cannot disguise runtime code as an allowed core
   ;; dependency. The individual effect check rejects it without metadata or
   ;; content access beneath the link; the project gate never opens its target.
   (define core-alias (build-path root "core" "runtime-alias"))
   (define linked-codec (build-path core-alias "codec.rkt"))
   (define linked-effect (build-path root "effects" "linked-escape.rkt"))
   (make-file-or-directory-link (build-path root "runtime") core-alias)
   (write-datum
    linked-effect
    '(module linked-escape "../macros/lazy-with-macros.rkt"
       (#%module-begin
        (require "../macros/macros.rkt"
                 "../core/runtime-alias/codec.rkt")
        (provide use)
        (def use value =
          (object-ok value)))))
   (define-values (linked-effect-findings linked-effect-accesses)
     (observe-source-accesses
      (list linked-codec)
      (lambda ()
        (file-boundary-violations linked-effect 'effect root))))
   (check-not-false
    (member 'disallowed-effect-import
            (kinds linked-effect-findings)))
   (check-equal? linked-effect-accesses 0)
   (define-values (linked-project-kinds linked-project-reads)
     (observe-source-reads
      (list core-alias linked-codec)
      project-kinds))
   (check-not-false
    (member 'disallowed-boundary-path linked-project-kinds))
   (check-equal? linked-project-reads 0)
   (delete-file linked-effect)
   (delete-file core-alias)

   ;; The macro layer is trusted to translate syntax mechanically, not to gain
   ;; operating-system authority. Exact imports plus a closed source
   ;; vocabulary catch both explicit capabilities and unknown implicit ones.
   (define macro-file (build-path root "macros" "macros.rkt"))
   (write-datum
    macro-file
    '(module macros lazy
       (#%module-begin
        (require (for-syntax racket/base)
                 racket/system)
        (provide def lambda-let define-function-name)
        (define-for-syntax leak (system "true")))))
   (check-project-kind 'invalid-macro-imports)
   (check-project-kind 'forbidden-macro-capability)
   (write-datum macro-file clean-macro-datum)

   (write-datum
    macro-file
    '(module macros lazy
       (#%module-begin
        (require (for-syntax racket/base))
        (provide def lambda-let define-function-name)
        (define-for-syntax observed (current-seconds)))))
   (check-project-kind 'unapproved-macro-identifier)
   (write-datum macro-file clean-macro-datum)

   (write-datum
    macro-file
    '(module macros lazy
       (#%module-begin
        (require (for-syntax racket/base)
                 (rename-in "../runtime/codec.rkt"
                            [object-ok bridge]))
        (provide def lambda-let define-function-name))))
   (check-project-kind 'invalid-macro-imports)
   (check-project-kind 'unauthorized-codec-import)
   (write-datum macro-file clean-macro-datum)

   ;; Both trusted paths are pinned, and new macro or language modules remain
   ;; outside the approved production classifications.
   (define macro-shell
     (build-path root "macros" "lazy-with-macros.rkt"))
   (write-datum
    macro-shell
    '(module lazy-with-macros racket/base
       (#%module-begin
        (require lazy/lazy)
        (provide (all-from-out lazy/lazy)
                 #%module-begin
                 #%app
                 #%datum
                 #%top)
        (define leak 'host-value))))
   (check-project-kind 'invalid-macro-shell-forms)
   (write-datum macro-shell clean-macro-shell-datum)

   (define macro-target (build-path root "macro-target.rkt"))
   (write-datum macro-target clean-macro-datum)
   (delete-file macro-file)
   (make-file-or-directory-link macro-target macro-file)
   (define-values (macro-symlink-kinds unsafe-macro-reads)
     (observe-source-reads (list macro-file) project-kinds))
   (check-not-false
    (member 'disallowed-boundary-path macro-symlink-kinds))
   (check-equal? unsafe-macro-reads 0)
   (delete-file macro-file)
   (delete-file macro-target)
   (write-datum macro-file clean-macro-datum)

   ;; Phase 19 admits exactly one reader, one facade/expander, and the pinned
   ;; package metadata. The facade alone may import and re-export production
   ;; host; its other imports, public surface, runtime definitions, and source
   ;; vocabulary remain closed.
   (define language-expander
     (build-path root "lang" "expander.rkt"))
   (define language-reader
     (build-path root "lang" "reader.rkt"))
   (define package-info
     (build-path root "info.rkt"))
   (define clean-language-expander-datum
     (read-datum language-expander))
   (define clean-language-reader-datum
     (read-datum language-reader))
   (define clean-package-info-datum
     (read-datum package-info))

   (check-equal?
    (file-boundary-violations language-expander
                              'language-expander
                              root)
    '())
   (check-equal?
    (file-boundary-violations language-reader
                              'language-reader
                              root)
    '())
   (check-equal?
    (file-boundary-violations package-info 'package-info root)
    '())

   (write-datum
    language-expander
    (append-module-form
     clean-language-expander-datum
     '(require (only-in racket/file file->bytes))))
   (define expanded-capability-kinds
     (kinds
      (file-boundary-violations language-expander
                                'language-expander
                                root)))
   (check-not-false
    (member 'invalid-language-expander-imports
            expanded-capability-kinds))
   (check-not-false
    (member 'forbidden-language-capability
            expanded-capability-kinds))
   (write-datum language-expander clean-language-expander-datum)

   (write-datum
    language-expander
    (append-module-form clean-language-expander-datum
                        '(provide raw-cons)))
   (check-not-false
    (member 'invalid-language-expander-export
            (kinds
             (file-boundary-violations language-expander
                                       'language-expander
                                       root))))
   (write-datum language-expander clean-language-expander-datum)

   (write-datum
    language-expander
    (append-module-form
     clean-language-expander-datum
     '(def escape =
        (language-make-stdout language-host))))
   (check-not-false
    (member 'invalid-language-runtime-definitions
            (kinds
             (file-boundary-violations language-expander
                                       'language-expander
                                       root))))
   (write-datum language-expander clean-language-expander-datum)

   (write-datum
    language-expander
    (append-module-form
     clean-language-expander-datum
     '(define-for-syntax (clock)
        (current-seconds))))
   (define expanded-vocabulary-kinds
     (kinds
      (file-boundary-violations language-expander
                                'language-expander
                                root)))
   (check-not-false
    (member 'unapproved-language-syntax-helper
            expanded-vocabulary-kinds))
   (check-not-false
    (member 'unapproved-language-identifier
            expanded-vocabulary-kinds))
   (write-datum language-expander clean-language-expander-datum)

   (write-datum
    language-reader
    (append-module-form clean-language-reader-datum
                        'racket/base))
   (check-equal?
    (kinds
     (file-boundary-violations language-reader
                               'language-reader
                               root))
    '(invalid-language-reader-forms))
   (write-datum language-reader clean-language-reader-datum)

   (write-datum
    package-info
    (append-module-form clean-package-info-datum
                        '(define leak "host")))
   (check-equal?
    (kinds
     (file-boundary-violations package-info 'package-info root))
    '(invalid-package-info-forms))
   (write-datum package-info clean-package-info-datum)

   (define extra-macro (build-path root "macros" "extra.rkt"))
   (write-datum
    extra-macro
    '(module extra racket/base
       (#%module-begin)))
   (check-project-kind 'unclassified-macro-module)
   (delete-file extra-macro)

   (define language-file (build-path root "lang" "main.rkt"))
   (write-datum
    language-file
    '(module main racket/base
       (#%module-begin
        (require (only-in "../runtime/host.rkt" host))
        (provide host))))
   (check-project-kind 'unclassified-language-module)
   (check-project-kind 'unauthorized-host-import)
   (check-project-kind 'unauthorized-host-export)
   (delete-file language-file)

   (check-equal? (project-boundary-violations root) '())))
