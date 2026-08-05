;;; ---------------------------------------------------------------------
;;; prefix-loader.lsp
;;;
;;; Loader for the "prefix" routine. This is the ONLY file you load via
;;; APPLOAD (or put in the Startup Suite) - it just loads the other
;;; module files below and reports success or failure. Don't put any
;;; real logic in this file.
;;;
;;; Rename this file to <yourprefix>-loader.lsp and replace every
;;; occurrence of "prefix" below with your own short prefix once you
;;; start a real routine (the New-Routine helper does this for you).
;;; ---------------------------------------------------------------------

(defun prefix-load-module (moduleFileName / modulePath)
  (setq modulePath (findfile moduleFileName))
  (if modulePath
    (load modulePath)
    (progn
      (princ (strcat "\nprefix: could not find " moduleFileName
                      " - make sure all module files stay in the same folder as this loader."))
      (princ)
    )
  )
)

(prefix-load-module "prefix-util.lsp")
(prefix-load-module "prefix-core.lsp")
(prefix-load-module "prefix-command.lsp")

(princ "\nprefix loaded.")
(princ)
