;;; EG_03_ColorLayer.lsp
;;; CAD TrueColor, layer creation and cleanup functions.

(defun eg:rgb (r g b / acad col ver)
  (setq acad (vlax-get-acad-object))
  (setq ver (substr (getvar "ACADVER") 1 2))
  (setq col (vla-GetInterfaceObject acad (strcat "AutoCAD.AcCmColor." ver)))
  (vla-SetRGB col r g b)
  col)

(defun eg:color-entity (ename r g b)
  (vla-put-TrueColor (vlax-ename->vla-object ename) (eg:rgb r g b)))

(defun eg:ensure-layer (name r g b / doc layers layer)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq layers (vla-get-Layers doc))
  (setq layer (vl-catch-all-apply 'vla-Item (list layers name)))
  (if (vl-catch-all-error-p layer) (setq layer (vla-Add layers name)))
  (vl-catch-all-apply 'vla-put-TrueColor (list layer (eg:rgb r g b)))
  layer)

(defun eg:clear-layer (name / ss i)
  (setq ss (ssget "X" (list (cons 8 name))))
  (if ss
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (entdel (ssname ss i))
        (setq i (1+ i)))
      (princ (strcat "\nDeleted existing hatches: " (itoa (sslength ss))))))
  (setq ss nil))

(princ "\nLoaded EG_03_ColorLayer.lsp")
(princ)
