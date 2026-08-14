;; hello-world.lsp
;; The smallest useful AutoLISP routine there is. Nothing is drawn and
;; nothing in your drawing changes - it only prints a line of text.
;;
;; Load it:  APPLOAD in AutoCAD, browse to this file, Load, Close.
;; Run it:   type HELLO at the AutoCAD command line.

(defun c:HELLO ()
  (princ "\nHello from AutoLISP - you just ran your own routine.")
  (princ "\nType HELLO again any time.")
  (princ)          ; clean exit - stops AutoCAD printing "nil" afterwards
)

(princ "\nHELLO loaded. Type HELLO to run it.")
(princ)
