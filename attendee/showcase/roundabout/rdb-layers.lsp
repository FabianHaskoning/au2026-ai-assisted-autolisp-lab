;;; ============================================================================
;;;  rdb-layers.lsp  -  Layers (truecolor, matching the design legend)
;;; ============================================================================

;; Create a layer with truecolor, only if it does not exist yet.
(defun rdb-ensure-layer (name r g b aci)
  (if (not (tblsearch "LAYER" name))
    (entmake
      (list '(0 . "LAYER")
            '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbLayerTableRecord")
            (cons 2 name) '(70 . 0)
            (cons 62 aci)                  ; ACI fallback (positive = on)
            (cons 420 (rdb-rgb r g b))     ; truecolor per the legend
            '(6 . "Continuous")))))

;; All roundabout layers (colors approximate the design-standard legend).
(defun rdb-all-layers ()
  (rdb-ensure-layer "RDB-Carriageway"   127 127 127   8)   ; asphalt - grey
  (rdb-ensure-layer "RDB-Mountable"     150  90  90  14)   ; mountable apron - brick red
  (rdb-ensure-layer "RDB-Splitter"      150  90  90  14)   ; splitter island - same
  (rdb-ensure-layer "RDB-CentralIsland" 150 200 120  92)   ; verge - light green
  (rdb-ensure-layer "RDB-Verge"         150 200 120  92)   ; verge - light green
  (rdb-ensure-layer "RDB-CyclePath"     170  70  50  12)   ; cycle path - red
  (rdb-ensure-layer "RDB-Marking"       255 255 255   7)   ; marking - white
  (rdb-ensure-layer "RDB-Kerb"           64  64  64 250)   ; edges - dark grey
  (rdb-ensure-layer "RDB-Centreline"     80  80  80 251))  ; center mark - grey

(princ)
