#lang lazy

(require (for-syntax racket/base))

(provide def
         lambda-let
         define-function-name)

(define-for-syntax (curried-lambdas arguments body)
  (if (null? arguments)
      body
      #`(lambda (#,(car arguments))
          #,(curried-lambdas (cdr arguments) body))))

(define-syntax (def stx)
  (syntax-case stx (=)
    [(_ name argument ... = body)
     (and (identifier? #'name)
          (andmap identifier? (syntax->list #'(argument ...))))
     #`(define name
         #,(curried-lambdas (syntax->list #'(argument ...))
                            #'body))]))

(define-syntax (lambda-let stx)
  (syntax-case stx (=)
    [(_ name = value body)
     (identifier? #'name)
     #'((lambda (name)
          body)
       value)]))

(define-for-syntax (use-site-identifier context name)
  (datum->syntax context name))

(define-for-syntax (name-list-expression elements context)
  (if (null? elements)
      (use-site-identifier context 'NIL)
      #`((#,(use-site-identifier context 'raw-cons)
           #,(car elements))
          #,(name-list-expression (cdr elements)
                                  context))))

(define-for-syntax (name-byte-expression byte context)
  (define bit-expressions
    (map
     (lambda (digit)
       (use-site-identifier
        context
        (if (char=? digit #\1)
            'raw-true
            'raw-false)))
     (string->list
      (number->string
       byte
       2))))
  #`(#,(use-site-identifier context 'raw-name-char)
     #,(name-list-expression bit-expressions
                             context)))

(define-for-syntax (function-name-expression name context)
  (define character-expressions
    (map
     (lambda (byte)
       (name-byte-expression byte context))
     (bytes->list
      (string->bytes/utf-8
       (symbol->string
        (syntax-e name))))))
  #`(#,(use-site-identifier context 'raw-name-string)
     #,(name-list-expression character-expressions
                             context)))

(define-syntax (define-function-name stx)
  (syntax-case stx ()
    [(_ binding rendered-name)
     (and (identifier? #'binding)
          (identifier? #'rendered-name))
     #`(define binding
         #,(function-name-expression #'rendered-name
                                     #'rendered-name))]))
