#lang s-exp "../macros/lazy-with-macros.rkt"

(require "../macros/macros.rkt"
         "binary-nat.rkt"
         "errors.rkt"
         "function-names.rkt"
         "lists.rkt"
         "logic.rkt"
         "objects.rkt"
         "tags.rkt"
         "typecheck.rkt"
         (only-in "rat.rkt"
                  raw-rat-is-nonnegative-whole
                  raw-rat-magnitude-bits))

(provide raw-make-char
         raw-char-value
         typed-make-char-rat
         typed-char-equal
         typed-char-less
         typed-char-less-equal
         typed-char-greater
         typed-char-greater-equal
         (rename-out [typed-make-char-rat MAKE-CHAR]
                     [typed-char-equal CHAR-EQ]
                     [typed-char-less CHAR-LT]
                     [typed-char-less-equal CHAR-LTE]
                     [typed-char-greater CHAR-GT]
                     [typed-char-greater-equal CHAR-GTE])
         A B C D E F G H I J K L M
         N O P Q R S T U V W X Y Z
         a b c d e f g h i j k l m
         n o p q r s t u v w x y z
         DIGIT-0 DIGIT-1 DIGIT-2 DIGIT-3 DIGIT-4
         DIGIT-5 DIGIT-6 DIGIT-7 DIGIT-8 DIGIT-9
         SPACE TAB CR LF
         DOT COMMA COLON SEMICOLON
         SLASH BACKSLASH HYPHEN UNDERSCORE
         QUESTION EQUAL AMPERSAND PERCENT HASH
         LEFT-PAREN RIGHT-PAREN
         LEFT-BRACKET RIGHT-BRACKET
         LEFT-BRACE RIGHT-BRACE)

(def raw-two-bits =
  (raw-nat-succ raw-one-bits))

(def raw-four-bits =
  ((raw-nat-add raw-two-bits) raw-two-bits))

(def raw-eight-bits =
  ((raw-nat-add raw-four-bits) raw-four-bits))

(def raw-nine-bits =
  (raw-nat-succ raw-eight-bits))

(def raw-ten-bits =
  (raw-nat-succ raw-nine-bits))

(def raw-sixteen-bits =
  ((raw-nat-add raw-eight-bits) raw-eight-bits))

(def raw-char-max-bits =
  ((raw-nat-sub
    ((raw-nat-mult raw-sixteen-bits)
     raw-sixteen-bits))
   raw-one-bits))

(def raw-make-char bits =
  ((raw-make-object char-type)
   (raw-normalize-nat bits)))

(def raw-char-value char =
  (raw-object-value char))

(def raw-make-checked-char bits =
  (lambda-let normalized =
    (raw-normalize-nat bits)
    (((raw-if
       ((raw-nat-less-equal normalized)
        raw-char-max-bits))
      (raw-make-char normalized))
     ((raw-add-result-frame invalid-char-error)
      make-char-function-name))))

(def char-binary-signature =
  ((raw-cons char-type)
   ((raw-cons char-type) NIL)))

;; The public constructor accepts a Rat since the Step 35.5 switch. The Rat
;; must be a nonnegative whole number; range checking stays on private
;; binary Nat bits.
(def raw-make-checked-char-rat rat =
  (((raw-if
     (raw-rat-is-nonnegative-whole rat))
    (raw-make-checked-char
     (raw-rat-magnitude-bits rat)))
   ((raw-add-result-frame invalid-count-error)
    make-char-function-name)))

(def char-rat-constructor-signature =
  ((raw-cons rat-type) NIL))

(def typed-make-char-rat =
  ((((make-typed-function raw-make-checked-char-rat)
     make-char-function-name)
    char-rat-constructor-signature)
   raw-keep-return))

(def typed-char-equal =
  ((((make-typed-function raw-nat-equal)
     char-eq-function-name)
    char-binary-signature)
   (raw-wrap-return bool-type)))

(def typed-char-less =
  ((((make-typed-function raw-nat-less)
     char-lt-function-name)
    char-binary-signature)
   (raw-wrap-return bool-type)))

(def typed-char-less-equal =
  ((((make-typed-function raw-nat-less-equal)
     char-lte-function-name)
    char-binary-signature)
   (raw-wrap-return bool-type)))

(def typed-char-greater =
  ((((make-typed-function raw-nat-greater)
     char-gt-function-name)
    char-binary-signature)
   (raw-wrap-return bool-type)))

(def typed-char-greater-equal =
  ((((make-typed-function raw-nat-greater-equal)
     char-gte-function-name)
    char-binary-signature)
   (raw-wrap-return bool-type)))

(def raw-char-succ char =
  (raw-make-char
   (raw-nat-succ
    (raw-char-value char))))

(def TAB =
  (raw-make-char raw-nine-bits))

(def LF =
  (raw-make-char raw-ten-bits))

(def CR =
  (raw-char-succ
   (raw-char-succ
    (raw-char-succ LF))))

(def SPACE =
  (raw-make-char
   ((raw-nat-mult raw-four-bits)
    raw-eight-bits)))

(def HASH =
  (raw-char-succ
   (raw-char-succ
    (raw-char-succ SPACE))))

(def PERCENT =
  (raw-char-succ
   (raw-char-succ HASH)))

(def AMPERSAND =
  (raw-char-succ PERCENT))

(def LEFT-PAREN =
  (raw-char-succ
   (raw-char-succ AMPERSAND)))

(def RIGHT-PAREN =
  (raw-char-succ LEFT-PAREN))

(def COMMA =
  (raw-char-succ
   (raw-char-succ
    (raw-char-succ RIGHT-PAREN))))

(def HYPHEN =
  (raw-char-succ COMMA))

(def DOT =
  (raw-char-succ HYPHEN))

(def SLASH =
  (raw-char-succ DOT))

(def DIGIT-0 =
  (raw-char-succ SLASH))

(def DIGIT-1 = (raw-char-succ DIGIT-0))
(def DIGIT-2 = (raw-char-succ DIGIT-1))
(def DIGIT-3 = (raw-char-succ DIGIT-2))
(def DIGIT-4 = (raw-char-succ DIGIT-3))
(def DIGIT-5 = (raw-char-succ DIGIT-4))
(def DIGIT-6 = (raw-char-succ DIGIT-5))
(def DIGIT-7 = (raw-char-succ DIGIT-6))
(def DIGIT-8 = (raw-char-succ DIGIT-7))
(def DIGIT-9 = (raw-char-succ DIGIT-8))

(def COLON =
  (raw-char-succ DIGIT-9))

(def SEMICOLON =
  (raw-char-succ COLON))

(def EQUAL =
  (raw-char-succ
   (raw-char-succ SEMICOLON)))

(def QUESTION =
  (raw-char-succ
   (raw-char-succ EQUAL)))

(def A =
  (raw-char-succ
   (raw-char-succ QUESTION)))

(def B = (raw-char-succ A))
(def C = (raw-char-succ B))
(def D = (raw-char-succ C))
(def E = (raw-char-succ D))
(def F = (raw-char-succ E))
(def G = (raw-char-succ F))
(def H = (raw-char-succ G))
(def I = (raw-char-succ H))
(def J = (raw-char-succ I))
(def K = (raw-char-succ J))
(def L = (raw-char-succ K))
(def M = (raw-char-succ L))
(def N = (raw-char-succ M))
(def O = (raw-char-succ N))
(def P = (raw-char-succ O))
(def Q = (raw-char-succ P))
(def R = (raw-char-succ Q))
(def S = (raw-char-succ R))
(def T = (raw-char-succ S))
(def U = (raw-char-succ T))
(def V = (raw-char-succ U))
(def W = (raw-char-succ V))
(def X = (raw-char-succ W))
(def Y = (raw-char-succ X))
(def Z = (raw-char-succ Y))

(def LEFT-BRACKET =
  (raw-char-succ Z))

(def BACKSLASH =
  (raw-char-succ LEFT-BRACKET))

(def RIGHT-BRACKET =
  (raw-char-succ BACKSLASH))

(def UNDERSCORE =
  (raw-char-succ
   (raw-char-succ RIGHT-BRACKET)))

(def a =
  (raw-char-succ
   (raw-char-succ UNDERSCORE)))

(def b = (raw-char-succ a))
(def c = (raw-char-succ b))
(def d = (raw-char-succ c))
(def e = (raw-char-succ d))
(def f = (raw-char-succ e))
(def g = (raw-char-succ f))
(def h = (raw-char-succ g))
(def i = (raw-char-succ h))
(def j = (raw-char-succ i))
(def k = (raw-char-succ j))
(def l = (raw-char-succ k))
(def m = (raw-char-succ l))
(def n = (raw-char-succ m))
(def o = (raw-char-succ n))
(def p = (raw-char-succ o))
(def q = (raw-char-succ p))
(def r = (raw-char-succ q))
(def s = (raw-char-succ r))
(def t = (raw-char-succ s))
(def u = (raw-char-succ t))
(def v = (raw-char-succ u))
(def w = (raw-char-succ v))
(def x = (raw-char-succ w))
(def y = (raw-char-succ x))
(def z = (raw-char-succ y))

(def LEFT-BRACE =
  (raw-char-succ z))

(def RIGHT-BRACE =
  (raw-char-succ
   (raw-char-succ LEFT-BRACE)))
