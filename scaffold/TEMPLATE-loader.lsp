;;; ---------------------------------------------------------------------
;;; prefix-loader.lsp
;;;
;;; Loader for the "prefix" routine. This is the ONLY file you load via
;;; APPLOAD (or put in the Startup Suite) - it just loads the other
;;; module files below and reports success or failure. Don't put any
;;; real logic in this file.
;;;
;;; If it can't find the module files it will ask you to point at
;;; prefix-util.lsp once, and load the rest from that same folder.
;;; ---------------------------------------------------------------------

;; Load one module from 'dir', or from the support search path if dir is
;; nil. Returns T when it loaded, nil when the file wasn't found.
(defun prefix-load-module (dir moduleFileName / modulePath)
  (setq modulePath (if dir (strcat dir "\\" moduleFileName) (findfile moduleFileName)))
  (if (and modulePath (findfile modulePath))
    (progn (load modulePath) T)
    (progn
      (princ (strcat "\nprefix: could not find " moduleFileName))
      nil
    )
  )
)

;; Load every module from 'dir'. Returns T only if all of them loaded.
(defun prefix-load-all (dir / ok)
  (setq ok T)
  (foreach m '("prefix-util.lsp" "prefix-core.lsp" "prefix-command.lsp")
    (if (not (prefix-load-module dir m)) (setq ok nil))
  )
  ok
)

;; 1) Try the support search path (the folder holding prefix-util.lsp).
(setq prefix-dir (if (findfile "prefix-util.lsp")
                   (vl-filename-directory (findfile "prefix-util.lsp"))))

;; 2) Fall back to asking once, rather than leaving you with an error.
(or (prefix-load-all prefix-dir)
    (progn
      (princ "\nModules not found on the search path. Point at prefix-util.lsp...")
      (setq prefix-file (getfiled "Select prefix-util.lsp" "" "lsp" 0))
      (if prefix-file
        (prefix-load-all (vl-filename-directory prefix-file))
        (princ "\nprefix not loaded.")
      )
    )
)

(princ "\nprefix loaded.")
(princ)
