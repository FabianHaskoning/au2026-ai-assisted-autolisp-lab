;; circle-at-point.lsp
;; Asks you to pick one point, then draws a circle of radius 10 there.
;; The first example that actually changes the drawing - run it on a
;; scratch drawing, not on real work.
;;
;; Load it:  APPLOAD in AutoCAD, browse to this file, Load, Close.
;; Run it:   type CIRCLEHERE at the AutoCAD command line.
;;
;; Note the *error* handler: if you press Esc halfway through, it still
;; puts CMDECHO back the way it found it. Every routine you write today
;; should do the same - see .continue/rules/05-autolisp-safety-practices.md.

(defun c:CIRCLEHERE ( / *error* old-cmdecho centre)

  (defun *error* (msg)
    (if old-cmdecho (setvar "CMDECHO" old-cmdecho))
    (if (not (member msg '("Function cancelled" "quit / exit abort")))
      (princ (strcat "\nCIRCLEHERE stopped: " msg))
    )
    (princ)
  )

  (setq old-cmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)

  (setq centre (getpoint "\nPick the centre of the circle: "))
  (if centre
    (command "._CIRCLE" centre 10.0)
    (princ "\nNo point picked - nothing was drawn.")
  )

  (setvar "CMDECHO" old-cmdecho)
  (princ)
)

(princ "\nCIRCLEHERE loaded. Type CIRCLEHERE to run it.")
(princ)
