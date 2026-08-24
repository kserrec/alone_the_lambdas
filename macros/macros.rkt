#lang lazy

(require (for-syntax racket/base))

(provide def
         lambda-let)

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
