#lang alone_the_lambdas

; Run this example in an empty scratch directory. It creates or replaces the
; relative file named below, then emits the bytes it reads back.
(def path = "alone-the-lambdas-round-trip.txt")
(def contents = "Alone the Lambdas file round trip.\n")

(let write-result = (write-file path contents)
  (if (is-ok write-result)
      (let read-result = (read-file path)
        (if (is-ok read-result)
            (stdout (unwrap-ok read-result))
            read-result))
      write-result))
