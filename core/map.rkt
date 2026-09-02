#lang s-exp "../macros/lazy-with-macros.rkt"

;; A persistent Map (tag 11) pairs a user-supplied pure key-equality
;; function with a private object-language List of key/value Pairs — never
;; a Racket collection or Racket equality. Setting or removing an entry
;; returns a new Map and never alters the old one. Lookup returns Option:
;; NONE means expected absence. The equality function's contract is
;; `key -> key -> Bool`; a comparison that returns a non-Bool value is a
;; structured Error, and one that returns an Error bubbles. Keys and
;; values may be any non-Error object-language values; no `Any` tag exists
;; and the generalized checker is unchanged.

(require "../macros/macros.rkt"
         (only-in "errors.rkt"
                  NIL
                  raw-cons
                  raw-add-result-frame
                  raw-bubble-error
                  raw-make-type-mismatch-error
                  argument-position-one)
         "fix.rkt"
         "function-names.rkt"
         (only-in "list-nat.rkt"
                  raw-list-length)
         (only-in "lists.rkt"
                  raw-list-head
                  raw-list-is-nil
                  raw-list-tail)
         "logic.rkt"
         "objects.rkt"
         (only-in "option.rkt"
                  NONE
                  raw-make-some)
         "pair.rkt"
         (only-in "rat.rkt"
                  raw-whole-rat)
         "tags.rkt"
         "typecheck.rkt")

(provide raw-map-equality
         raw-map-entries
         typed-make-map
         typed-map-empty?
         typed-map-size
         typed-map-lookup
         (rename-out [typed-make-map MAKE-MAP]
                     [typed-map-empty? MAP-EMPTY?]
                     [typed-map-size MAP-SIZE]
                     [typed-map-lookup MAP-LOOKUP]))

(def raw-make-map equality entries =
  ((raw-make-object map-type)
   ((raw-pair equality) entries)))

(def raw-map-equality map =
  (raw-first
   (raw-object-value map)))

(def raw-map-entries map =
  (raw-second
   (raw-object-value map)))

(def raw-entry-key entry =
  (raw-first entry))

(def raw-entry-value entry =
  (raw-second entry))

;; The equality function must answer with a typed Bool. An Error answer
;; bubbles with the operation's frame; any other answer is a structured
;; type mismatch attributed to the same operation.
(def raw-comparison-boolean answer operation-name continue =
  (((raw-if
     ((raw-is-type bool-type) answer))
    (continue
     (raw-object-value answer)))
   (((raw-if
      ((raw-is-type error-type) answer))
     ((raw-add-result-frame answer) operation-name))
    ((((raw-bubble-error
        (((raw-make-type-mismatch-error
           argument-position-one)
          bool-type)
         (raw-object-type answer)))
       operation-name)
      argument-position-one)
     bool-type))))

;; MAKE-MAP accepts the pure equality function as-is; an Error argument
;; bubbles rather than becoming a Map component.
(def typed-make-map equality =
  (((raw-if
     ((raw-is-type error-type) equality))
    equality)
   ((raw-make-map equality) NIL)))

(def map-unary-signature =
  ((raw-cons map-type) NIL))

(def raw-map-is-empty payload =
  (raw-list-is-nil
   (raw-second payload)))

(def typed-map-empty? =
  ((((make-typed-function raw-map-is-empty)
     map-empty-function-name)
    map-unary-signature)
   (raw-wrap-return bool-type)))

(def raw-map-size payload =
  (raw-whole-rat
   (raw-list-length
    (raw-second payload))))

(def typed-map-size =
  ((((make-typed-function raw-map-size)
     map-size-function-name)
    map-unary-signature)
   (raw-wrap-return rat-type)))

;; Strict Map validation with the operation's own frame, shared by every
;; mixed-strictness operation below (their key and value arguments carry
;; no tag contract, so the checker is not used).
(def raw-with-map map operation-name continue =
  (((raw-if
     ((raw-is-type error-type) map))
    ((((raw-bubble-error map)
       operation-name)
      argument-position-one)
     map-type))
   (((raw-if
      ((raw-is-type map-type) map))
     (continue map))
    ((((raw-bubble-error
        (((raw-make-type-mismatch-error
           argument-position-one)
          map-type)
         (raw-object-type map)))
       operation-name)
      argument-position-one)
     map-type))))

(def raw-map-find-step recur equality operation-name key entries =
  (((raw-if
     (raw-list-is-nil entries))
    NONE)
   (((raw-comparison-boolean
      ((equality key)
       (raw-entry-key
        (raw-list-head entries))))
     operation-name)
    (lambda (matched)
      (((raw-if matched)
        (raw-make-some
         (raw-entry-value
          (raw-list-head entries))))
       ((((recur equality)
          operation-name)
         key)
        (raw-list-tail entries)))))))

(def raw-map-find =
  (raw-fix raw-map-find-step))

(def typed-map-lookup map key =
  (((raw-if
     ((raw-is-type error-type) key))
    ((raw-add-result-frame key) map-lookup-function-name))
   (((raw-with-map map) map-lookup-function-name)
    (lambda (validated)
      ((((raw-map-find
          (raw-map-equality validated))
         map-lookup-function-name)
        key)
       (raw-map-entries validated))))))
