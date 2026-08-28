#lang racket/base

(require (only-in racket/file file-type-bits regular-file-type-bits)
         (only-in racket/path path-get-extension)
         (for-syntax racket/base
                     (only-in racket/path path-only)))

(define command-misuse-status 64)
(define invalid-source-status 65)
(define unavailable-source-status 66)
(define unexpected-failure-status 70)

(define help-text
  (string-append
   "Usage:\n"
   "  atl run FILE.atl\n"
   "  atl --help\n"
   "  atl --version\n"))

(define language-declaration
  #"#lang alone_the_lambdas")

(define-syntax (embedded-product-version stx)
  (define source (syntax-source stx))
  (unless (path? source)
    (raise-syntax-error #f "runner source path is unavailable" stx))
  (define content
    (call-with-input-file (build-path (path-only source) 'up "VERSION")
      (lambda (input)
        (read-bytes 64 input))
      #:mode 'binary))
  (define matched
    (and (bytes? content)
         (regexp-match #px#"^(0[.]2[.]0(?:-dev|-rc[.]1)?)\n$"
                       content)))
  (unless matched
    (raise-syntax-error #f "invalid product version metadata" stx))
  (datum->syntax stx
                 (bytes->string/utf-8 (cadr matched))))

(define (stop status source reason)
  (if source
      (eprintf "Alone the Lambdas: ~a: ~a\n" source reason)
      (eprintf "Alone the Lambdas: ~a\n" reason))
  (exit status))

(define (dotenv-component? part)
  (and (path? part)
       (regexp-match?
        #px"(^|\\.)env($|\\.)"
        (string-downcase (path->string part)))))

(define (dotenv-path? path)
  (for/or ([part (in-list (explode-path path))])
    (dotenv-component? part)))

(define (resolve-parent-path path)
  (let loop ([remaining (explode-path (path->complete-path path))]
             [resolved #f]
             [seen '()])
    (cond
      [(null? remaining)
       (and resolved (simplify-path resolved #f))]
      [else
       (define next
         (if resolved
             (build-path resolved (car remaining))
             (car remaining)))
       (cond
         [(link-exists? next)
          (if (member next seen equal?)
              #f
              (loop
               (append
                (explode-path
                 (path->complete-path (resolve-path next)))
                (cdr remaining))
               #f
               (cons next seen)))]
         [else
          (loop (cdr remaining) next seen)])])))

(define (valid-language-declaration? source)
  (call-with-input-file source
    (lambda (input)
      (define declaration
        (read-bytes (bytes-length language-declaration) input))
      (define terminator
        (read-byte input))
      (and (equal? declaration language-declaration)
           (or (eof-object? terminator)
               (= terminator 10)
               (and (= terminator 13)
                    (equal? (read-byte input) 10)))))
    #:mode 'binary))

(define (regular-file? path)
  (= (bitwise-and
      (hash-ref (file-or-directory-stat path) 'mode)
      file-type-bits)
     regular-file-type-bits))

(define (validate-source source-name)
  (with-handlers
      ([exn:fail?
        (lambda (failure)
          (stop unavailable-source-status source-name "source is unavailable"))])
    (define supplied-path (string->path source-name))
    (when (dotenv-path? supplied-path)
      (stop unavailable-source-status source-name "dotenv paths are refused"))
    (unless (equal? (path-get-extension supplied-path) #".atl")
      (stop invalid-source-status source-name "source must end in .atl"))
    (define complete-path (path->complete-path supplied-path))
    (when (link-exists? complete-path)
      (stop unavailable-source-status source-name "symbolic links are refused"))
    (define-values (parent name directory?)
      (split-path complete-path))
    (define resolved-parent (resolve-parent-path parent))
    (unless resolved-parent
      (stop unavailable-source-status source-name "source is unavailable"))
    (when (dotenv-path? resolved-parent)
      (stop unavailable-source-status source-name "dotenv paths are refused"))
    (define resolved-source (build-path resolved-parent name))
    (unless (regular-file? resolved-source)
      (stop unavailable-source-status source-name "source is unavailable"))
    (unless (valid-language-declaration? resolved-source)
      (stop invalid-source-status source-name
            "first line must be #lang alone_the_lambdas"))
    supplied-path))

(define (run-source source-name)
  (define source-path (validate-source source-name))
  (with-handlers
      ([exn:fail:read?
        (lambda (failure)
          (stop invalid-source-status source-name "source could not be read"))]
       [exn:fail:syntax?
        (lambda (failure)
          (stop invalid-source-status source-name "source has invalid syntax"))]
       [exn:fail:filesystem?
        (lambda (failure)
          (stop unavailable-source-status source-name "source is unavailable"))]
       [exn:fail?
        (lambda (failure)
          (stop unexpected-failure-status source-name
                "unexpected launcher failure"))])
    (dynamic-require source-path #f)))

(define (main)
  (define arguments
    (vector->list (current-command-line-arguments)))
  (cond
    [(equal? arguments '("--help"))
     (display help-text)]
    [(equal? arguments '("--version"))
     (define product-version (embedded-product-version))
     (display "Alone the Lambdas ")
     (display product-version)
     (newline)]
    [(and (= (length arguments) 2)
          (equal? (car arguments) "run"))
     (run-source (cadr arguments))]
    [else
     (stop command-misuse-status #f
           "usage: atl run FILE.atl | atl --help | atl --version")]))

(main)
