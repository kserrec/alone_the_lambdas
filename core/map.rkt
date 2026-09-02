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
                  raw-make-some
                  raw-option-is-some)
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
         typed-map-contains?
         typed-map-set
         typed-map-remove
         (rename-out [typed-make-map MAKE-MAP]
                     [typed-map-empty? MAP-EMPTY?]
                     [typed-map-size MAP-SIZE]
                     [typed-map-lookup MAP-LOOKUP]
                     [typed-map-contains? MAP-CONTAINS?]
                     [typed-map-set MAP-SET]
                     [typed-map-remove MAP-REMOVE]))

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

;; MAKE-MAP accepts the pure equality function exactly as supplied: the
;; strict layer is a closed convention, and probing an arbitrary function
;; with a tag check is undefined, so no check runs here. The function's
;; Bool contract is enforced at every comparison instead.
(def typed-make-map equality =
  ((raw-make-map equality) NIL))

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

(def typed-map-contains? map key =
  (((raw-if
     ((raw-is-type error-type) key))
    ((raw-add-result-frame key) map-contains-function-name))
   (((raw-with-map map) map-contains-function-name)
    (lambda (validated)
      (lambda-let found =
        ((((raw-map-find
            (raw-map-equality validated))
           map-contains-function-name)
          key)
         (raw-map-entries validated))
        (((raw-if
           ((raw-is-type error-type) found))
          found)
         ((raw-make-object bool-type)
          (raw-option-is-some
           (raw-object-value found)))))))))

;; Persistent update: a matched key is replaced in place with no duplicate
;; entry; an absent key prepends. A comparison failure mid-walk propagates
;; as the whole answer instead of hiding inside a rebuilt List.
(def raw-map-set-step recur equality operation-name key value entries =
  (((raw-if
     (raw-list-is-nil entries))
    ((raw-cons
      ((raw-pair key) value))
     NIL))
   (((raw-comparison-boolean
      ((equality key)
       (raw-entry-key
        (raw-list-head entries))))
     operation-name)
    (lambda (matched)
      (((raw-if matched)
        ((raw-cons
          ((raw-pair key) value))
         (raw-list-tail entries)))
       (lambda-let rest =
         (((((recur equality)
             operation-name)
            key)
           value)
          (raw-list-tail entries))
         (((raw-if
            ((raw-is-type error-type) rest))
           rest)
          ((raw-cons
            (raw-list-head entries))
           rest))))))))

(def raw-map-set =
  (raw-fix raw-map-set-step))

(def typed-map-set map key value =
  (((raw-if
     ((raw-is-type error-type) key))
    ((raw-add-result-frame key) map-set-function-name))
   (((raw-if
      ((raw-is-type error-type) value))
     ((raw-add-result-frame value) map-set-function-name))
    (((raw-with-map map) map-set-function-name)
     (lambda (validated)
       (lambda-let updated =
         (((((raw-map-set
              (raw-map-equality validated))
             map-set-function-name)
            key)
           value)
          (raw-map-entries validated))
         (((raw-if
            ((raw-is-type error-type) updated))
           updated)
          ((raw-make-map
            (raw-map-equality validated))
           updated))))))))

;; Persistent removal: removing an absent key returns an equivalent Map.
(def raw-map-remove-step recur equality operation-name key entries =
  (((raw-if
     (raw-list-is-nil entries))
    NIL)
   (((raw-comparison-boolean
      ((equality key)
       (raw-entry-key
        (raw-list-head entries))))
     operation-name)
    (lambda (matched)
      (((raw-if matched)
        (raw-list-tail entries))
       (lambda-let rest =
         ((((recur equality)
            operation-name)
           key)
          (raw-list-tail entries))
         (((raw-if
            ((raw-is-type error-type) rest))
           rest)
          ((raw-cons
            (raw-list-head entries))
           rest))))))))

(def raw-map-remove =
  (raw-fix raw-map-remove-step))

(def typed-map-remove map key =
  (((raw-if
     ((raw-is-type error-type) key))
    ((raw-add-result-frame key) map-remove-function-name))
   (((raw-with-map map) map-remove-function-name)
    (lambda (validated)
      (lambda-let updated =
        ((((raw-map-remove
            (raw-map-equality validated))
           map-remove-function-name)
          key)
         (raw-map-entries validated))
        (((raw-if
           ((raw-is-type error-type) updated))
          updated)
         ((raw-make-map
           (raw-map-equality validated))
          updated)))))))
