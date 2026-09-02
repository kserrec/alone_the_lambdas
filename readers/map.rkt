#lang racket/base

(require racket/promise
         "../core/map.rkt"
         "list.rkt")

(provide map->string)

(define (lazy-apply function argument)
  ((force function) argument))

(define (map->string value)
  (format "MAP:~a"
          (length
           (list->host-list
            (lazy-apply raw-map-entries value)
            (lambda (entry) entry)))))
