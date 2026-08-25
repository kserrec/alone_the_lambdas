#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "errors.rkt"
         "function-names.rkt"
         "lists.rkt"
         "logic.rkt"
         "objects.rkt"
         "tags.rkt"
         "typecheck.rkt")

(provide TRUE
         FALSE
         typed-not
         typed-and
         typed-or
         typed-xor
         typed-if
         (rename-out [typed-not NOT]
                     [typed-and AND]
                     [typed-or OR]
                     [typed-xor XOR]
                     [typed-if if]))

(def raw-make-bool value =
  ((raw-make-object bool-type) value))

(def TRUE =
  (raw-make-bool raw-true))

(def FALSE =
  (raw-make-bool raw-false))

(def bool-unary-signature =
  ((raw-cons bool-type) NIL))

(def bool-binary-signature =
  ((raw-cons bool-type)
   ((raw-cons bool-type) NIL)))

(def typed-not =
  ((((make-typed-function raw-not)
     not-function-name)
    bool-unary-signature)
   (raw-wrap-return bool-type)))

(def typed-and =
  ((((make-typed-function raw-and)
     and-function-name)
    bool-binary-signature)
   (raw-wrap-return bool-type)))

(def typed-or =
  ((((make-typed-function raw-or)
     or-function-name)
    bool-binary-signature)
   (raw-wrap-return bool-type)))

(def typed-xor =
  ((((make-typed-function raw-xor)
     xor-function-name)
    bool-binary-signature)
   (raw-wrap-return bool-type)))

(def raw-ignore-if-branches failure ignored-then ignored-else =
  failure)

(def typed-if condition =
  (((raw-if
     ((raw-is-type error-type) condition))
    (raw-ignore-if-branches
     ((((raw-bubble-error condition)
        if-function-name)
       argument-position-one)
      bool-type)))
   (((raw-if
      ((raw-is-type bool-type) condition))
     (raw-if
      (raw-object-value condition)))
    (raw-ignore-if-branches
     ((((raw-bubble-error
         (((raw-make-type-mismatch-error
            argument-position-one)
           bool-type)
          (raw-object-type condition)))
        if-function-name)
       argument-position-one)
      bool-type)))))
