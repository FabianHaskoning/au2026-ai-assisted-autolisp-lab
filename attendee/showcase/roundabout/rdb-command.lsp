;;; ============================================================================
;;;  rdb-command.lsp  -  The ROUNDABOUT command (orchestration)
;;; ----------------------------------------------------------------------------
;;;  Load-order dependent: requires rdb-util, rdb-layers, rdb-core,
;;;  rdb-arms, rdb-cycle and rdb-dialog.
;;; ============================================================================

(defun c:ROUNDABOUT ( / *error* dcl_id dcl_file result P pp arms i ang gap ap
                        mouth mouths old_cmdecho old_osmode old_fillmode
                        Rb Ri Ro we wx wm Ls Re Rx lArm verge wbike
                        doCycle doMark doDrop)

  (setq old_cmdecho  (getvar "CMDECHO")
        old_osmode   (getvar "OSMODE")
        old_fillmode (getvar "FILLMODE"))

  (defun *error* (msg)
    (if old_cmdecho  (setvar "CMDECHO"  old_cmdecho))
    (if old_osmode   (setvar "OSMODE"   old_osmode))
    (if old_fillmode (setvar "FILLMODE" old_fillmode))
    (if (and dcl_id (>= dcl_id 0)) (unload_dialog dcl_id))
    (if (and dcl_file (findfile dcl_file)) (vl-file-delete dcl_file))
    (if (and msg (/= msg "Function cancelled") (/= msg "quit / exit abort"))
        (princ (strcat "\nError: " msg)))
    (princ))

  ;; --- dialog ---
  (setq dcl_file (rdb-write-dcl) dcl_id (load_dialog dcl_file))
  (if (< dcl_id 0)
    (progn (princ "\nCould not load the DCL.")
           (if (findfile dcl_file) (vl-file-delete dcl_file)) (exit)))
  (if (not (new_dialog "roundabout" dcl_id))
    (progn (unload_dialog dcl_id) (setq dcl_id nil)
           (if (findfile dcl_file) (vl-file-delete dcl_file))
           (princ "\nCould not open the dialog.") (exit)))

  ;; initial values (rural + standard defaults)
  (set_tile "eb_rb" "18.00") (set_tile "eb_ri" "12.75") (set_tile "eb_ro" "9.75")
  (set_tile "rb_rural" "1")
  (set_tile "eb_we" "4.00")  (set_tile "eb_wx" "4.50")  (set_tile "eb_wm" "4.00")
  (set_tile "eb_ls" "15.00") (set_tile "eb_re" "12.00") (set_tile "eb_rx" "12.00")
  (set_tile "eb_larm" "25.00")
  (set_tile "eb_verge" "2.00") (set_tile "eb_wbike" "2.50")
  (set_tile "cb_cycle" "1") (set_tile "cb_mark" "1") (set_tile "cb_drop" "1")
  (rdb-refresh-readonly)

  (action_tile "rb_urban"
    "(set_tile \"eb_rb\" \"16.00\")(set_tile \"eb_ri\" \"10.50\")(set_tile \"eb_ro\" \"7.50\")(rdb-refresh-readonly)")
  (action_tile "rb_rural"
    "(set_tile \"eb_rb\" \"18.00\")(set_tile \"eb_ri\" \"12.75\")(set_tile \"eb_ro\" \"9.75\")(rdb-refresh-readonly)")
  (action_tile "eb_rb" "(rdb-refresh-readonly)")
  (action_tile "eb_ri" "(rdb-refresh-readonly)")
  (action_tile "eb_ro" "(rdb-refresh-readonly)")
  (action_tile "accept" "(rdb-read-values)(done_dialog 1)")
  (action_tile "cancel" "(done_dialog 0)")

  (setq result (start_dialog))
  (unload_dialog dcl_id) (setq dcl_id nil)
  (if (findfile dcl_file) (vl-file-delete dcl_file))

  ;; --- drawing ---
  (if (= result 1)
    (if (not (and (> Ro 0.0) (> Ri Ro) (> Rb Ri)
                  (> we 0.0) (> wx 0.0) (> wm 0.0) (> Ls 0.0)
                  (> Re 0.0) (> Rx 0.0) (> lArm 0.0) (> verge 0.0) (> wbike 0.0)
                  (< (+ we wm wx) (* 2.0 Rb))))
      (alert "Invalid dimensions.\n\nRequired: Rb > Ri > Ro > 0, all arm/cycle sizes > 0,\nand entry+splitter+exit < 2*outer radius.")
      (progn
        (setvar "CMDECHO" 0) (setvar "OSMODE" 0)
        (setq P (getpoint "\nPick the roundabout center point: "))
        (if (null P)
          (princ "\nNo center point - cancelled.")
          (progn
            ;; point out the arm directions
            (setq arms '() i 1)
            (while (setq pp (getpoint P (strcat "\nDirection of arm " (itoa i) " (Enter = done): ")))
              (setq arms (cons (angle P pp) arms) i (1+ i)))
            (setq arms (reverse arms))
            ;; draw: fills first, then edges
            (rdb-all-layers)
            (setvar "FILLMODE" 1)
            (rdb-draw-core-fills P Rb Ri Ro)
            (setq gap 0.4
                  ap  (list we wx wm Ls Re Rx lArm gap doDrop)
                  mouths '())
            (foreach ang arms
              (setq mouth (rdb-draw-arm P ang Rb ap))
              (if mouth (setq mouths (cons mouth mouths))))
            (if doCycle (rdb-draw-cycle-ring P Rb verge wbike mouths doMark))
            (rdb-kerb-arcs P Rb mouths)
            (rdb-draw-core-edges P Rb Ri Ro)
            (command "._REGEN")
            (princ (strcat "\nRoundabout drawn: " (itoa (length arms)) " arm(s), "
                           "outer radius " (rtos Rb 2 2) " m"
                           (if doCycle " (with cycle ring)." ".")))))))
    (princ "\nCancelled."))

  (setvar "CMDECHO"  old_cmdecho)
  (setvar "OSMODE"   old_osmode)
  (setvar "FILLMODE" old_fillmode)
  (princ))

(princ)
