;;; ============================================================================
;;;  eg-loader.lsp  -  Loader for the cadastral-map showcase
;;; ----------------------------------------------------------------------------
;;;  This is the only file you load (APPLOAD or Startup Suite). It loads the
;;;  modules in the order they depend on each other and then defines EGMAP.
;;;
;;;  Modules (same folder): eg-util, eg-service, eg-color, eg-select,
;;;  eg-hatch, eg-command.
;;;
;;;  EGMAP also needs the ArcGIS for AutoCAD plugin and internet access to the
;;;  map service. See README.md in this folder before you try to run it.
;;; ============================================================================

(vl-load-com)

;; Load all modules from folder 'dir' (or via the support search path if
;; dir = nil). Returns T when everything loaded, otherwise nil.
(defun eg--load-from (dir / mods p ok)
  (setq mods '("eg-util.lsp" "eg-service.lsp" "eg-color.lsp" "eg-select.lsp"
               "eg-hatch.lsp" "eg-command.lsp")
        ok T)
  (foreach m mods
    (setq p (if dir (strcat dir "\\" m) (findfile m)))
    (if (and p (findfile p))
      (load p)
      (progn (setq ok nil)
             (princ (strcat "\nEGMAP: module not found: " m)))))
  ok)

;; 1) try via the support search path (the folder holding eg-util.lsp).
(setq eg--dir (if (findfile "eg-util.lsp")
                  (vl-filename-directory (findfile "eg-util.lsp"))))

;; 2) fallback: ask the user once to point at eg-util.lsp.
(or (eg--load-from eg--dir)
    (progn
      (princ "\nModules not found on the search path. Point at eg-util.lsp...")
      (setq eg--f (getfiled "Select eg-util.lsp" "" "lsp" 0))
      (if eg--f
        (eg--load-from (vl-filename-directory eg--f))
        (princ "\nEGMAP not loaded."))))

(if (member "C:EGMAP" (atoms-family 1))
  (princ "\nEGMAP loaded. Type EGMAP to run it - it needs the ArcGIS for AutoCAD plugin.")
  (princ "\nEGMAP NOT fully loaded - check the module files."))
(princ)
