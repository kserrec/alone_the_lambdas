#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "../core/binary-nat.rkt"
         "../core/chars.rkt"
         (only-in "../core/errors.rkt"
                  NIL
                  raw-make-root-error)
         "../core/fix.rkt"
         (only-in "../core/lists.rkt"
                  raw-append
                  raw-cons
                  raw-fold)
         "../core/logic.rkt"
         "../core/objects.rkt"
         "../core/result.rkt"
         "../core/strings.rkt"
         "../core/tags.rkt"
         "../core/typecheck.rkt"
         (only-in "http.rkt"
                  raw-crlf-chars
                  raw-http-version-chars
                  raw-space-chars
                  unsupported-http-status-kind))

(provide HTTP-STATUS-OK
         HTTP-STATUS-BAD-REQUEST
         HTTP-STATUS-NOT-FOUND
         HTTP-STATUS-INTERNAL-SERVER-ERROR
         render-http-response)

(def raw-name-char bits =
  ((raw-make-object char-type) bits))

(def raw-name-string chars =
  ((raw-make-object string-type) chars))

(define-function-name render-http-response-function-name render-http-response)

(def unsupported-http-status-error =
  (raw-make-root-error unsupported-http-status-kind))

(def raw-unsupported-http-status-result =
  (raw-make-err unsupported-http-status-error))

;; Fixed response bytes stay in this separately scanned pure module so request
;; parsing and response construction can be reviewed independently.
(def raw-content-length-prefix-chars =
  ((raw-cons C)
   ((raw-cons o)
    ((raw-cons n)
     ((raw-cons t)
      ((raw-cons e)
       ((raw-cons n)
        ((raw-cons t)
         ((raw-cons HYPHEN)
          ((raw-cons L)
           ((raw-cons e)
            ((raw-cons n)
             ((raw-cons g)
              ((raw-cons t)
               ((raw-cons h)
                ((raw-cons COLON)
                 ((raw-cons SPACE) NIL)))))))))))))))))

(def raw-connection-close-chars =
  ((raw-cons C)
   ((raw-cons o)
    ((raw-cons n)
     ((raw-cons n)
      ((raw-cons e)
       ((raw-cons c)
        ((raw-cons t)
         ((raw-cons i)
          ((raw-cons o)
           ((raw-cons n)
            ((raw-cons COLON)
             ((raw-cons SPACE)
              ((raw-cons c)
               ((raw-cons l)
                ((raw-cons o)
                 ((raw-cons s)
                  ((raw-cons e) NIL))))))))))))))))))

(def raw-ok-reason-chars =
  ((raw-cons O)
   ((raw-cons K) NIL)))

(def raw-bad-request-reason-chars =
  ((raw-cons B)
   ((raw-cons a)
    ((raw-cons d)
     ((raw-cons SPACE)
      ((raw-cons R)
       ((raw-cons e)
        ((raw-cons q)
         ((raw-cons u)
          ((raw-cons e)
           ((raw-cons s)
            ((raw-cons t) NIL))))))))))))

(def raw-not-found-reason-chars =
  ((raw-cons N)
   ((raw-cons o)
    ((raw-cons t)
     ((raw-cons SPACE)
      ((raw-cons F)
       ((raw-cons o)
        ((raw-cons u)
         ((raw-cons n)
          ((raw-cons d) NIL))))))))))

(def raw-internal-server-error-reason-chars =
  ((raw-cons I)
   ((raw-cons n)
    ((raw-cons t)
     ((raw-cons e)
      ((raw-cons r)
       ((raw-cons n)
        ((raw-cons a)
         ((raw-cons l)
          ((raw-cons SPACE)
           ((raw-cons S)
            ((raw-cons e)
             ((raw-cons r)
              ((raw-cons v)
               ((raw-cons e)
                ((raw-cons r)
                 ((raw-cons SPACE)
                  ((raw-cons E)
                   ((raw-cons r)
                    ((raw-cons r)
                     ((raw-cons o)
                      ((raw-cons r) NIL))))))))))))))))))))))

(def raw-hundred-bits =
  ((raw-nat-mult
    (raw-nat-value TEN))
   (raw-nat-value TEN)))

(def raw-status-ok-bits =
  ((raw-nat-mult
    (raw-nat-value TWO))
   raw-hundred-bits))

(def raw-status-bad-request-bits =
  ((raw-nat-mult
    (raw-nat-value FOUR))
   raw-hundred-bits))

(def raw-status-not-found-bits =
  ((raw-nat-add raw-status-bad-request-bits)
   (raw-nat-value FOUR)))

(def raw-status-internal-server-error-bits =
  ((raw-nat-mult
    (raw-nat-value FIVE))
   raw-hundred-bits))

(def HTTP-STATUS-OK =
  (raw-make-nat raw-status-ok-bits))

(def HTTP-STATUS-BAD-REQUEST =
  (raw-make-nat raw-status-bad-request-bits))

(def HTTP-STATUS-NOT-FOUND =
  (raw-make-nat raw-status-not-found-bits))

(def HTTP-STATUS-INTERNAL-SERVER-ERROR =
  (raw-make-nat raw-status-internal-server-error-bits))

(def raw-status-supported? status =
  ((raw-or
    ((raw-or
      ((raw-nat-equal status)
       raw-status-ok-bits))
     ((raw-nat-equal status)
      raw-status-bad-request-bits)))
   ((raw-or
     ((raw-nat-equal status)
      raw-status-not-found-bits))
    ((raw-nat-equal status)
     raw-status-internal-server-error-bits))))

(def raw-status-reason status =
  (((raw-if
     ((raw-nat-equal status)
      raw-status-ok-bits))
    raw-ok-reason-chars)
   (((raw-if
      ((raw-nat-equal status)
       raw-status-bad-request-bits))
     raw-bad-request-reason-chars)
    (((raw-if
       ((raw-nat-equal status)
        raw-status-not-found-bits))
      raw-not-found-reason-chars)
     raw-internal-server-error-reason-chars))))

(def raw-decimal-char digit =
  (raw-make-char
   ((raw-nat-add
     (raw-char-value DIGIT-0))
    digit)))

(def raw-nat-decimal-chars-step recur value =
  (((raw-if
     ((raw-nat-less value)
      (raw-nat-value TEN)))
    ((raw-cons
      (raw-decimal-char value))
     NIL))
   (lambda-let quotient =
     ((raw-nat-div value)
      (raw-nat-value TEN))
     (lambda-let remainder =
       ((raw-nat-sub value)
        ((raw-nat-mult quotient)
         (raw-nat-value TEN)))
       ((raw-append
         (recur quotient))
        ((raw-cons
          (raw-decimal-char remainder))
         NIL))))))

(def raw-nat-decimal-chars value =
  ((raw-fix raw-nat-decimal-chars-step)
   value))

(def raw-concat lists =
  (((raw-fold raw-append) NIL)
   lists))

(def raw-render-supported-http-response status body =
  (lambda-let status-digits =
    (raw-nat-decimal-chars status)
    (lambda-let content-length-digits =
      (raw-nat-decimal-chars
       (raw-string-length body))
      (raw-make-ok
       (raw-make-string
        (raw-concat
         ((raw-cons raw-http-version-chars)
          ((raw-cons raw-space-chars)
           ((raw-cons status-digits)
            ((raw-cons raw-space-chars)
             ((raw-cons
               (raw-status-reason status))
              ((raw-cons raw-crlf-chars)
               ((raw-cons raw-content-length-prefix-chars)
                ((raw-cons content-length-digits)
                 ((raw-cons raw-crlf-chars)
                  ((raw-cons raw-connection-close-chars)
                   ((raw-cons raw-crlf-chars)
                    ((raw-cons raw-crlf-chars)
                     ((raw-cons body) NIL)))))))))))))))))))

(def raw-render-http-response status body =
  (((raw-if
     (raw-status-supported? status))
    ((raw-render-supported-http-response status)
     body))
   raw-unsupported-http-status-result))

(def http-response-signature =
  ((raw-cons nat-type)
   ((raw-cons string-type) NIL)))

(def render-http-response =
  ((((make-typed-function raw-render-http-response)
     render-http-response-function-name)
    http-response-signature)
   raw-keep-return))
