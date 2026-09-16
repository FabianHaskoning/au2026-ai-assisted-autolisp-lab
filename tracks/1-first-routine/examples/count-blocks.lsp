;; count-blocks.lsp
;; Counts every block reference in the drawing and reports the total.
;; Read-only - it selects things but changes nothing, so it is safe to
;; run on any drawing.
;;
;; Load it:  APPLOAD in AutoCAD, browse to this file, Load, Close.
;; Run it:   type COUNTBLOCKS at the AutoCAD command line.
;;
;; This is the shape most useful routines start from: select a set of
;; entities, then do something with them. Here the "something" is just
;; counting - ask the assistant to change that and you have a new tool.

(defun c:COUNTBLOCKS ( / selection total)
  ;; "_X" searches the whole drawing, not just what is on screen.
  ;; '((0 . "INSERT")) filters it down to block references only.
  (setq selection (ssget "_X" '((0 . "INSERT"))))
  (setq total (if selection (sslength selection) 0))

  (princ (strcat "\nThis drawing contains " (itoa total) " block reference(s)."))
  (princ)
)

(princ "\nCOUNTBLOCKS loaded. Type COUNTBLOCKS to run it.")
(princ)
