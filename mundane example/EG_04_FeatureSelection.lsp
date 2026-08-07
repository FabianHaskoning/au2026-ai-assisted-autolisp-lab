;;; EG_04_FeatureSelection.lsp
;;; ArcGIS for AutoCAD feature selection by PERCEELSCORE value.

(defun eg:select-perceelscore (flname field value)
  (esri_featurelayer_select
    flname
    ""
    (list (cons "ATTRIBUTEQUERY" (eg:query field value)))))

(princ "\nLoaded EG_04_FeatureSelection.lsp")
(princ)
