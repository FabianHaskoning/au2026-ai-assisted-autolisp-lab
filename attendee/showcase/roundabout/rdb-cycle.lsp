;;; ============================================================================
;;;  rdb-cycle.lsp  -  Separated cycle ring around the roundabout
;;; ----------------------------------------------------------------------------
;;;  Ring between Rin = Rb+verge and Rout = Rin+wbike, interrupted at every
;;;  arm by a crossing (same red band + optional block marking).
;;; ============================================================================

(setq *rdb-nmark* 5)   ; number of blocks in a crossing marking

;; White radial block marking (zebra) across a mouth, between Rin and Rout.
(defun rdb-crossing-marking (ctr Rin Rout a0 a1 / span i ang p0 p1)
  (setq span (rdb-norm-ang (- a1 a0)) i 1)
  (repeat *rdb-nmark*
    (setq ang (+ a0 (* span (/ (- (float i) 0.5) (float *rdb-nmark*))))
          p0  (list (+ (car ctr) (* Rin (cos ang)))  (+ (cadr ctr) (* Rin (sin ang))))
          p1  (list (+ (car ctr) (* Rout (cos ang))) (+ (cadr ctr) (* Rout (sin ang)))))
    (rdb-make-taper p0 0.35 p1 0.35 "RDB-Marking")
    (setq i (1+ i))))

;; Draw the cycle ring + crossings.
;;   mouths = list of (a_start . a_end); nil -> full closed ring.
(defun rdb-draw-cycle-ring (ctr Rb verge wbike mouths doMark / Rin Rout spans)
  (setq Rin (+ Rb verge) Rout (+ Rb verge wbike))
  (cond
    ((null mouths)
     (rdb-make-donut ctr Rin Rout "RDB-CyclePath")
     (rdb-make-circle ctr Rin  "RDB-Kerb")
     (rdb-make-circle ctr Rout "RDB-Kerb"))
    (T
     ;; filled ring segments between the arms
     (setq spans (rdb-complement-spans mouths))
     (foreach g spans
       (if (> (rdb-norm-ang (- (cdr g) (car g))) 1e-6)
         (progn
           (rdb-make-arcband ctr Rin Rout (car g) (cdr g) "RDB-CyclePath")
           (rdb-make-arc ctr Rin  (car g) (cdr g) "RDB-Kerb")
           (rdb-make-arc ctr Rout (car g) (cdr g) "RDB-Kerb"))))
     ;; crossings (same red band across the road mouth) + marking
     (foreach m mouths
       (rdb-make-arcband ctr Rin Rout (car m) (cdr m) "RDB-CyclePath")
       (if doMark (rdb-crossing-marking ctr Rin Rout (car m) (cdr m)))))))

(princ)
