;;; EG_06_Main.lsp
;;; Main command. Load files EG_01 to EG_05 first, then load this file.

(setq eg:url "https://maps.prorail.nl/arcgis/rest/services/Kadastraal/MapServer/5?f=pjson")
(setq eg:flname "Eigendomskaart")
(setq eg:field "PERCEELSCORE")
(setq eg:hatchLayer "EIGENDOMSKAART_HATCH")

(defun eg:process-perceelscore (flname field hatchLayer item allHatches / value r g b ss i e h nColor nHatch)
  (setq value (nth 0 item))
  (setq r (nth 1 item))
  (setq g (nth 2 item))
  (setq b (nth 3 item))
  (setq ss (eg:select-perceelscore flname field value))
  (setq nColor 0 nHatch 0)
  (if ss
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq e (ssname ss i))
        (vl-catch-all-apply 'eg:color-entity (list e r g b))
        (setq nColor (1+ nColor))
        (setq h (vl-catch-all-apply 'eg:hatch-boundary (list e hatchLayer r g b)))
        (if (and h (not (vl-catch-all-error-p h)))
          (progn
            (ssadd h allHatches)
            (setq nHatch (1+ nHatch))))
        (setq i (1+ i)))
      (princ (strcat "\n" field "=" value " -> colored " (itoa nColor) ", hatches " (itoa nHatch))))
    (princ (strcat "\nNo features for " field "=" value)))
  (setq ss nil))

(defun c:EIGENDOMSKAART_RENDERER_HATCH (/ inp renderer item allHatches)
  (setq inp (getstring T (strcat "\nFeature layer name <" eg:flname ">: ")))
  (if (/= inp "") (setq eg:flname inp))
  (setq inp (getstring T (strcat "\nRenderer field <" eg:field ">: ")))
  (if (/= inp "") (setq eg:field inp))
  (setq inp (getstring T (strcat "\nREST metadata URL <" eg:url ">: ")))
  (if (/= inp "") (setq eg:url inp))

  (eg:ensure-layer eg:hatchLayer 250 249 175)
  (setq renderer (eg:get-perceelscore-renderer eg:url))
  (if renderer
    (progn
      (princ (strcat "\nRenderer classes found: " (itoa (length renderer))))
      (eg:clear-layer eg:hatchLayer)
      (setq allHatches (ssadd))
      (foreach item renderer
        (eg:process-perceelscore eg:flname eg:field eg:hatchLayer item allHatches))
      (eg:hatches-to-back allHatches)
      (princ (strcat "\nFinished. Total hatches: " (itoa (sslength allHatches))))
      (setq allHatches nil))
    (princ "\nNo renderer classes found. Check the URL or service access."))
  (princ))

(princ "\nLoaded EG_06_Main.lsp")
(princ "\nCommand loaded: EIGENDOMSKAART_RENDERER_HATCH")
(princ)
