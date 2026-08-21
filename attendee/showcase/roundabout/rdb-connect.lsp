;;; ============================================================================
;;;  rdb-connect.lsp  -  Connect two roundabouts via a waypoint (RDBCONNECT)
;;; ----------------------------------------------------------------------------
;;;  Requires (load order): rdb-util, rdb-layers, rdb-arms (rdb-fill-fan,
;;;  rdb-proj-u, rdb-kerb-arcs, *rdb-nmouth*, *rdb-nfil*).
;;; ============================================================================

(setq *rdbc-rf* 12.0)   ; remembered entry/exit radius

;; Ascending, de-duplicated radius list (tolerance 1e-4).
(defun rdbc-distinct-sorted (lst / s out)
  (setq s (vl-sort lst '<) out '())
  (foreach r s
    (if (or (null out) (> (abs (- r (car out))) 1e-4))
      (setq out (cons r out))))
  (reverse out))

;; Select a roundabout via a circle/arc. Returns (c Rb Ri W kerbEnames) or nil.
;;   c = center, Rb = outer radius (3rd-smallest radius), Ri = 2nd-smallest,
;;   W = Rb-Ri, kerbEnames = the RDB-Kerb entities at radius ~Rb.
(defun rdbc-pick-roundabout (prompt / e ed ty cc c ss i en ed2 radii kerbs Rb Ri)
  (setq e (entsel prompt))
  (cond
    ((null e) (princ "\nNothing selected.") nil)
    ((not (member (cdr (assoc 0 (entget (car e)))) '("CIRCLE" "ARC")))
     (princ "\nPick a circle or arc (layer RDB-Kerb) of the roundabout.") nil)
    (T
     (setq ed (entget (car e))
           cc (cdr (assoc 10 ed)) c (list (car cc) (cadr cc))
           ss (ssget "_X" '((0 . "CIRCLE,ARC") (8 . "RDB-Kerb")))
           radii '() kerbs '())
     (if (null ss)
       (progn (princ "\nNo RDB-Kerb found.") nil)
       (progn
         (setq i 0)
         (repeat (sslength ss)
           (setq en (ssname ss i) ed2 (entget en) cc (cdr (assoc 10 ed2)))
           (if (< (distance c (list (car cc) (cadr cc))) 1e-4)
             (setq radii (cons (cdr (assoc 40 ed2)) radii)))
           (setq i (1+ i)))
         (setq radii (rdbc-distinct-sorted radii))
         (if (< (length radii) 3)
           (progn (princ "\nNo valid roundabout recognized (expected Ro < Ri < Rb).") nil)
           (progn
             (setq Ri (nth 1 radii) Rb (nth 2 radii) i 0)
             (repeat (sslength ss)
               (setq en (ssname ss i) ed2 (entget en) cc (cdr (assoc 10 ed2)))
               (if (and (< (distance c (list (car cc) (cadr cc))) 1e-4)
                        (< (abs (- (cdr (assoc 40 ed2)) Rb)) 1e-3))
                 (setq kerbs (cons en kerbs)))
               (setq i (1+ i)))
             (list c Rb Ri (- Rb Ri) kerbs))))))))

;; Existing mouths from the kerb entities. Full CIRCLE -> nil (no mouths);
;; ARCs -> complement of the arc spans.
(defun rdbc-read-kerb-mouths (kerbs / spans ed)
  (if (vl-some '(lambda (en) (= (cdr (assoc 0 (entget en))) "CIRCLE")) kerbs)
    nil
    (progn
      (setq spans '())
      (foreach en kerbs
        (setq ed (entget en))
        (if (= (cdr (assoc 0 ed)) "ARC")
          (setq spans (cons (cons (cdr (assoc 50 ed)) (cdr (assoc 51 ed))) spans))))
      (if spans (rdb-complement-spans spans)))))

;; Draw the flare into one roundabout (fill + fillet kerb arcs).
;; Returns (pA mouth) or nil when the fillet does not fit.
(defun rdbc-flare (c d W Rf Rb / sL sR flL flR TlL TcL OL TlR TcR OR aA pA bnd thL thR)
  (setq sL (/ W 2.0) sR (- (/ W 2.0))
        flL (rdb-fillet c d sL Rf Rb)
        flR (rdb-fillet c d sR Rf Rb))
  (if (and flL flR)
    (progn
      (setq TlL (nth 0 flL) TcL (nth 1 flL) thL (nth 2 flL) OL (nth 3 flL)
            TlR (nth 0 flR) TcR (nth 1 flR) thR (nth 2 flR) OR (nth 3 flR)
            aA  (rdb-proj-u c d TlL)
            pA  (rdb-loc c d aA 0.0)
            bnd (append
                  (rdb-arc-pts c Rb thR thL *rdb-nmouth*)
                  (cdr (rdb-arc-pts-short OL Rf (angle OL TcL) (angle OL TlL) *rdb-nfil*))
                  (rdb-arc-pts-short OR Rf (angle OR TlR) (angle OR TcR) *rdb-nfil*)))
      (rdb-fill-fan bnd "RDB-Carriageway")
      (rdb-make-arc-short OL Rf (angle OL TcL) (angle OL TlL) "RDB-Kerb")
      (rdb-make-arc-short OR Rf (angle OR TlR) (angle OR TcR) "RDB-Kerb")
      (list pA (cons thR thL)))))

;; Filled carriageway band with a kink at M.
(defun rdbc-draw-band (pA M pB W)
  (rdb-make-wpoly (list pA M pB) W nil "RDB-Carriageway"))

;; Kerb edges: offset of [pA,M,pB] by +/-W/2, mitred at M.
(defun rdbc-draw-edges (pA M pB W / hW n1 n2 cross lA1 lB1 rA1 rB1 apexL apexR)
  (setq hW (/ W 2.0)
        n1 (rdb-lnorm pA M) n2 (rdb-lnorm M pB)
        cross (- (* (car n1) (cadr n2)) (* (cadr n1) (car n2)))
        lA1 (rdb-off pA hW n1)        lB1 (rdb-off pB hW n2)
        rA1 (rdb-off pA (- hW) n1)    rB1 (rdb-off pB (- hW) n2))
  (if (< (abs cross) 1e-4)
    (setq apexL (rdb-off M hW n1) apexR (rdb-off M (- hW) n1))
    (setq apexL (inters lA1 (rdb-off M hW n1) (rdb-off M hW n2) lB1 nil)
          apexR (inters rA1 (rdb-off M (- hW) n1) (rdb-off M (- hW) n2) rB1 nil)))
  (if (null apexL) (setq apexL (rdb-off M hW n1)))
  (if (null apexR) (setq apexR (rdb-off M (- hW) n1)))
  (rdb-make-line lA1 apexL "RDB-Kerb")
  (rdb-make-line apexL lB1 "RDB-Kerb")
  (rdb-make-line rA1 apexR "RDB-Kerb")
  (rdb-make-line apexR rB1 "RDB-Kerb"))

;; Dashed centerline (3 m dash / 3 m gap) along p->q.
(defun rdbc-dash (p q / len ux uy t0 t1)
  (setq len (distance p q))
  (if (> len 1e-6)
    (progn
      (setq ux (/ (- (car q) (car p)) len) uy (/ (- (cadr q) (cadr p)) len) t0 0.0)
      (while (< t0 len)
        (setq t1 (min len (+ t0 3.0)))
        (rdb-make-line (list (+ (car p) (* ux t0)) (+ (cadr p) (* uy t0)))
                       (list (+ (car p) (* ux t1)) (+ (cadr p) (* uy t1))) "RDB-Marking")
        (setq t0 (+ t1 3.0))))))

(defun rdbc-draw-centerline (pA M pB)
  (rdbc-dash pA M) (rdbc-dash M pB))

;; Cut the connection mouth into a roundabout's kerb (replace the old kerb).
(defun rdbc-recut-kerb (c Rb kerbs newMouth / mouths)
  (setq mouths (rdbc-read-kerb-mouths kerbs))
  (foreach en kerbs (entdel en))
  (rdb-kerb-arcs c Rb (cons newMouth mouths)))

;;; ------------------------------------------------------------------ command
(defun c:RDBCONNECT ( / *error* old_cmdecho old_osmode old_fillmode
                        rA rB cA RbA RiA cB RbB kerbsA kerbsB W Rf
                        M dA dB resA resB pA pB mouthA mouthB)

  (setq old_cmdecho (getvar "CMDECHO") old_osmode (getvar "OSMODE")
        old_fillmode (getvar "FILLMODE"))
  (defun *error* (msg)
    (if old_cmdecho  (setvar "CMDECHO"  old_cmdecho))
    (if old_osmode   (setvar "OSMODE"   old_osmode))
    (if old_fillmode (setvar "FILLMODE" old_fillmode))
    (if (and msg (/= msg "Function cancelled") (/= msg "quit / exit abort"))
        (princ (strcat "\nError: " msg)))
    (princ))

  (setvar "CMDECHO" 0)
  (rdb-all-layers)
  (setq rA (rdbc-pick-roundabout "\nSelect the first roundabout (circle/arc): "))
  (if rA (setq rB (rdbc-pick-roundabout "\nSelect the second roundabout (circle/arc): ")))

  (if (and rA rB)
    (progn
      (setq cA (nth 0 rA) RbA (nth 1 rA) RiA (nth 2 rA) W (nth 3 rA) kerbsA (nth 4 rA)
            cB (nth 0 rB) RbB (nth 1 rB)                              kerbsB (nth 4 rB))
      (if (< (distance cA cB) 1e-3)
        (alert "Select two different roundabouts.")
        (progn
          (initget 6)
          (setq Rf (getreal (strcat "\nEntry/exit radius <" (rtos *rdbc-rf* 2 2) ">: ")))
          (if Rf (setq *rdbc-rf* Rf) (setq Rf *rdbc-rf*))
          (setvar "OSMODE" 0)
          (setq M (getpoint "\nPick a waypoint: "))
          (setvar "OSMODE" old_osmode)
          (if (null M)
            (princ "\nNo waypoint - cancelled.")
            (progn
              (setq M (list (car M) (cadr M)))
              (cond
                ((< (distance M cA) RbA) (alert "The waypoint lies inside the first roundabout."))
                ((< (distance M cB) RbB) (alert "The waypoint lies inside the second roundabout."))
                (T
                 (setq dA (angle cA M) dB (angle cB M))
                 (setvar "FILLMODE" 1)
                 (setq resA (rdbc-flare cA dA W Rf RbA)
                       resB (rdbc-flare cB dB W Rf RbB))
                 (if (and resA resB)
                   (progn
                     (setq pA (car resA) mouthA (cadr resA)
                           pB (car resB) mouthB (cadr resB))
                     (rdbc-draw-band pA M pB W)
                     (rdbc-draw-edges pA M pB W)
                     (rdbc-draw-centerline pA M pB)
                     (rdbc-recut-kerb cA RbA kerbsA mouthA)
                     (rdbc-recut-kerb cB RbB kerbsB mouthB)
                     (command "._REGEN")
                     (princ (strcat "\nConnection drawn, width " (rtos W 2 2) " m.")))
                   (alert "Entry/exit radius does not fit; pick a smaller radius.")))))))))
    (princ "\nCancelled."))

  (setvar "CMDECHO"  old_cmdecho)
  (setvar "OSMODE"   old_osmode)
  (setvar "FILLMODE" old_fillmode)
  (princ))

(princ)
