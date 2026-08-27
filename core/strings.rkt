#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "binary-nat.rkt"
         "chars.rkt"
         "errors.rkt"
         "fix.rkt"
         "function-names.rkt"
         "list-nat.rkt"
         "lists.rkt"
         "logic.rkt"
         "objects.rkt"
         "tags.rkt"
         "typecheck.rkt")

(provide EMPTY-STRING
         raw-make-string
         raw-string-value
         raw-string-empty?
         raw-string-length
         raw-string-equal
         raw-string-append
         raw-string-head
         raw-string-tail
         raw-string-prefix?
         raw-string-contains?
         typed-make-string
         typed-string-empty?
         typed-string-length
         typed-string-equal
         typed-string-append
         typed-string-head
         typed-string-tail
         typed-string-prefix?
         typed-string-contains?
         (rename-out [typed-make-string MAKE-STRING]
                     [typed-string-empty? STRING-EMPTY?]
                     [typed-string-length STRING-LENGTH]
                     [typed-string-equal STRING-EQ]
                     [typed-string-append STRING-APPEND]
                     [typed-string-head STRING-HEAD]
                     [typed-string-tail STRING-TAIL]
                     [typed-string-prefix? STRING-PREFIX?]
                     [typed-string-contains? STRING-CONTAINS?]))

(def raw-make-string chars =
  ((raw-make-object string-type) chars))

(def raw-string-value string =
  (raw-object-value string))

(def EMPTY-STRING =
  (raw-make-string NIL))

(def raw-char-list-valid-step recur chars =
  (((raw-if
     (raw-list-is-nil chars))
    raw-true)
   (((raw-if
      ((raw-is-type char-type)
       (raw-list-head chars)))
     (recur
      (raw-list-tail chars)))
    raw-false)))

(def raw-char-list-valid? =
  (raw-fix raw-char-list-valid-step))

(def raw-make-checked-string list-payload =
  (lambda-let chars =
    (raw-list-object list-payload)
    (((raw-if
       (raw-char-list-valid? chars))
      (raw-make-string chars))
     ((raw-add-result-frame invalid-string-error)
      make-string-function-name))))

(def raw-string-empty? chars =
  (raw-list-is-nil chars))

(def raw-string-length chars =
  (raw-list-length chars))

(def raw-char-equal left right =
  ((raw-nat-equal
    (raw-char-value left))
   (raw-char-value right)))

(def raw-string-equal-step recur left right =
  (((raw-if
     (raw-list-is-nil left))
    (raw-list-is-nil right))
   (((raw-if
      (raw-list-is-nil right))
     raw-false)
    (((raw-if
       ((raw-char-equal
         (raw-list-head left))
        (raw-list-head right)))
      ((recur
        (raw-list-tail left))
       (raw-list-tail right)))
     raw-false))))

(def raw-string-equal =
  (raw-fix raw-string-equal-step))

(def raw-string-append left right =
  ((raw-append left) right))

(def raw-string-head chars =
  (((raw-if
     (raw-list-is-nil chars))
    ((raw-add-result-frame empty-list-error)
     string-head-function-name))
   (raw-list-head chars)))

(def raw-string-tail chars =
  (((raw-if
     (raw-list-is-nil chars))
    ((raw-add-result-frame empty-list-error)
     string-tail-function-name))
   (raw-make-string
    (raw-list-tail chars))))

(def raw-string-prefix-step recur string prefix =
  (((raw-if
     (raw-list-is-nil prefix))
    raw-true)
   (((raw-if
      (raw-list-is-nil string))
     raw-false)
    (((raw-if
       ((raw-char-equal
         (raw-list-head string))
        (raw-list-head prefix)))
      ((recur
        (raw-list-tail string))
       (raw-list-tail prefix)))
     raw-false))))

(def raw-string-prefix? =
  (raw-fix raw-string-prefix-step))

(def raw-string-contains-step recur string substring =
  (((raw-if
     (raw-list-is-nil substring))
    raw-true)
   (((raw-if
      (raw-list-is-nil string))
     raw-false)
    (((raw-if
       ((raw-string-prefix? string)
        substring))
      raw-true)
     ((recur
       (raw-list-tail string))
      substring)))))

(def raw-string-contains? =
  (raw-fix raw-string-contains-step))

(def string-unary-signature =
  ((raw-cons string-type) NIL))

(def string-binary-signature =
  ((raw-cons string-type)
   ((raw-cons string-type) NIL)))

(def typed-make-string =
  ((((make-typed-function raw-make-checked-string)
     make-string-function-name)
    list-unary-signature)
   raw-keep-return))

(def typed-string-empty? =
  ((((make-typed-function raw-string-empty?)
     string-empty-function-name)
    string-unary-signature)
   (raw-wrap-return bool-type)))

(def typed-string-length =
  ((((make-typed-function raw-string-length)
     string-length-function-name)
    string-unary-signature)
   (raw-wrap-return nat-type)))

(def typed-string-equal =
  ((((make-typed-function raw-string-equal)
     string-eq-function-name)
    string-binary-signature)
   (raw-wrap-return bool-type)))

(def typed-string-append =
  ((((make-typed-function raw-string-append)
     string-append-function-name)
    string-binary-signature)
   (raw-wrap-return string-type)))

(def typed-string-head =
  ((((make-typed-function raw-string-head)
     string-head-function-name)
    string-unary-signature)
   raw-keep-return))

(def typed-string-tail =
  ((((make-typed-function raw-string-tail)
     string-tail-function-name)
    string-unary-signature)
   raw-keep-return))

(def typed-string-prefix? =
  ((((make-typed-function raw-string-prefix?)
     string-prefix-function-name)
    string-binary-signature)
   (raw-wrap-return bool-type)))

(def typed-string-contains? =
  ((((make-typed-function raw-string-contains?)
     string-contains-function-name)
    string-binary-signature)
   (raw-wrap-return bool-type)))
