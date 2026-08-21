;;; ============================================================================
;;;  rdb-loader.lsp  -  Loader for the roundabout showcase
;;; ----------------------------------------------------------------------------
;;;  This is the only file you need to load (APPLOAD or Startup Suite).
;;;  It loads the modules, which together define the ROUNDABOUT command.
;;;
;;;  Modules (same folder): rdb-util, rdb-layers, rdb-core, rdb-arms,
;;;  rdb-cycle, rdb-connect, rdb-dialog, rdb-command.
;;;
;;;  Tip: add this folder to Options > Files > Support File Search Path,
;;;  then the loader finds the modules automatically.
;;; ============================================================================

(vl-load-com)

;; Load all modules from folder 'dir' (or via the support search path if
;; dir = nil). Returns T when everything loaded, otherwise nil.
(defun rdb--load-from (dir / mods p ok)
  (setq mods '("rdb-util.lsp" "rdb-layers.lsp" "rdb-core.lsp" "rdb-arms.lsp"
               "rdb-cycle.lsp" "rdb-connect.lsp" "rdb-dialog.lsp" "rdb-command.lsp")
        ok T)
  (foreach m mods
    (setq p (if dir (strcat dir "\\" m) (findfile m)))
    (if (and p (findfile p))
      (load p)
      (progn (setq ok nil)
             (princ (strcat "\nROUNDABOUT: module not found: " m)))))
  ok)

;; 1) try via the support search path (the folder holding rdb-util.lsp).
(setq rdb--dir (if (findfile "rdb-util.lsp")
                   (vl-filename-directory (findfile "rdb-util.lsp"))))

;; 2) fallback: ask the user once to point at rdb-util.lsp.
(or (rdb--load-from rdb--dir)
    (progn
      (princ "\nModules not found on the search path. Point at rdb-util.lsp...")
      (setq rdb--f (getfiled "Select rdb-util.lsp" "" "lsp" 0))
      (if rdb--f
        (rdb--load-from (vl-filename-directory rdb--f))
        (princ "\nROUNDABOUT not loaded."))))

(if (and (member "C:ROUNDABOUT" (atoms-family 1))
         (member "C:RDBCONNECT" (atoms-family 1)))
  (princ "\nROUNDABOUT loaded. Commands: ROUNDABOUT (draw a roundabout), RDBCONNECT (connect two roundabouts).")
  (princ "\nROUNDABOUT NOT fully loaded - check the module files."))
(princ)
