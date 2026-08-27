#lang racket/base

;; Structural gate for the deliberately nonuniform Phase 14 production tree.
;; `check-purity.rkt` remains the expanded zero-exception proof for core/. This
;; checker adds the approved classes without weakening that proof:
;;
;;   effects/             pure source forms and closed project imports
;;   runtime/codec.rkt    deterministic conversion, no effect capabilities
;;   runtime/host.rkt     sole host export and the Phase 14 stdout allowlist

(require racket/file
         racket/list
         racket/path
         racket/runtime-path)

(provide (struct-out boundary-violation)
         file-boundary-violations
         project-boundary-violations)

(struct boundary-violation (path kind detail)
  #:transparent)

(struct module-info (language forms)
  #:transparent)

(define-runtime-path default-project-root "..")

(define effect-language "../macros/lazy-with-macros.rkt")
(define effect-macro-import "../macros/macros.rkt")

(define forbidden-codec-capabilities
  '(current-input-port current-output-port current-error-port
    read read-byte read-bytes read-line write write-byte write-bytes
    display print printf eprintf flush-output
    open-input-file open-output-file call-with-input-file
    call-with-output-file file->bytes file->string
    directory-list make-directory make-directory* delete-directory
    delete-directory/files delete-file rename-file-or-directory copy-file
    tcp-connect tcp-listen tcp-accept tcp-close udp-open-socket
    system system* process process* subprocess shell-execute
    eval dynamic-require namespace-require make-base-namespace
    ffi-lib get-ffi-obj getenv putenv current-environment-variables
    thread thread/suspend-to-kill future place
    set! set-box! vector-set! hash-set! hash-set*! bytes-set! string-set!
    make-hash make-hasheq make-weak-hash register registry))

(define forbidden-host-capabilities
  '(read read-byte read-bytes read-line write write-byte display print printf
    open-input-file open-output-file call-with-input-file
    call-with-output-file file->bytes file->string
    directory-list make-directory make-directory* delete-directory
    delete-directory/files delete-file rename-file-or-directory copy-file
    tcp-connect tcp-listen tcp-accept tcp-close udp-open-socket
    system system* process process* subprocess shell-execute
    eval dynamic-require namespace-require make-base-namespace
    ffi-lib get-ffi-obj getenv putenv current-environment-variables
    thread thread/suspend-to-kill future place))

;; Exact source vocabularies make the implicit racket/base import explicit.
;; Adding even an otherwise unknown identifier to either trusted runtime file
;; requires a deliberate update here in the same phase that approves it.
(define phase14-codec-vocabulary
  '(#%module-begin * + <= > NIL and apply argument bit bits bits-value
    boolean? byte->object-char bytes bytes->immutable-bytes
    bytes->object-string bytes? car cdr char char-type chars codec
    codec-failure codec-failure? codec-false codec-true cond cons decoded
    define else eq? error-value exn:fail? expected failure false-marker first
    first-codec-failure for/fold for/list force function
    host-list->object-list if in-bytes in-list integer integer->raw-bits
    lambda lazy-apply lazy-apply2 length let list list-type loop map memq
    module nil? not null? object-char->byte object-err object-has-type?
    object-list->host-list object-ok object-string->bytes odd? only-in ormap
    out-of-range payload provide quote quotient racket/base racket/promise
    raise-argument-error raw-bit->boolean raw-bits->byte
    raw-boolean->boolean raw-char-value raw-cons raw-false raw-is-type
    raw-list-head raw-list-is-nil raw-list-tail raw-make-char raw-make-err
    raw-make-ok raw-make-string raw-string-value raw-true reason remaining
    require result reverse reversed second seen selected string-type struct
    struct-out tail total true-marker unless value values with-handlers
    wrong-type zero?))

(define phase14-host-vocabulary
  '(#%module-begin = EMPTY-STRING NIL argument bytes->object-string bytes=?
    cadr car case codec-failure-reason codec-failure? cond
    current-output-port decoded-request define dispatch-request else
    exn:fail? failure first flush-output force function host if
    invalid-codec-request invalid-request io-failure-code lambda lazy-apply
    lazy-apply2 length make-host-bridge make-host-failure
    make-invalid-host-request module not object-err object-list->host-list
    object-ok object-string->bytes only-in operation operation-bytes
    operation-value out-of-range out-of-range-reason output payload
    perform-stdout provide racket/base racket/promise reason reason->object
    request require second stdout-failure stdout-operation
    unknown-operation-reason with-handlers write-bytes wrong-arity-reason
    wrong-type-reason))

(define expected-codec-provide
  '(provide (struct-out codec-failure)
            object-list->host-list
            host-list->object-list
            object-string->bytes
            bytes->object-string
            object-ok
            object-err))

(define expected-host-provide '(provide host))

(define (normalized path)
  (simplify-path (path->complete-path path) #f))

(define (dotenv-name? path)
  (define name (file-name-from-path path))
  (and name
       (regexp-match?
        #px"(^|\\.)env($|\\.)"
        (string-downcase (path->string name)))))

(define (safe-source-path? path)
  (and (not (dotenv-name? path))
       (not (link-exists? path))))

(define (path-within? parent child)
  (define parent-parts (explode-path (normalized parent)))
  (define child-parts (explode-path (normalized child)))
  (and (<= (length parent-parts) (length child-parts))
       (equal? parent-parts
               (take child-parts (length parent-parts)))))

(define (resolve-relative source-path module-path)
  (normalized
   (build-path (or (path-only source-path) (current-directory))
               module-path)))

(define (read-module-info path)
  (define datum
    (call-with-input-file path
      (lambda (input)
        (parameterize ([read-accept-reader #t]
                       [current-load-relative-directory (path-only path)])
          (read input)))))
  (and (list? datum)
       (= (length datum) 4)
       (eq? (car datum) 'module)
       (let ([body (list-ref datum 3)])
         (and (list? body)
              (pair? body)
              (eq? (car body) '#%module-begin)
              (module-info (list-ref datum 2)
                           (cdr body))))))

(define (violation path kind detail)
  (boundary-violation path kind (format "~s" detail)))

(define (require-form? form)
  (and (pair? form) (eq? (car form) 'require)))

(define (provide-form? form)
  (and (pair? form) (eq? (car form) 'provide)))

(define (require-spec-base spec)
  (cond
    [(or (string? spec) (symbol? spec)) spec]
    [(and (list? spec)
          (pair? spec)
          (eq? (car spec) 'only-in)
          (>= (length spec) 3))
     (cadr spec)]
    [else #f]))

(define (only-in-spec? spec)
  (and (list? spec)
       (pair? spec)
       (eq? (car spec) 'only-in)))

(define (module-require-specs info)
  (append-map cdr
              (filter require-form?
                      (module-info-forms info))))

(define (provided-identifiers info)
  (append-map
   (lambda (form)
     (append-map
      (lambda (spec)
        (cond
          [(symbol? spec) (list spec)]
          [(and (list? spec)
                (pair? spec)
                (eq? (car spec) 'rename-out))
           (filter-map
            (lambda (rename)
              (and (list? rename)
                   (= (length rename) 2)
                   (symbol? (cadr rename))
                   (cadr rename)))
            (cdr spec))]
          [else '()]))
      (cdr form)))
   (filter provide-form? (module-info-forms info))))

(define (only-in-identifiers spec)
  (filter-map
   (lambda (selection)
     (cond
       [(symbol? selection) selection]
       [(and (list? selection)
             (= (length selection) 2)
             (symbol? (cadr selection)))
        (cadr selection)]
       [else #f]))
   (cddr spec)))

(define (imported-identifiers spec source-path)
  (define base (require-spec-base spec))
  (cond
    [(only-in-spec? spec)
     (only-in-identifiers spec)]
    [(string? base)
     (define target (resolve-relative source-path base))
     (define info
       (with-handlers ([exn:fail? (lambda (failure) #f)])
         (and (source-file? target)
              (read-module-info target))))
     (if info (provided-identifiers info) '())]
    [else '()]))

(define (effect-top-level-identifiers info)
  (filter-map
   (lambda (form)
     (cond
       [(and (list? form)
             (>= (length form) 4)
             (eq? (car form) 'def)
             (symbol? (cadr form)))
        (cadr form)]
       [(and (list? form)
             (= (length form) 3)
             (eq? (car form) 'define-function-name)
             (symbol? (cadr form)))
        (cadr form)]
       [else #f]))
   (module-info-forms info)))

(define (effect-allowed-identifiers info source-path)
  (remove-duplicates
   (append
    (effect-top-level-identifiers info)
    (append-map (lambda (spec)
                  (imported-identifiers spec source-path))
                (module-require-specs info)))))

(define (source-file? path)
  (and (file-exists? path)
       (equal? (path-get-extension path) #".rkt")
       (safe-source-path? path)))

(define (effect-import-allowed? spec source-path project-root)
  (define base (require-spec-base spec))
  (and (string? base)
       (let ([target (resolve-relative source-path base)])
         (or (and (equal? base effect-macro-import)
                  (equal? target
                          (normalized
                           (build-path project-root "macros" "macros.rkt")))
                  (source-file? target))
             (and (source-file? target)
                  (or (path-within? (build-path project-root "core") target)
                      (path-within? (build-path project-root "effects")
                                    target)))))))

(define (codec-import-allowed? spec source-path project-root)
  (define base (require-spec-base spec))
  (cond
    [(eq? base 'racket/promise) (eq? spec 'racket/promise)]
    [(string? base)
     (define target (resolve-relative source-path base))
     (and (only-in-spec? spec)
          (source-file? target)
          (path-within? (build-path project-root "core") target))]
    [else #f]))

(define (host-import-allowed? spec source-path project-root)
  (define base (require-spec-base spec))
  (cond
    [(eq? base 'racket/promise) (eq? spec 'racket/promise)]
    [(string? base)
     (define target (resolve-relative source-path base))
     (define allowed
       (map (lambda (parts)
              (normalized (apply build-path project-root parts)))
            '(("core" "errors.rkt")
              ("core" "strings.rkt")
              ("effects" "protocol.rkt")
              ("runtime" "codec.rkt"))))
     (and (only-in-spec? spec)
          (source-file? target)
          (member target allowed equal?))]
    [else #f]))

(define (datum-symbols datum)
  (cond
    [(symbol? datum) (list datum)]
    [(pair? datum)
     (append (datum-symbols (car datum))
             (datum-symbols (cdr datum)))]
    [(vector? datum)
     (append-map datum-symbols (vector->list datum))]
    [else '()]))

(define (symbol-violations path symbols forbidden kind)
  (for/list ([name (in-list (remove-duplicates symbols))]
             #:when (memq name forbidden))
    (violation path kind name)))

(define (codec-pattern-violations path symbols)
  (for/list ([name (in-list (remove-duplicates symbols))]
             #:when
             (let ([text (symbol->string name)])
               (or (regexp-match? #px"^set-.+!$" text)
                   (regexp-match? #px"registry" text))))
    (violation path 'forbidden-codec-capability name)))

(define (strict-vocabulary-violations path allowed kind)
  (define info
    (with-handlers ([exn:fail? (lambda (failure) #f)])
      (read-module-info path)))
  (if info
      (for/list ([name (in-list
                        (remove-duplicates
                         (datum-symbols (module-info-forms info))))]
                 #:unless (memq name allowed))
        (violation path kind name))
      '()))

(define (pure-expression-violations expression bound allowed path)
  (cond
    [(symbol? expression)
     (if (or (memq expression bound)
             (memq expression allowed))
         '()
         (list (violation path 'unapproved-effect-identifier expression)))]
    [(not (pair? expression))
     (list (violation path 'forbidden-effect-datum expression))]
    [(eq? (car expression) 'lambda)
     (if (and (= (length expression) 3)
              (list? (cadr expression))
              (= (length (cadr expression)) 1)
              (symbol? (caadr expression)))
         (pure-expression-violations
          (caddr expression)
          (cons (caadr expression) bound)
          allowed
          path)
         (list (violation path 'non-unary-effect-lambda expression)))]
    [(eq? (car expression) 'lambda-let)
     (if (and (= (length expression) 5)
              (symbol? (cadr expression))
              (eq? (caddr expression) '=))
         (append
          (pure-expression-violations (cadddr expression)
                                      bound
                                      allowed
                                      path)
          (pure-expression-violations
           (list-ref expression 4)
           (cons (cadr expression) bound)
           allowed
           path))
         (list (violation path 'invalid-effect-macro-form expression)))]
    [(= (length expression) 2)
     (append (pure-expression-violations (car expression)
                                         bound
                                         allowed
                                         path)
             (pure-expression-violations (cadr expression)
                                         bound
                                         allowed
                                         path))]
    [else
     (list (violation path 'non-unary-effect-application expression))]))

(define (effect-definition-violations form allowed path)
  (define equals
    (indexes-of form '=))
  (cond
    [(or (not (eq? (car form) 'def))
         (not (= (length equals) 1))
         (< (car equals) 2)
         (not (= (car equals) (- (length form) 2)))
         (not (symbol? (cadr form)))
         (not (andmap symbol? (take (cddr form) (- (car equals) 2)))))
     (list (violation path 'invalid-effect-definition form))]
    [(eq? (cadr form) 'host)
     (list (violation path 'forbidden-host-definition 'host))]
    [else
     (define arguments
       (take (cddr form) (- (car equals) 2)))
     (pure-expression-violations (last form)
                                 arguments
                                 allowed
                                 path)]))

(define (effect-provide-violations form definitions path)
  (append-map
   (lambda (spec)
     (cond
       [(eq? spec 'host)
        (list (violation path 'forbidden-host-export spec))]
       [(and (symbol? spec) (memq spec definitions))
        '()]
       [else
        (list (violation path 'unapproved-effect-export spec))]))
   (cdr form)))

(define (effect-form-violations form definitions allowed path project-root)
  (cond
    [(require-form? form)
     (for/list ([spec (in-list (cdr form))]
                #:unless (effect-import-allowed? spec path project-root))
       (violation path 'disallowed-effect-import spec))]
    [(provide-form? form)
     (effect-provide-violations form definitions path)]
    [(and (pair? form) (eq? (car form) 'def))
     (effect-definition-violations form allowed path)]
    [(and (list? form)
          (= (length form) 3)
          (eq? (car form) 'define-function-name)
          (symbol? (cadr form))
          (symbol? (caddr form)))
     (if (eq? (cadr form) 'host)
         (list (violation path 'forbidden-host-definition form))
         '())]
    [else
     (list (violation path 'disallowed-effect-module-form form))]))

(define (effect-violations path info project-root)
  (define definitions
    (effect-top-level-identifiers info))
  (define allowed
    (effect-allowed-identifiers info path))
  (append
   (if (equal? (module-info-language info) effect-language)
       '()
       (list (violation path 'unexpected-effect-language
                        (module-info-language info))))
   (append-map (lambda (form)
                 (effect-form-violations form
                                         definitions
                                         allowed
                                         path
                                         project-root))
               (module-info-forms info))))

(define (strict-import-violations path info project-root allowed? kind)
  (for/list ([spec (in-list (module-require-specs info))]
             #:unless (allowed? spec path project-root))
    (violation path kind spec)))

(define (strict-language-violations path info class)
  (if (eq? (module-info-language info) 'racket/base)
      '()
      (list (violation path
                       (if (eq? class 'codec)
                           'unexpected-codec-language
                           'unexpected-host-language)
                       (module-info-language info)))))

(define (exact-provide-violations path info expected kind)
  (define provides
    (filter provide-form? (module-info-forms info)))
  (if (equal? provides (list expected))
      '()
      (list (violation path kind provides))))

(define (codec-violations path info project-root)
  (define symbols
    (datum-symbols (module-info-forms info)))
  (append
   (strict-language-violations path info 'codec)
   (strict-import-violations path info project-root
                             codec-import-allowed?
                             'disallowed-codec-import)
   (exact-provide-violations path info expected-codec-provide
                             'invalid-codec-export)
   (symbol-violations path
                      symbols
                      forbidden-codec-capabilities
                      'forbidden-codec-capability)
   (codec-pattern-violations path symbols)))

(define (top-level-binding-name form)
  (and (list? form)
       (>= (length form) 3)
       (case (car form)
         [(define)
          (let ([binding (cadr form)])
            (if (pair? binding) (car binding) binding))]
         [(def) (cadr form)]
         [(define-values)
          (and (list? (cadr form))
               (= (length (cadr form)) 1)
               (caadr form))]
         [else #f])))

(define (host-violations path info project-root)
  (define host-definitions
    (filter (lambda (form)
              (eq? (top-level-binding-name form) 'host))
            (module-info-forms info)))
  (define imported-targets
    (filter-map
     (lambda (spec)
       (define base (require-spec-base spec))
       (and (string? base)
            (resolve-relative path base)))
     (module-require-specs info)))
  (define required-targets
    (list (normalized (build-path project-root "effects" "protocol.rkt"))
          (normalized (build-path project-root "runtime" "codec.rkt"))))
  (append
   (strict-language-violations path info 'host)
   (strict-import-violations path info project-root
                             host-import-allowed?
                             'disallowed-host-import)
   (exact-provide-violations path info expected-host-provide
                             'invalid-host-export)
   (if (= (length host-definitions) 1)
       '()
       (list (violation path 'invalid-host-definition-count
                        (length host-definitions))))
   (for/list ([required (in-list required-targets)]
              #:unless (= (count (lambda (target)
                                   (equal? target required))
                                 imported-targets)
                          1))
     (violation path 'missing-required-host-import required))
   (symbol-violations path
                      (datum-symbols (module-info-forms info))
                      forbidden-host-capabilities
                      'forbidden-host-capability)))

(define (file-boundary-violations path class
                                  [project-root default-project-root])
  (define source (normalized path))
  (cond
    [(not (safe-source-path? source))
     (list (violation source 'disallowed-boundary-path source))]
    [(not (file-exists? source))
     (list (violation source 'missing-boundary-file source))]
    [else
     (define info
       (with-handlers ([exn:fail? (lambda (failure) failure)])
         (read-module-info source)))
     (cond
       [(exn? info)
        (list (violation source 'boundary-read-failure
                         (exn-message info)))]
       [(not info)
        (list (violation source 'invalid-boundary-module source))]
       [(eq? class 'effect)
        (effect-violations source info (normalized project-root))]
       [(eq? class 'codec)
        (codec-violations source info (normalized project-root))]
       [(eq? class 'host)
        (host-violations source info (normalized project-root))]
       [else
        (list (violation source 'unknown-boundary-class class))])]))

(define (racket-files-under directory)
  (cond
    [(dotenv-name? directory) '()]
    [(link-exists? directory) (list directory)]
    [(directory-exists? directory)
     (append-map racket-files-under
                 (directory-list directory #:build? #t))]
    [(and (file-exists? directory)
          (equal? (path-get-extension directory) #".rkt"))
     (list (normalized directory))]
    [else '()]))

(define (unauthorized-codec-imports files codec host)
  (append-map
   (lambda (source)
     (define info
       (with-handlers ([exn:fail? (lambda (failure) #f)])
         (read-module-info source)))
     (if info
         (for/list ([spec (in-list (module-require-specs info))]
                    #:when
                    (let ([base (require-spec-base spec)])
                      (and (string? base)
                           (equal? (resolve-relative source base) codec)
                           (not (equal? source host)))))
           (violation source 'unauthorized-codec-import spec))
         '()))
   files))

(define (unauthorized-host-surfaces files host)
  (append-map
   (lambda (source)
     (define info
       (with-handlers ([exn:fail? (lambda (failure) #f)])
         (read-module-info source)))
     (if (or (not info) (equal? source host))
         '()
         (append
          (for/list ([form (in-list (module-info-forms info))]
                     #:when (eq? (top-level-binding-name form) 'host))
            (violation source 'unauthorized-host-definition form))
          (for/list ([form (in-list (module-info-forms info))]
                     #:when
                     (and (provide-form? form)
                          (member 'host (datum-symbols (cdr form)))))
            (violation source 'unauthorized-host-export form)))))
   files))

(define (project-boundary-violations
         [project-root default-project-root])
  (define root (normalized project-root))
  (define effects-directory (build-path root "effects"))
  (define runtime-directory (build-path root "runtime"))
  (define codec (normalized (build-path runtime-directory "codec.rkt")))
  (define host (normalized (build-path runtime-directory "host.rkt")))
  (define effect-files (racket-files-under effects-directory))
  (define runtime-files (racket-files-under runtime-directory))
  (define production-files
    (append (racket-files-under (build-path root "core"))
            effect-files
            runtime-files))
  (append
   (append-map (lambda (path)
                 (file-boundary-violations path 'effect root))
               effect-files)
   (file-boundary-violations codec 'codec root)
   (file-boundary-violations host 'host root)
   (strict-vocabulary-violations codec
                                 phase14-codec-vocabulary
                                 'unapproved-codec-identifier)
   (strict-vocabulary-violations host
                                 phase14-host-vocabulary
                                 'unapproved-host-identifier)
   (for/list ([path (in-list runtime-files)]
              #:unless (member path (list codec host) equal?))
     (violation path 'unclassified-runtime-module path))
   (unauthorized-codec-imports production-files codec host)
   (unauthorized-host-surfaces production-files host)))

(module+ main
  (define findings
    (project-boundary-violations default-project-root))
  (cond
    [(null? findings)
     (printf "Boundary check passed: pure effects, isolated codec, sole host.\n")]
    [else
     (for ([finding (in-list findings)])
       (eprintf "~a: ~a: ~a\n"
                (boundary-violation-path finding)
                (boundary-violation-kind finding)
                (boundary-violation-detail finding)))
     (exit 1)]))
