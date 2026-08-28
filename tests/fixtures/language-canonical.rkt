#lang alone_the_lambdas

(def choose x condition =
  (if condition
      (cons x NIL)
      NIL))

(def selected =
  (choose "λ🙂" TRUE))

(stdout
 (if (IS-NIL (TAIL selected))
     (HEAD selected)
     "wrong"))
