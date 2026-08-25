#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "errors.rkt"
         "fix.rkt"
         "logic.rkt"
         "objects.rkt"
         "pair.rkt"
         "tags.rkt")

(provide make-typed-function
         raw-wrap-return
         raw-keep-return)

(def raw-signature-head signature =
  (raw-first
   (raw-object-value signature)))

(def raw-signature-tail signature =
  (raw-second
   (raw-object-value signature)))

(def raw-signature-is-empty signature =
  ((raw-is-type error-type)
   (raw-signature-tail signature)))

(def raw-wrap-return return-type result =
  ((raw-make-object return-type) result))

(def raw-keep-return result =
  result)

(def raw-absorb-error-step recur remaining-types failure =
  (((raw-if
     (raw-signature-is-empty remaining-types))
    failure)
   (lambda (ignored)
     ((recur
       (raw-signature-tail remaining-types))
      failure))))

(def raw-absorb-error remaining-types failure =
  (((raw-fix raw-absorb-error-step)
    remaining-types)
   failure))

(def raw-make-typed-function-step recur raw-function function-name expected-types return-policy argument-position =
  (((raw-if
     (raw-signature-is-empty expected-types))
    (return-policy raw-function))
   (lambda (argument)
     (lambda-let expected-type =
       (raw-signature-head expected-types)
       (lambda-let remaining-types =
         (raw-signature-tail expected-types)
         (((raw-if
           ((raw-is-type error-type) argument))
           ((raw-absorb-error remaining-types)
            ((((raw-bubble-error argument)
               function-name)
              argument-position)
             expected-type)))
          (((raw-if
             ((raw-is-type expected-type) argument))
            (((((recur
                 (raw-function
                  (raw-object-value argument)))
                function-name)
               remaining-types)
              return-policy)
             (church-succ argument-position)))
           ((raw-absorb-error remaining-types)
            ((((raw-bubble-error
                (((raw-make-type-mismatch-error
                   argument-position)
                  expected-type)
                 (raw-object-type argument)))
               function-name)
              argument-position)
             expected-type)))))))))

(def make-typed-function raw-function function-name expected-types return-policy =
  ((((((raw-fix raw-make-typed-function-step)
       raw-function)
      function-name)
     expected-types)
    return-policy)
   argument-position-one))
