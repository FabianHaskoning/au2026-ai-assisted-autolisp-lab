;; well-behaved-command.lsp
;; A "well-behaved" AutoCAD command - the standard your instruction file
;; should push every AI-generated routine toward. Compare what the AI gives
;; you *before* and *after* your rules file against this specimen.
;; Extracted (and simplified) from rdb-command.lsp in the roundabout
;; showcase, C:\LabWork\showcase\roundabout\.
;;
;; Load it:  APPLOAD in AutoCAD, browse to this file, Load, Close.
;; Run it:   type RINGS at the AutoCAD command line.
;;
;; What makes it well-behaved:
;;   1. It saves every system variable it changes, and restores them on BOTH
;;      the normal exit path and the error path (*error* handler).
;;   2. It validates input and says what's wrong instead of crashing.
;;   3. It offers a remembered default, so Enter repeats your last choice.
;;   4. It reports what it did when it's done.

(setq *rings-count* 3)   ; remembered number of rings between runs

(defun c:RINGS ( / *error* old-cmdecho old-osmode n spacing centre i drawn)

  ;; Runs on Esc or any error: put the system variables back first.
  (defun *error* (msg)
    (if old-cmdecho (setvar "CMDECHO" old-cmdecho))
    (if old-osmode (setvar "OSMODE" old-osmode))
    (if (not (member msg '("Function cancelled" "quit / exit abort")))
      (princ (strcat "\nRINGS stopped: " msg))
    )
    (princ)
  )

  (setq old-cmdecho (getvar "CMDECHO")
        old-osmode  (getvar "OSMODE"))
  (setvar "CMDECHO" 0)

  ;; Number of rings: initget 6 rejects zero and negative numbers,
  ;; Enter accepts the remembered default shown in the prompt.
  (initget 6)
  (setq n (getint (strcat "\nNumber of rings <" (itoa *rings-count*) ">: ")))
  (if n (setq *rings-count* n) (setq n *rings-count*))

  (initget 6)
  (setq spacing (getreal "\nSpacing between rings <2.0>: "))
  (if (null spacing) (setq spacing 2.0))

  ;; Keep picking centre points until the user presses Enter.
  (setvar "OSMODE" 0)
  (setq drawn 0)
  (while (setq centre (getpoint "\nPick a centre point (Enter = done): "))
    (setq i 1)
    (repeat n
      (command "._CIRCLE" centre (* i spacing))
      (setq i (1+ i))
    )
    (setq drawn (1+ drawn))
  )

  (setvar "CMDECHO" old-cmdecho)
  (setvar "OSMODE" old-osmode)
  (princ (strcat "\nRINGS: drew " (itoa n) " ring(s) at "
                 (itoa drawn) " point(s)."))
  (princ)
)

(princ "\nRINGS loaded. Type RINGS to run it.")
(princ)
