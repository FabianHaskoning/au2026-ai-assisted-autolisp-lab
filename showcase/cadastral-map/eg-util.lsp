;; eg-util.lsp - small string helpers for the cadastral-map showcase.
;;
;; Loaded by: eg-loader.lsp (never load this file on its own).
;; Defines no commands.
;;
;; Everything here exists to turn text that came out of a web service into
;; something the rest of the routine can use: trimmed strings, "is this a
;; number?", and a safely quoted attribute query.

(vl-load-com)

;; Strip whitespace and stray quote characters off both ends.
(defun eg:trim (s)
  (if s (vl-string-trim " \t\r\n\"'" s) "")
)

;; One character of s, 1-based. Used all over the JSON reader.
(defun eg:at (s p) (substr s p 1))

;; Is this character a space, tab, CR or LF?
(defun eg:blankp (ch) (member (ascii ch) '(9 10 13 32)))

;; Replace every occurrence of 'old' in s with 'new'.
;; Note it consumes s as it goes rather than re-scanning the result - a
;; re-scanning version loops forever when 'new' contains 'old'.
(defun eg:rep (s old new / p out)
  (setq out "")
  (while (setq p (vl-string-search old s))
    (setq out (strcat out (substr s 1 p) new)
          s   (substr s (+ p (strlen old) 1)))
  )
  (strcat out s)
)

;; Does this string look like a number? Digits, dots and minus signs only,
;; and at least one actual digit - so "-", "..." and "" are all rejected.
(defun eg:numstrp (s / n i ch ok digit)
  (setq s     (eg:trim s)
        n     (strlen s)
        i     1
        ok    (> n 0)
        digit nil)
  (while (and ok (<= i n))
    (setq ch (substr s i 1))
    (cond
      ((wcmatch ch "[0-9]") (setq digit T))
      ((wcmatch ch "[.-]"))
      (T (setq ok nil))
    )
    (setq i (1+ i))
  )
  (and ok digit)
)

;; Build an ArcGIS attribute query: FIELD = 123 or FIELD = 'text'.
;; Single quotes inside the value are doubled, which is how SQL-style
;; queries escape them - without this, a value containing an apostrophe
;; produces a query the service rejects.
(defun eg:query (field value)
  (if (eg:numstrp value)
    (strcat field " = " value)
    (strcat field " = '" (eg:rep value "'" "''") "'")
  )
)

(princ "\n  eg-util.lsp loaded")
(princ)
