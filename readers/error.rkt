#lang racket/base

(require racket/list
         racket/promise
         racket/string
         "../core/errors.rkt"
         "list.rkt"
         "string.rkt"
         "type-tag.rkt")

(provide error-value->string)

(define (lazy-apply function argument)
  ((force function) argument))

(define (error-kind->string kind)
  (case (type-tag->integer kind)
    [(0) "TYPE-MISMATCH"]
    [(1) "EMPTY-LIST"]
    [(2) "INVALID-NAT"]
    [(3) "DIVIDE-BY-ZERO"]
    [(4) "INVALID-CHAR"]
    [(5) "INVALID-STRING"]
    [(6) "WRONG-RESULT-VARIANT"]
    [else
     (format "ERROR-KIND:~a"
             (type-tag->integer kind))]))

(define (error-frames->oldest-first error)
  (reverse
   (list->host-list
    (lazy-apply raw-error-frames error)
    values)))

(define (frame->string frame actual-type)
  (define function-name
    (string-value->string
     (lazy-apply
      raw-error-frame-function-name
      frame)))
  (define position
    (type-tag->integer
     (lazy-apply
      raw-error-frame-argument-position
      frame)))
  (if (= position 0)
      (format "~a(result)" function-name)
      (format "~a(arg~a expected ~a~a)"
              function-name
              position
              (type-tag->string
               (lazy-apply
                raw-error-frame-expected-type
                frame))
              (if actual-type
                  (format " got ~a" actual-type)
                  ""))))

(define (type-mismatch-root->string details)
  (format "TYPE-MISMATCH(arg~a expected ~a got ~a)"
          (type-tag->integer
           (lazy-apply
            raw-type-mismatch-argument-position
            details))
          (type-tag->string
           (lazy-apply
            raw-type-mismatch-expected-type
            details))
          (type-tag->string
           (lazy-apply
            raw-type-mismatch-actual-type
            details))))

(define (error-value->string error)
  (define root
    (lazy-apply raw-error-root error))
  (define kind
    (lazy-apply raw-error-root-kind root))
  (define frames
    (error-frames->oldest-first error))
  (if (= (type-tag->integer kind) 0)
      (let* ([details
              (lazy-apply
               raw-error-root-details
               root)]
             [actual-type
              (type-tag->string
               (lazy-apply
                raw-type-mismatch-actual-type
                details))])
        (if (null? frames)
            (type-mismatch-root->string details)
            (string-join
             (cons
              (frame->string (car frames)
                             actual-type)
              (map
               (lambda (frame)
                 (frame->string frame #f))
               (cdr frames)))
             "\n  -> ")))
      (string-join
       (cons
        (error-kind->string kind)
        (map
         (lambda (frame)
           (frame->string frame #f))
         frames))
       "\n  -> ")))
