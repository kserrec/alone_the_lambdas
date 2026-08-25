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

(define scaffolding-heads
  '(require
    provide
    #%require
    #%provide))

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
      (byte-regexp? datum)))

(define (unary-formals? formals)
  (and (list? formals)
       (= (length formals) 1)
       (symbol? (car formals))))

(define (arity-specific-checker-name? datum)
  (and (symbol? datum)
       (regexp-match?
        #px"^(type-check|make-typed-function)-?[0-9]+$"
        (symbol->string datum))))

(define (form-violations form)
  (define head
    (and (pair? form)
         (car form)))
  (append
   (if (and (eq? head 'lambda)
            (pair? (cdr form))
            (not (unary-formals? (cadr form))))
       (list
        (violation 'non-unary-lambda
                   (format "~s" form)))
       '())
   (if (and (eq? head 'define)
            (pair? (cdr form))
            (pair? (cadr form)))
       (list
        (violation 'host-function-definition
                   (format "~s" form)))
       '())
   (if (memq head forbidden-heads)
       (list
        (violation 'forbidden-host-form
                   (symbol->string head)))
       '())))

(define (form-contents-violations form)
  (cond
    [(pair? form)
     (append (datum-violations (car form))
             (form-contents-violations (cdr form)))]
    [(null? form)
     '()]
    [else
     (datum-violations form)]))

(define (datum-violations datum)
  (cond
    [(pair? datum)
     (define head (car datum))
     (cond
       [(eq? head 'module)
        (append-map datum-violations
                    (cdddr datum))]
       [(memq head scaffolding-heads)
        '()]
       [else
        (append (form-violations datum)
                (form-contents-violations datum))])]
    [(host-datum? datum)
     (list
      (violation 'forbidden-host-datum
                 (format "~s" datum)))]
    [(arity-specific-checker-name? datum)
     (list
      (violation 'arity-specific-checker
                 (symbol->string datum)))]
    [else
     '()]))

(define (file-violations path)
  (call-with-input-file path
    (lambda (input)
      (parameterize ([read-accept-reader #t])
        (datum-violations
         (syntax->datum
          (read-syntax path input)))))))

(define (dotenv-name? path)
  (regexp-match?
   #px"(^|\\.)env($|\\.)"
   (path->string
    (file-name-from-path path))))

(define (production-files-under path)
  (cond
    [(dotenv-name? path)
     '()]
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
