;;; EG_01_Utilities.lsp
;;; Shared utility functions for Eigendomskaart renderer scripts.

(vl-load-com)

(defun eg:trim (s) (if s (vl-string-trim " \t\r\n\"'" s) ""))
(defun eg:at (s p) (substr s p 1))
(defun eg:blankp (ch) (member (ascii ch) '(9 10 13 32)))

(defun eg:rep (s old new / p)
  (while (setq p (vl-string-search old s))
    (setq s (strcat (substr s 1 p) new (substr s (+ p (strlen old) 1)))))
  s)

(defun eg:numstrp (s / i ch ok)
  (setq s (eg:trim s) i 1 ok (> (strlen s) 0))
  (while (and ok (<= i (strlen s)))
    (setq ch (substr s i 1))
    (if (not (wcmatch ch "[0-9.-]")) (setq ok nil))
    (setq i (1+ i)))
  ok)

(defun eg:query (field value)
  (if (eg:numstrp value)
    (strcat field " = " value)
    (strcat field " = '" value "'")))

(princ "\nLoaded EG_01_Utilities.lsp")
(princ)
