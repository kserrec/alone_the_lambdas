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
    apply
    values
    call/cc
    dynamic-wind
    delay
    force
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
    map
    filter
    foldl
    foldr
    append
    reverse
    length
    vector
    hash
    set
    box
    set!
    set-box!
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

(define (unary-formals? formals)
  (and (list? formals)
       (= (length formals) 1)
       (symbol? (car formals))))

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

(define (datum-violations datum)
  (cond
    [(pair? datum)
     (append (form-violations datum)
             (append-map datum-violations datum))]
    [(vector? datum)
     (append-map datum-violations
                 (vector->list datum))]
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
