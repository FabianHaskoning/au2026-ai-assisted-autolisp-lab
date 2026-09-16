;; eg-select.lsp - selecting features through the ArcGIS for AutoCAD plugin.
;;
;; Loaded by: eg-loader.lsp (never load this file on its own).
;; Defines no commands. Needs eg-util.lsp.
;;
;; This is the file that ties the whole showcase to something outside
;; AutoCAD. esri_featurelayer_select is not an AutoLISP function and it is not
;; in this folder - it arrives with the ArcGIS for AutoCAD plugin. Without
;; that plugin the routine cannot work at all, so it is checked for by name
;; rather than left to fail with "no function definition".

;; Is the ArcGIS for AutoCAD plugin loaded in this session?
(defun eg:arcgis-available-p ()
  (if (member "ESRI_FEATURELAYER_SELECT" (atoms-family 1)) T nil)
)

;; Select every feature in 'flname' whose 'field' equals 'value'.
;; Returns a selection set, or nil.
(defun eg:select-by-value (flname field value)
  (if (eg:arcgis-available-p)
    (esri_featurelayer_select
      flname
      ""                                  ; no spatial filter - attributes only
      (list (cons "ATTRIBUTEQUERY" (eg:query field value)))
    )
    (progn
      (princ "\nArcGIS for AutoCAD is not loaded, so no features can be selected.")
      nil
    )
  )
)

(princ "\n  eg-select.lsp loaded")
(princ)
