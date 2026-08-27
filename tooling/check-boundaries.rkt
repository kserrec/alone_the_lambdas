#lang racket/base

;; Structural gate for the deliberately nonuniform Phase 15 production tree.
;; `check-purity.rkt` remains the expanded zero-exception proof for core/. This
;; checker adds the approved classes without weakening that proof:
;;
;;   effects/             pure source forms and closed project imports
;;   macros/              the two exact mechanical expansion modules
;;   runtime/codec.rkt    deterministic conversion, no effect capabilities
;;   runtime/host.rkt     sole host export and the Phase 15 effect allowlist
;;   lang/                empty until its Phase 19 classification is approved

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
    file->string
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
(define phase15-codec-vocabulary
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

(define phase15-host-vocabulary
  '(#%module-begin = EMPTY-STRING NIL and argument bytes->object-string
    bytes->string/utf-8 bytes=? cadr caddr call-with-output-file car case cdr
    code codec-failure-reason codec-failure? cond current-output-port
    decode-path decoded-request define dispatch-one-string dispatch-request
    dispatch-two-strings domain else eq? errno errno-in? exn:fail:contract?
    exn:fail:filesystem:errno-errno exn:fail:filesystem:errno? exn:fail?
    exn:fail:out-of-memory? failure file->bytes file-failure
    filesystem-failure-code first
    flush-output force function host host-failure if invalid-codec-request
    invalid-path-code invalid-request invalid-text-code io-failure-code lambda
    lazy-apply lazy-apply2 length let make-host-bridge make-host-failure
    make-invalid-host-request memv module not not-found-code null? numbers
    object-err object-list->host-list object-ok object-string->bytes only-in
    operation operation-bytes operation-value or out-of-range
    out-of-range-reason output pair? path path-payload payload performer
    perform-read-file perform-stdout perform-write-file permission-denied-code
    posix provide quote racket/base racket/file racket/promise
    read-file-operation reason reason->object request require
    resource-exhausted-code second stdout-operation string? timed-out-code
    truncate unknown-operation-reason windows with-handlers write-bytes
    write-file-operation wrong-arity-reason wrong-type-reason))

(define macro-vocabulary
  '(... = NIL _ and andmap argument arguments binding bit-expressions body
    byte bytes->list car cdr char=? character-expressions context
    curried-lambdas datum->syntax def define define-for-syntax
    define-function-name define-syntax digit elements for-syntax
    function-name-expression identifier? if lambda lambda-let map name
    name-byte-expression name-list-expression null? number->string provide
    quasisyntax quote racket/base raw-cons raw-false raw-name-char
    raw-name-string raw-true rendered-name require string->bytes/utf-8
    string->list stx symbol->string syntax syntax->list syntax-case syntax-e
    unsyntax use-site-identifier value))

(define expected-macro-shell-language 'racket/base)

(define expected-macro-shell-forms
  '((require lazy/lazy)
    (provide (all-from-out lazy/lazy)
             #%module-begin
             #%app
             #%datum
             #%top)))

(define expected-macro-language 'lazy)

(define expected-macro-requires
  '((require (for-syntax racket/base))))

(define expected-macro-provide
  '(provide def
            lambda-let
            define-function-name))

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

(define (dotenv-path? path)
  (for/or ([part (in-list (explode-path (normalized path)))])
    (and (path? part)
         (dotenv-name? part))))

(define (path-within? parent child)
  (define parent-parts (explode-path (normalized parent)))
  (define child-parts (explode-path (normalized child)))
  (and (<= (length parent-parts) (length child-parts))
       (equal? parent-parts
               (take child-parts (length parent-parts)))))

(define (safe-absolute-components? path)
  (let loop ([parts (explode-path (normalized path))]
             [current #f])
    (cond
      [(null? parts) #t]
      [(not (path? (car parts))) #f]
      [else
       (define next
         (if current
             (build-path current (car parts))
             (car parts)))
       (and (not (dotenv-name? next))
            (not (link-exists? next))
            (loop (cdr parts) next))])))

(define (safe-components-under? project-root path)
  (define root (normalized project-root))
  (define source (normalized path))
  (and
   (safe-absolute-components? root)
   (path-within? root source)
   (let loop ([current root]
              [parts
               (explode-path (find-relative-path root source))])
     (cond
       [(null? parts) #t]
       [(not (path? (car parts))) #f]
       [else
        (define next (build-path current (car parts)))
        (and (not (dotenv-name? next))
             (not (link-exists? next))
             (loop next (cdr parts)))]))))

(define (safe-source-path? path [project-root #f])
  (and (not (dotenv-path? path))
       (if project-root
           (safe-components-under? project-root path)
           (safe-absolute-components? path))))

(define (resolve-relative source-path module-path)
  (normalized
   (build-path (or (path-only source-path) (current-directory))
               module-path)))

(define (read-module-info/unchecked path)
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

(define (combined-require-bases specs)
  (define groups
    (map require-spec-bases specs))
  (and (andmap list? groups)
       (append* groups)))

(define (require-spec-bases spec)
  (cond
    [(or (string? spec) (symbol? spec)) (list spec)]
    [(and (list? spec)
          (pair? spec)
          (memq (car spec) '(only-in except-in rename-in))
          (>= (length spec) 2))
     (require-spec-bases (cadr spec))]
    [(and (list? spec)
          (pair? spec)
          (eq? (car spec) 'prefix-in)
          (>= (length spec) 3))
     (require-spec-bases (caddr spec))]
    [(and (list? spec)
          (pair? spec)
          (memq (car spec) '(combine-in for-syntax for-template for-label)))
     (combined-require-bases (cdr spec))]
    [(and (list? spec)
          (pair? spec)
          (memq (car spec) '(for-meta only-meta-in for-space))
          (>= (length spec) 3))
     (combined-require-bases (cddr spec))]
    [else #f]))

(define (require-spec-base spec)
  (define bases
    (require-spec-bases spec))
  (and bases
       (= (length bases) 1)
       (car bases)))

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

(define (imported-identifiers spec source-path project-root)
  (define base (require-spec-base spec))
  (cond
    [(only-in-spec? spec)
     (only-in-identifiers spec)]
    [(string? base)
     (define target (resolve-relative source-path base))
     (define info (read-module-info target project-root))
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

(define (effect-allowed-identifiers info source-path project-root)
  (remove-duplicates
   (append
    (effect-top-level-identifiers info)
    (append-map (lambda (spec)
                  (if (effect-import-allowed? spec
                                              source-path
                                              project-root)
                      (imported-identifiers spec
                                            source-path
                                            project-root)
                      '()))
                (module-require-specs info)))))

(define (source-file? path project-root)
  (and (safe-source-path? path project-root)
       (file-exists? path)
       (equal? (path-get-extension path) #".rkt")))

;; All opportunistic project-wide reads go through this guard. The one caller
;; that has already rejected unsafe/missing paths uses the unchecked reader so
;; it can preserve a concrete read-failure diagnostic for a regular source.
(define (read-module-info path project-root)
  (with-handlers ([exn:fail? (lambda (failure) #f)])
    (and (source-file? path project-root)
         (read-module-info/unchecked path))))

(define (effect-import-allowed? spec source-path project-root)
  (define base (require-spec-base spec))
  (and (string? base)
       (let ([target (resolve-relative source-path base)])
         (or (and (equal? base effect-macro-import)
                  (equal? target
                          (normalized
                           (build-path project-root "macros" "macros.rkt")))
                  (source-file? target project-root))
             (and (or (path-within? (build-path project-root "core") target)
                      (path-within? (build-path project-root "effects")
                                    target))
                  (source-file? target project-root))))))

(define (codec-import-allowed? spec source-path project-root)
  (define base (require-spec-base spec))
  (cond
    [(eq? base 'racket/promise) (eq? spec 'racket/promise)]
    [(string? base)
     (define target (resolve-relative source-path base))
     (and (only-in-spec? spec)
          (path-within? (build-path project-root "core") target)
          (source-file? target project-root))]
    [else #f]))

(define (host-import-allowed? spec source-path project-root)
  (define base (require-spec-base spec))
  (cond
    [(eq? base 'racket/promise) (eq? spec 'racket/promise)]
    [(eq? base 'racket/file)
     (and (only-in-spec? spec)
          (equal? (only-in-identifiers spec) '(file->bytes)))]
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
          (member target allowed equal?)
          (source-file? target project-root))]
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

(define (capability-pattern-violations path symbols kind)
  (for/list ([name (in-list (remove-duplicates symbols))]
             #:when
             (let ([text (symbol->string name)])
               (or (regexp-match? #px"^set-.+!$" text)
                   (regexp-match? #px"registry" text))))
    (violation path kind name)))

(define (strict-vocabulary-violations path project-root allowed kind)
  (define info (read-module-info path project-root))
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
    (effect-allowed-identifiers info path project-root))
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

(define (exact-language-violations path info expected kind)
  (if (eq? (module-info-language info) expected)
      '()
      (list (violation path kind (module-info-language info)))))

(define (exact-require-violations path info expected kind)
  (define requires
    (filter require-form? (module-info-forms info)))
  (if (equal? requires expected)
      '()
      (list (violation path kind requires))))

(define (exact-provide-violations path info expected kind)
  (define provides
    (filter provide-form? (module-info-forms info)))
  (if (equal? provides (list expected))
      '()
      (list (violation path kind provides))))

(define (macro-shell-violations path info)
  (append
   (exact-language-violations path
                              info
                              expected-macro-shell-language
                              'unexpected-macro-shell-language)
   (if (equal? (module-info-forms info) expected-macro-shell-forms)
       '()
       (list (violation path
                        'invalid-macro-shell-forms
                        (module-info-forms info))))))

(define (macro-violations path info)
  (define symbols
    (datum-symbols (module-info-forms info)))
  (append
   (exact-language-violations path
                              info
                              expected-macro-language
                              'unexpected-macro-language)
   (exact-require-violations path
                             info
                             expected-macro-requires
                             'invalid-macro-imports)
   (exact-provide-violations path
                             info
                             expected-macro-provide
                             'invalid-macro-export)
   (symbol-violations path
                      symbols
                      forbidden-codec-capabilities
                      'forbidden-macro-capability)
   (capability-pattern-violations path
                                  symbols
                                  'forbidden-macro-capability)))

(define (codec-violations path info project-root)
  (define symbols
    (datum-symbols (module-info-forms info)))
  (append
   (exact-language-violations path
                              info
                              'racket/base
                              'unexpected-codec-language)
   (strict-import-violations path info project-root
                             codec-import-allowed?
                             'disallowed-codec-import)
   (exact-provide-violations path info expected-codec-provide
                             'invalid-codec-export)
   (symbol-violations path
                      symbols
                      forbidden-codec-capabilities
                      'forbidden-codec-capability)
   (capability-pattern-violations path
                                  symbols
                                  'forbidden-codec-capability)))

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
   (exact-language-violations path
                              info
                              'racket/base
                              'unexpected-host-language)
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
  (define root (normalized project-root))
  (cond
    [(not (safe-source-path? source root))
     (list (violation source 'disallowed-boundary-path source))]
    [(not (file-exists? source))
     (list (violation source 'missing-boundary-file source))]
    [else
     (define info
       (with-handlers ([exn:fail? (lambda (failure) failure)])
         (read-module-info/unchecked source)))
     (cond
       [(exn? info)
        (list (violation source 'boundary-read-failure
                         (exn-message info)))]
       [(not info)
        (list (violation source 'invalid-boundary-module source))]
       [(eq? class 'effect)
        (effect-violations source info root)]
       [(eq? class 'macro-shell)
        (macro-shell-violations source info)]
       [(eq? class 'macro)
        (macro-violations source info)]
       [(eq? class 'codec)
        (codec-violations source info root)]
       [(eq? class 'host)
        (host-violations source info root)]
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

(define (unsafe-production-path-violations files project-root)
  (for/list ([path (in-list files)]
             #:unless (source-file? path project-root))
    (violation path 'disallowed-boundary-path path)))

(define (unauthorized-codec-imports files project-root codec host)
  (append-map
   (lambda (source)
     (define info (read-module-info source project-root))
     (if info
         (for*/list ([spec (in-list (module-require-specs info))]
                     [base (in-list (or (require-spec-bases spec) '()))]
                     #:when
                     (and (string? base)
                          (equal? (resolve-relative source base) codec)
                          (not (equal? source host))))
           (violation source 'unauthorized-codec-import spec))
         '()))
   files))

(define (unauthorized-host-imports files project-root host)
  (append-map
   (lambda (source)
     (define info (read-module-info source project-root))
     (if (or (not info) (equal? source host))
         '()
         (for*/list ([spec (in-list (module-require-specs info))]
                     [base (in-list (or (require-spec-bases spec) '()))]
                     #:when
                     (and (string? base)
                          (equal? (resolve-relative source base) host)))
           (violation source 'unauthorized-host-import spec))))
   files))

(define (unclassified-require-specs files project-root)
  (append-map
   (lambda (source)
     (define info (read-module-info source project-root))
     (if info
         (for/list ([spec (in-list (module-require-specs info))]
                    #:unless (require-spec-bases spec))
           (violation source 'unclassified-production-import spec))
         '()))
   files))

(define (unauthorized-host-surfaces files project-root host)
  (append-map
   (lambda (source)
     (define info (read-module-info source project-root))
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
  (cond
    [(not (safe-absolute-components? root))
     (list (violation root 'disallowed-boundary-root 'unsafe-root))]
    [(not (directory-exists? root))
     (list (violation root 'missing-boundary-root 'missing-root))]
    [else
     ;; No directory discovery or source read occurs until the complete
     ;; authorization anchor above has passed component-by-component checks.
     (define effects-directory (build-path root "effects"))
     (define macros-directory (build-path root "macros"))
     (define runtime-directory (build-path root "runtime"))
     (define language-directory (build-path root "lang"))
     (define macro-shell
       (normalized (build-path macros-directory "lazy-with-macros.rkt")))
     (define macro-definitions
       (normalized (build-path macros-directory "macros.rkt")))
     (define codec (normalized (build-path runtime-directory "codec.rkt")))
     (define host (normalized (build-path runtime-directory "host.rkt")))
     (define effect-files (racket-files-under effects-directory))
     (define macro-files (racket-files-under macros-directory))
     (define runtime-files (racket-files-under runtime-directory))
     (define language-files (racket-files-under language-directory))
     (define production-files
       (append-map
        racket-files-under
        (list (build-path root "core")
              effects-directory
              macros-directory
              runtime-directory
              language-directory)))
     (append
      (unsafe-production-path-violations production-files root)
      (append-map (lambda (path)
                    (file-boundary-violations path 'effect root))
                  effect-files)
      (file-boundary-violations macro-shell 'macro-shell root)
      (file-boundary-violations macro-definitions 'macro root)
      (file-boundary-violations codec 'codec root)
      (file-boundary-violations host 'host root)
      (strict-vocabulary-violations codec
                                    root
                                    phase15-codec-vocabulary
                                    'unapproved-codec-identifier)
      (strict-vocabulary-violations host
                                    root
                                    phase15-host-vocabulary
                                    'unapproved-host-identifier)
      (strict-vocabulary-violations macro-definitions
                                    root
                                    macro-vocabulary
                                    'unapproved-macro-identifier)
      (for/list ([path (in-list macro-files)]
                 #:unless (member path
                                  (list macro-shell macro-definitions)
                                  equal?))
        (violation path 'unclassified-macro-module path))
      (for/list ([path (in-list runtime-files)]
                 #:unless (member path (list codec host) equal?))
        (violation path 'unclassified-runtime-module path))
      (for/list ([path (in-list language-files)])
        (violation path 'unclassified-language-module path))
      (unclassified-require-specs production-files root)
      (unauthorized-codec-imports production-files root codec host)
      (unauthorized-host-imports production-files root host)
      (unauthorized-host-surfaces production-files root host))]))

(module+ main
  (define findings
    (project-boundary-violations default-project-root))
  (cond
    [(null? findings)
     (printf
      "Boundary check passed: pure effects, mechanical macros, isolated codec, sole host.\n")]
    [else
     (for ([finding (in-list findings)])
       (eprintf "~a: ~a: ~a\n"
                (boundary-violation-path finding)
                (boundary-violation-kind finding)
                (boundary-violation-detail finding)))
     (exit 1)]))
