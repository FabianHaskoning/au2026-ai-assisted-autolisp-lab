;; make-layers.lsp
;; Creates four ready-to-use layers, each with a truecolor color - the kind
;; of thing you'd otherwise click together in the Layer Manager every time.
;; Extracted (and simplified) from the roundabout showcase in
;; C:\LabWork\showcase\roundabout\.
;;
;; Load it:  APPLOAD in AutoCAD, browse to this file, Load, Close.
;; Run it:   type MAKELAYERS at the AutoCAD command line.
;; See it:   open the layer dropdown - four new layers, already colored.
;;
;; The interesting part: entmake builds an entity (here: a layer table
;; record) from a plain list of dotted pairs. The tblsearch check makes the
;; routine safe to run twice - existing layers are left alone.

;; 24-bit truecolor value for DXF group code 420.
(defun rgb-value (r g b)
  (+ (* r 65536) (* g 256) b)
)

;; Create one layer, only if it does not exist yet.
;; name = layer name, r g b = truecolor, aci = fallback color index.
(defun ensure-layer (name r g b aci)
  (if (tblsearch "LAYER" name)
    nil                                  ; already there - leave it alone
    (entmake
      (list
        '(0 . "LAYER")
        '(100 . "AcDbSymbolTableRecord")
        '(100 . "AcDbLayerTableRecord")
        (cons 2 name)                    ; layer name
        '(70 . 0)                        ; not frozen/locked
        (cons 62 aci)                    ; classic color (fallback)
        (cons 420 (rgb-value r g b))     ; truecolor
        '(6 . "Continuous")              ; linetype
      )
    )
  )
)

(defun c:MAKELAYERS ( / made)
  (setq made 0)
  (foreach spec '(("Roads"     127 127 127   8)
                  ("Cycleways" 170  70  50  12)
                  ("Green"     150 200 120  92)
                  ("Markings"  255 255 255   7))
    (if (apply 'ensure-layer spec)
      (setq made (1+ made))
    )
  )
  (princ (strcat "\nMAKELAYERS: " (itoa made) " layer(s) created, "
                 (itoa (- 4 made)) " already existed."))
  (princ)
)

(princ "\nMAKELAYERS loaded. Type MAKELAYERS to run it.")
(princ)
