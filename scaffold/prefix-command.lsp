;;; ---------------------------------------------------------------------
;;; prefix-command.lsp
;;;
;;; The command(s) an attendee actually types in AutoCAD. Kept separate
;;; from prefix-core.lsp / prefix-util.lsp so anyone reading this
;;; routine can find the "front door" without reading everything else
;;; first.
;;;
;;; Rename c:PLACEHOLDER to the real command name once you know it
;;; (uppercase, short, memorable).
;;; ---------------------------------------------------------------------

(defun c:PLACEHOLDER (/ *error* oldFillMode)

  (defun *error* (msg)
    ;; TODO: restore anything this command changed (system variables,
    ;; selection sets, etc.) here, on BOTH the error path and the
    ;; normal exit path below. See 05-autolisp-safety-practices.md.
    (if oldFillMode (setvar "FILLMODE" oldFillMode))
    (if (and msg (not (member msg '("Function cancelled" "quit / exit abort"))))
      (princ (strcat "\nprefix error: " msg))
    )
    (princ)
  )

  ;; Example of the save-before-change / restore-in-both-paths pattern
  ;; described in 05-autolisp-safety-practices.md. Remove if this
  ;; routine never needs to change a system variable.
  (setq oldFillMode (getvar "FILLMODE"))

  (prefix-run)

  (if oldFillMode (setvar "FILLMODE" oldFillMode))
  (princ)
)
