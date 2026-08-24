#lang racket/base

(require racket/promise)

(provide raw-boolean->boolean)

(define (raw-boolean->boolean value)
  (force
   ((force
     ((force value) #t))
    #f)))
