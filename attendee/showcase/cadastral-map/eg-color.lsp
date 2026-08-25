;; eg-color.lsp - TrueColor objects, layer creation, and clearing a layer.
;;
;; Loaded by: eg-loader.lsp (never load this file on its own).
;; Defines no commands.
;;
;; Two things here are worth noticing:
;;   1. A colour is a COM object. You create it, you use it, and you release
;;      it. The routine that calls eg:make-color owns it and must call
;;      eg:release-color when it is done - one colour per class, not one per
;;      entity, or a big drawing leaves thousands of objects behind.
;;   2. eg:clear-layer deletes drawing content, so it counts first, says what
;;      it found, and asks. Nothing here removes anything you did not confirm.

;; Create a TrueColor object for r/g/b. Returns nil if AutoCAD refuses.
;; Whoever calls this must call eg:release-color on the result.
(defun eg:make-color (r g b / acad ver col)
  (setq acad (vlax-get-acad-object))
  ;; "25.0s (LMS Tech)" -> "25". AcCmColor is versioned, so the interface
  ;; name has to match the running AutoCAD.
  (setq ver (substr (getvar "ACADVER") 1 2))
  (setq col (vl-catch-all-apply 'vla-GetInterfaceObject
                                (list acad (strcat "AutoCAD.AcCmColor." ver))))
  (if (vl-catch-all-error-p col)
    (progn
      (princ (strcat "\nCould not create a colour object for AutoCAD version " ver "."))
      nil
    )
    (progn (vla-SetRGB col r g b) col)
  )
)

;; Hand a colour object back to AutoCAD.
(defun eg:release-color (col)
  (if col (vl-catch-all-apply 'vlax-release-object (list col)))
  nil
)

;; Apply an already-made colour object to one entity.
(defun eg:color-entity (ename col)
  (if col
    (vla-put-TrueColor (vlax-ename->vla-object ename) col)
  )
)

;; Find the layer, or create it, and give it this colour. Returns the layer.
(defun eg:ensure-layer (name r g b / doc layers layer col)
  (setq doc    (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq layers (vla-get-Layers doc))
  (setq layer  (vl-catch-all-apply 'vla-Item (list layers name)))
  (if (vl-catch-all-error-p layer) (setq layer (vla-Add layers name)))
  (setq col (eg:make-color r g b))
  (if col
    (progn
      (vl-catch-all-apply 'vla-put-TrueColor (list layer col))
      (eg:release-color col)
    )
  )
  layer
)

;; Delete everything on a layer - after saying how much that is and asking.
;; Returns the number of objects deleted (0 if the user said no).
(defun eg:clear-layer (name / ss n i answer)
  (setq ss (ssget "X" (list (cons 8 name))) n 0)
  (if ss
    (progn
      (initget "Yes No")
      (setq answer (getkword
                     (strcat "\nLayer " name " already holds " (itoa (sslength ss))
                             " object(s) from an earlier run. Delete them? [Yes/No] <No>: ")))
      (if (= answer "Yes")
        (progn
          (setq i 0)
          (while (< i (sslength ss))
            (entdel (ssname ss i))
            (setq i (1+ i))
          )
          (setq n (sslength ss))
          (princ (strcat "\nDeleted " (itoa n) " object(s) from layer " name "."))
        )
        (princ (strcat "\nKept the existing objects on layer " name " - new hatches will be added on top."))
      )
    )
  )
  n
)

(princ "\n  eg-color.lsp loaded")
(princ)
