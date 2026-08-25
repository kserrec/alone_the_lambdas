#lang racket/base

(require racket/list
         racket/path
         racket/runtime-path)

(provide (struct-out violation)
         datum-violations
         file-violations
         production-files-under)

(struct violation (kind detail)
  #:transparent)

(define expected-production-language
  "../macros/lazy-with-macros.rkt")

(define expected-macro-import
  "../macros/macros.rkt")

(define-runtime-path trusted-production-language-file
  "../macros/lazy-with-macros.rkt")

(define-runtime-path trusted-macro-import-file
  "../macros/macros.rkt")

(define trusted-production-language-path
  (normalize-path trusted-production-language-file))

(define trusted-macro-import-path
  (normalize-path trusted-macro-import-file))

(define forbidden-heads
  '(if
    cond
    case
    when
    unless
    and
    or
    not
    let
    let*
    letrec
    let-values
    let*-values
    for
    for*
    for/list
    for*/list
    do
    match
    match-lambda
    case-lambda
    begin
    begin0
    apply
    values
    call/cc
    dynamic-wind
    delay
    force
    host
    eval
    dynamic-require
    system
    process
    open-input-file
    open-output-file
    call-with-input-file
    call-with-output-file
    display
    printf
    +
    -
    *
    /
    =
    <
    >
    <=
    >=
    eq?
    eqv?
    equal?
    pair?
    list?
    null?
    number?
    boolean?
    string?
    procedure?
    list
    cons
    car
    cdr
    member
    memq
    assoc
    map
    filter
    foldl
    foldr
    append
    reverse
    length
    vector
    make-vector
    vector-ref
    hash
    make-hash
    hash-ref
    set
    box
    set!
    set-box!
    string
    make-string
    string-length
    string-ref
    string=?
    char=?
    string-append
    substring
    regexp
    raise
    error
    with-handlers
    struct
    quote
    quasiquote
    λ))

(define reserved-production-bindings
  '(lambda
    define
    def
    lambda-let
    define-function-name
    require
    provide))

(define (host-datum? datum)
  (or (number? datum)
      (boolean? datum)
      (string? datum)
      (char? datum)
      (bytes? datum)
      (vector? datum)
      (hash? datum)
      (box? datum)
      (regexp? datum)
      (byte-regexp? datum)
      (keyword? datum)))

(define (unary-formals? formals)
  (and (list? formals)
       (= (length formals) 1)
       (symbol? (car formals))))

(define (arity-specific-checker-name? datum)
  (and (symbol? datum)
       (regexp-match?
        #px"^(type-check|make-typed-function)-?[0-9]+$"
        (symbol->string datum))))

(define (reserved-production-binding-violations identifier)
  (if (memq identifier
            reserved-production-bindings)
      (list
       (violation 'reserved-production-binding
                  (symbol->string identifier)))
      '()))

(define (arity-specific-identifier-violations identifier)
  (if (arity-specific-checker-name? identifier)
      (list
       (violation 'arity-specific-checker
                  (symbol->string identifier)))
      '()))

(define (production-binding-violations identifier)
  (append
   (reserved-production-binding-violations identifier)
   (arity-specific-identifier-violations identifier)))

(define (parse-def form)
  (and (list? form)
       (>= (length form) 4)
       (eq? (car form) 'def)
       (symbol? (cadr form))
       (let loop ([remaining (cddr form)]
                  [arguments '()])
         (cond
           [(null? remaining)
            #f]
           [(eq? (car remaining) '=)
            (and (= (length remaining) 2)
                 (list (reverse arguments)
                       (cadr remaining)))]
           [(symbol? (car remaining))
            (loop (cdr remaining)
                  (cons (car remaining)
                        arguments))]
           [else
            #f]))))

(define (valid-lambda-let? form)
  (and (list? form)
       (= (length form) 5)
       (eq? (car form) 'lambda-let)
       (symbol? (cadr form))
       (eq? (caddr form) '=)))

(define (valid-function-name-definition? form)
  (and (list? form)
       (= (length form) 3)
       (eq? (car form) 'define-function-name)
       (symbol? (cadr form))
       (symbol? (caddr form))))

(define (plain-project-import? spec)
  (and (string? spec)
       (not (dotenv-name? (string->path spec)))
       (or (equal? spec expected-macro-import)
           (regexp-match? #px"^[^/\\\\]+\\.rkt$"
                          spec))))

(define (identifier-selection? selection)
  (or (symbol? selection)
      (and (list? selection)
           (= (length selection) 2)
           (andmap symbol? selection))))

(define (import-module-path spec)
  (cond
    [(plain-project-import? spec)
     spec]
    [(and (list? spec)
          (pair? spec))
     (case (car spec)
       [(only-in)
        (and (>= (length spec) 3)
             (andmap identifier-selection?
                     (cddr spec))
             (import-module-path (cadr spec)))]
       [(except-in)
        (and (>= (length spec) 3)
             (andmap symbol?
                     (cddr spec))
             (import-module-path (cadr spec)))]
       [(rename-in)
        (and (>= (length spec) 3)
             (andmap
              (lambda (renaming)
                (and (list? renaming)
                     (= (length renaming) 2)
                     (andmap symbol? renaming)))
              (cddr spec))
             (import-module-path (cadr spec)))]
       [(prefix-in)
        (and (= (length spec) 3)
             (symbol? (cadr spec))
             (import-module-path (caddr spec)))]
       [else
        #f])]
    [else
     #f]))

(define (allowed-require-spec? spec [source-path #f])
  (define module-path
    (import-module-path spec))
  (and module-path
       (or (not (equal? module-path
                        expected-macro-import))
           (and (string? spec)
                (or (not source-path)
                    (trusted-relative-path?
                     source-path
                     spec
                     trusted-macro-import-path))))))

(define (expression-violations expression
                               [bound '()]
                               [strict-identifiers? #f])
  (cond
    [(symbol? expression)
     (cond
       [(memq expression bound)
        '()]
       [(arity-specific-checker-name? expression)
        (list
         (violation 'arity-specific-checker
                    (symbol->string expression)))]
       [(memq expression forbidden-heads)
        (list
         (violation 'forbidden-host-identifier
                    (symbol->string expression)))]
       [strict-identifiers?
        (list
         (violation 'unapproved-production-identifier
                    (symbol->string expression)))]
       [else
        '()])]
    [(null? expression)
     (list
      (violation 'forbidden-host-datum
                 "()"))]
    [(host-datum? expression)
     (list
      (violation 'forbidden-host-datum
                 (format "~s" expression)))]
    [(pair? expression)
     (if (list? expression)
         (let ([head (car expression)])
           (cond
             [(and (eq? head 'lambda)
                   (not (memq head bound)))
              (if (and (= (length expression) 3)
                       (unary-formals? (cadr expression)))
                  (expression-violations
                   (caddr expression)
                   (cons (caadr expression)
                         bound)
                   strict-identifiers?)
                  (list
                   (violation 'non-unary-lambda
                              (format "~s" expression))))]
             [(and (eq? head 'lambda-let)
                   (not (memq head bound)))
              (if (valid-lambda-let? expression)
                  (append
                   (expression-violations
                    (cadddr expression)
                    bound
                    strict-identifiers?)
                   (expression-violations
                    (car (cddddr expression))
                    (cons (cadr expression)
                          bound)
                    strict-identifiers?))
                  (list
                   (violation 'invalid-lambda-let
                              (format "~s" expression))))]
             [(and (eq? head 'define)
                   (not (memq head bound)))
              (append
               (list
                (violation 'host-function-definition
                           (format "~s" expression)))
               (append-map
                (lambda (part)
                  (expression-violations
                   part
                   bound
                   strict-identifiers?))
                (cddr expression)))]
             [(and (memq head forbidden-heads)
                   (not (memq head bound)))
              (append
               (list
                (violation 'forbidden-host-form
                           (symbol->string head)))
               (append-map
                (lambda (part)
                  (expression-violations
                   part
                   bound
                   strict-identifiers?))
                (cdr expression)))]
             [(= (length expression) 2)
              (append
               (expression-violations
                (car expression)
                bound
                strict-identifiers?)
               (expression-violations
                (cadr expression)
                bound
                strict-identifiers?))]
             [else
              (list
               (violation 'non-unary-application
                          (format "~s" expression))) ]))
         (list
          (violation 'non-unary-application
                     (format "~s" expression))))]
    [else
     (list
      (violation 'forbidden-host-datum
                 (format "~s" expression)))]))

(define (require-violations form [source-path #f])
  (append-map
   (lambda (spec)
     (if (allowed-require-spec? spec source-path)
         '()
         (list
          (violation 'disallowed-production-import
                     (format "~s" spec)))))
   (cdr form)))

(define (provide-violations form module-bindings)
  (append-map
   (lambda (spec)
     (cond
       [(symbol? spec)
        (if (memq spec module-bindings)
            '()
            (list
             (violation 'unapproved-production-export
                        (symbol->string spec))))]
       [(and (list? spec)
             (pair? spec)
             (eq? (car spec) 'rename-out))
        (append-map
         (lambda (renaming)
           (if (and (list? renaming)
                    (= (length renaming) 2)
                    (symbol? (car renaming))
                    (symbol? (cadr renaming))
                    (memq (car renaming)
                          module-bindings))
               (arity-specific-identifier-violations
                (cadr renaming))
               (list
                (violation 'unapproved-production-export
                           (format "~s" renaming)))))
         (cdr spec))]
       [else
        (list
         (violation 'disallowed-production-export
                    (format "~s" spec)))]))
   (cdr form)))

(define (top-level-violations form
                              [module-bindings '()]
                              [strict-identifiers? #f]
                              [source-path #f])
  (cond
    [(and (pair? form)
          (eq? (car form) 'require))
     (require-violations form source-path)]
    [(and (pair? form)
          (eq? (car form) 'provide))
     (if strict-identifiers?
         (provide-violations form
                             module-bindings)
         '())]
    [(and (pair? form)
          (eq? (car form) 'def))
     (define parsed (parse-def form))
     (if parsed
         (append
          (production-binding-violations
           (cadr form))
          (expression-violations
           (cadr parsed)
           (append (car parsed)
                   module-bindings)
           strict-identifiers?))
         (list
          (violation 'invalid-def
                     (format "~s" form))))]
    [(and (pair? form)
          (eq? (car form) 'define-function-name))
     (if (valid-function-name-definition? form)
         (production-binding-violations
          (cadr form))
         (list
          (violation 'invalid-function-name-definition
                     (format "~s" form))))]
    [else
     (expression-violations form
                            module-bindings
                            strict-identifiers?)]))

(define (module-body-forms datum)
  (and (list? datum)
       (= (length datum) 4)
       (eq? (car datum) 'module)
       (let ([body (cadddr datum)])
         (and (list? body)
              (pair? body)
              (eq? (car body) '#%module-begin)
              (cdr body)))))

(define (module-violations datum
                           [source-path #f]
                           [seen-paths '()])
  (define forms
    (module-body-forms datum))
  (define imported-bindings
    (if (and forms source-path)
        (module-import-identifiers source-path
                                   forms)
        '()))
  (define module-bindings
    (if forms
        (append
         (module-defined-identifiers forms)
         imported-bindings)
        '()))
  (append
   (if (and (list? datum)
            (= (length datum) 4)
            (equal? (caddr datum)
                    expected-production-language)
            (or (not source-path)
                (trusted-relative-path?
                 source-path
                 (caddr datum)
                 trusted-production-language-path)))
       '()
       (list
        (violation 'unexpected-production-language
                   (if (and (list? datum)
                            (>= (length datum) 3))
                       (format "~s" (caddr datum))
                       (format "~s" datum)))))
   (if (and forms source-path)
       (missing-import-violations source-path
                                  forms)
       '())
   (if (and forms source-path)
       (import-path-violations source-path
                               forms)
       '())
   (if (and forms source-path)
       (import-purity-violations source-path
                                 forms
                                 seen-paths)
       '())
   (append-map production-binding-violations
               imported-bindings)
   (cond
     [forms
      (append-map
       (lambda (form)
         (top-level-violations form
                               module-bindings
                               (and source-path #t)
                               source-path))
       forms)]
     [else
      (list
       (violation 'invalid-production-module
                  (format "~s" datum)))])))

(define (datum-violations datum)
  (if (and (pair? datum)
           (eq? (car datum) 'module))
      (module-violations datum)
      (expression-violations datum)))

(define (read-module-datum path)
  (call-with-input-file path
    (lambda (input)
      (parameterize ([read-accept-reader #t])
        (syntax->datum
         (read-syntax path input))))))

(define (provided-identifiers datum)
  (define forms
    (module-body-forms datum))
  (if forms
      (append-map
       (lambda (form)
         (if (and (pair? form)
                  (eq? (car form) 'provide))
             (append-map
              (lambda (spec)
                (cond
                  [(symbol? spec)
                   (list spec)]
                  [(and (list? spec)
                        (pair? spec)
                        (eq? (car spec) 'rename-out))
                   (filter-map
                    (lambda (renaming)
                      (and (list? renaming)
                           (= (length renaming) 2)
                           (symbol? (cadr renaming))
                           (cadr renaming)))
                    (cdr spec))]
                  [else
                   '()]))
              (cdr form))
             '()))
       forms)
      '()))

(define (module-defined-identifiers forms)
  (filter-map
   (lambda (form)
     (cond
       [(and (pair? form)
             (eq? (car form) 'def)
             (parse-def form))
        (cadr form)]
       [(valid-function-name-definition? form)
        (cadr form)]
       [else
        #f]))
   forms))

(define (resolve-import source-path spec)
  (simplify-path
   (build-path
    (or (path-only source-path)
        (current-directory))
    spec)
   #f))

(define (trusted-relative-path? source-path spec trusted-path)
  (define candidate
    (resolve-import source-path spec))
  (and (file-exists? candidate)
       (equal? (normalize-path candidate)
               trusted-path)))

(define (selected-identifiers identifiers selections)
  (append-map
   (lambda (selection)
     (cond
       [(symbol? selection)
        (if (memq selection identifiers)
            (list selection)
            '())]
       [(memq (car selection) identifiers)
        (list (cadr selection))]
       [else
        '()]))
   selections))

(define (renamed-identifiers identifiers renamings)
  (map
   (lambda (identifier)
     (define renaming
       (assq identifier renamings))
     (if renaming
         (cadr renaming)
         identifier))
   identifiers))

(define (prefixed-identifiers identifiers prefix)
  (map
   (lambda (identifier)
     (string->symbol
      (string-append
       (symbol->string prefix)
       (symbol->string identifier))))
   identifiers))

(define (transformed-import-identifiers source-path spec)
  (cond
    [(string? spec)
     (if (equal? spec expected-macro-import)
         '()
         (let ([imported-path
                (resolve-import source-path spec)])
           (if (and (safe-production-path? imported-path)
                    (file-exists? imported-path))
               (provided-identifiers
                (read-module-datum imported-path))
               '())))]
    [else
     (case (car spec)
       [(only-in)
        (selected-identifiers
         (transformed-import-identifiers source-path
                                         (cadr spec))
         (cddr spec))]
       [(except-in)
        (filter
         (lambda (identifier)
           (not (memq identifier
                      (cddr spec))))
         (transformed-import-identifiers source-path
                                         (cadr spec)))]
       [(rename-in)
        (renamed-identifiers
         (transformed-import-identifiers source-path
                                         (cadr spec))
         (cddr spec))]
       [(prefix-in)
        (prefixed-identifiers
         (transformed-import-identifiers source-path
                                         (caddr spec))
         (cadr spec))])]))

(define (module-import-identifiers source-path forms)
  (append-map
   (lambda (form)
     (if (and (pair? form)
              (eq? (car form) 'require))
         (append-map
          (lambda (spec)
            (if (allowed-require-spec? spec source-path)
                (transformed-import-identifiers source-path
                                                spec)
                '()))
          (cdr form))
         '()))
   forms))

(define (missing-import-violations source-path forms)
  (append-map
   (lambda (form)
     (if (and (pair? form)
              (eq? (car form) 'require))
         (append-map
          (lambda (spec)
            (define module-path
              (and (allowed-require-spec? spec source-path)
                   (import-module-path spec)))
            (if (and module-path
                     (not (file-exists?
                           (resolve-import source-path
                                           module-path))))
                (list
                 (violation 'missing-production-import
                            spec))
                '()))
          (cdr form))
         '()))
   forms))

(define (import-path-violations source-path forms)
  (append-map
   (lambda (form)
     (if (and (pair? form)
              (eq? (car form) 'require))
         (filter-map
          (lambda (spec)
            (define module-path
              (and (allowed-require-spec? spec source-path)
                   (import-module-path spec)))
            (and module-path
                 (not (equal? module-path
                              expected-macro-import))
                 (let ([resolved
                        (resolve-import source-path
                                        module-path)])
                   (and (not (safe-production-path? resolved))
                        (violation
                         'disallowed-production-import
                         (format "~s" spec))))))
          (cdr form))
         '()))
   forms))

(define (project-import-paths source-path forms)
  (remove-duplicates
   (append-map
    (lambda (form)
      (if (and (pair? form)
               (eq? (car form) 'require))
          (filter-map
           (lambda (spec)
             (define module-path
               (and (allowed-require-spec? spec source-path)
                    (import-module-path spec)))
             (and module-path
                  (not (equal? module-path
                               expected-macro-import))
                  (let ([resolved
                         (resolve-import source-path
                                         module-path)])
                    (and (safe-production-path? resolved)
                         (file-exists? resolved)
                         (simplify-path
                          (path->complete-path resolved))))))
           (cdr form))
          '()))
    forms)
   equal?))

(define (import-purity-violations source-path forms seen-paths)
  (filter-map
   (lambda (imported-path)
     (and (not (member imported-path
                       seen-paths
                       equal?))
          (let ([findings
                 (module-violations
                  (read-module-datum imported-path)
                  imported-path
                  (cons imported-path
                        seen-paths))])
            (and (pair? findings)
                 (violation
                  'impure-production-import
                  (format "~a (~a)"
                          imported-path
                          (violation-kind
                           (car findings))))))))
   (project-import-paths source-path forms)))

(define (file-violations path)
  (cond
    [(not (safe-production-path? path))
     (list
      (violation 'disallowed-production-path
                 (format "~a" path)))]
    [else
     (define normalized-path
       (simplify-path
        (path->complete-path path)
        #f))
     (if (safe-production-path? normalized-path)
         (let ([datum
                (read-module-datum normalized-path)])
           (remove-duplicates
            (module-violations datum
                               normalized-path
                               (list normalized-path))
            equal?))
         (list
          (violation 'disallowed-production-path
                     (format "~a" normalized-path))))]))

(define (dotenv-name? path)
  (regexp-match?
   #px"(^|\\.)env($|\\.)"
   (string-downcase
    (path->string
     (file-name-from-path path)))))

(define (safe-production-path? path)
  (and (not (dotenv-name? path))
       (not (link-exists? path))))

(define (production-files-under path)
  (cond
    [(dotenv-name? path)
     '()]
    [(link-exists? path)
     (if (equal? (path-get-extension path)
                 #".rkt")
         (list path)
         '())]
    [(directory-exists? path)
     (append-map production-files-under
                 (directory-list path
                                 #:build? #t))]
    [(and (file-exists? path)
          (equal? (path-get-extension path)
                  #".rkt"))
     (list path)]
    [else
     '()]))

(define-runtime-path default-production-directory
  "../core")

(module+ main
  (define arguments
    (vector->list
     (current-command-line-arguments)))
  (define targets
    (if (null? arguments)
        (list default-production-directory)
        (map string->path arguments)))
  (define files
    (append-map production-files-under
                targets))
  (define findings
    (for*/list ([file (in-list files)]
                [finding (in-list
                          (file-violations file))])
      (cons file finding)))

  (cond
    [(null? files)
     (eprintf "No production Racket files found.\n")
     (exit 2)]
    [(null? findings)
     (printf "Purity check passed: ~a production file(s).\n"
             (length files))]
    [else
     (for ([finding (in-list findings)])
       (eprintf "~a: ~a: ~a\n"
                (car finding)
                (violation-kind (cdr finding))
                (violation-detail (cdr finding))))
     (exit 1)]))
