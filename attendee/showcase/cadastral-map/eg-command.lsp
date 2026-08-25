;; eg-command.lsp - the command that ties the showcase together.
;;
;; Loaded by: eg-loader.lsp (never load this file on its own).
;; Run it:    type EGMAP at the AutoCAD command line.
;;
;; What it does, in order:
;;   1. asks which feature layer, which field, and which service URL
;;   2. downloads the service definition and reads its colour classes
;;   3. makes sure the hatch layer exists, and offers to clear it
;;   4. per class: selects the matching features, recolours them, and puts a
;;      solid fill behind each closed one
;;   5. pushes all the new fills to the back and reports the totals
;;
;; It changes your drawing, so it is wrapped the way anything that changes a
;; drawing should be: one undo mark around the whole run, an *error* handler
;; that puts CMDECHO back if you press Esc, and no deletion without a
;; question first.

;; Remembered between runs - Enter at each prompt keeps the current value.
(setq *eg-url*          "https://maps.prorail.nl/arcgis/rest/services/Kadastraal/MapServer/5?f=pjson")
(setq *eg-feature-layer* "Eigendomskaart")
(setq *eg-field*        "PERCEELSCORE")
(setq *eg-hatch-layer*  "EIGENDOMSKAART_HATCH")

;; Handle one renderer class: (value r g b).
;; One colour object is made here and released here - not once per entity.
(defun eg:process-class (flname field hatch-layer item all-hatches
                         / value r g b col ss i e h n-color n-hatch)
  (setq value (nth 0 item)
        r     (nth 1 item)
        g     (nth 2 item)
        b     (nth 3 item))
  (setq ss (eg:select-by-value flname field value))
  (setq n-color 0 n-hatch 0)
  (if ss
    (progn
      (setq col (eg:make-color r g b))
      (setq i 0)
      (while (< i (sslength ss))
        (setq e (ssname ss i))
        ;; One bad entity must not stop the whole run.
        (vl-catch-all-apply 'eg:color-entity (list e col))
        (setq n-color (1+ n-color))
        (setq h (vl-catch-all-apply 'eg:hatch-boundary (list e hatch-layer col)))
        (if (and h (not (vl-catch-all-error-p h)))
          (progn
            (ssadd h all-hatches)
            (setq n-hatch (1+ n-hatch))
          )
        )
        (setq i (1+ i))
      )
      (eg:release-color col)
      (princ (strcat "\n  " field "=" value " -> coloured " (itoa n-color)
                     ", filled " (itoa n-hatch)))
    )
    (princ (strcat "\n  " field "=" value " -> no features"))
  )
)

(defun c:EGMAP ( / *error* old-cmdecho doc undo-open inp classes all-hatches)

  ;; Runs on Esc or on any error. Close the undo mark and put CMDECHO back,
  ;; so an interrupted run is still one single U away from where you started.
  (defun *error* (msg)
    (if (and doc undo-open) (vl-catch-all-apply 'vla-EndUndoMark (list doc)))
    (if old-cmdecho (setvar "CMDECHO" old-cmdecho))
    (if (not (member msg '("Function cancelled" "quit / exit abort")))
      (princ (strcat "\nEGMAP stopped: " msg))
    )
    (princ)
  )

  (if (not (eg:arcgis-available-p))
    (progn
      (princ "\nEGMAP needs the ArcGIS for AutoCAD plugin, and it is not loaded in this session.")
      (princ "\nInstall it from Autodesk App Store, restart AutoCAD, then try again.")
      (princ)
    )
    (progn
      (setq inp (getstring T (strcat "\nFeature layer name <" *eg-feature-layer* ">: ")))
      (if (/= inp "") (setq *eg-feature-layer* inp))
      (setq inp (getstring T (strcat "\nRenderer field <" *eg-field* ">: ")))
      (if (/= inp "") (setq *eg-field* inp))
      (setq inp (getstring T (strcat "\nService metadata URL <" *eg-url* ">: ")))
      (if (/= inp "") (setq *eg-url* inp))

      (princ "\nAsking the service which colour classes it uses...")
      (setq classes (eg:get-renderer-classes *eg-url*))

      (if (null classes)
        (princ "\nNo colour classes came back, so there is nothing to draw. Check the URL and your network access.")
        (progn
          (princ (strcat "\nColour classes found: " (itoa (length classes))))

          (setq old-cmdecho (getvar "CMDECHO"))
          (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
          (vla-StartUndoMark doc)
          (setq undo-open T)
          (setvar "CMDECHO" 0)

          (eg:ensure-layer *eg-hatch-layer* 250 249 175)
          (eg:clear-layer *eg-hatch-layer*)

          (setq all-hatches (ssadd))
          (foreach item classes
            (eg:process-class *eg-feature-layer* *eg-field* *eg-hatch-layer*
                              item all-hatches)
          )
          (eg:hatches-to-back all-hatches)

          (setvar "CMDECHO" old-cmdecho)
          (vla-EndUndoMark doc)
          (setq undo-open nil)

          (princ (strcat "\nFinished. " (itoa (sslength all-hatches))
                         " fill(s) on layer " *eg-hatch-layer*
                         ". One U undoes the whole run."))
        )
      )
      (princ)
    )
  )
)

;; The name this routine had before it was shortened. Kept so anyone with the
;; old name in a script or a menu macro still finds it.
(defun c:EIGENDOMSKAART_RENDERER_HATCH () (c:EGMAP))

(princ "\n  eg-command.lsp loaded")
(princ)
