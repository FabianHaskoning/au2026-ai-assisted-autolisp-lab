;;; ============================================================================
;;;  rdb-arms.lsp  -  Arms (legs): entry/exit radii, asphalt, splitter island
;;; ----------------------------------------------------------------------------
;;;  Arm parameters ap = (we wx wm Ls Re Rx lArm gap drop)
;;;    we   entry width           Ls   splitter length     lArm arm length
;;;    wx   exit width            Re   entry radius        gap  nose distance
;;;    wm   splitter width        Rx   exit radius         drop T=teardrop/nil=straight
;;; ============================================================================

(setq *rdb-nmouth* 18)   ; sampling of the mouth arc
(setq *rdb-nfil*   8)    ; sampling of the fillet arc

;; Project (Q - P) onto the axis direction u (length along u).
(defun rdb-proj-u (P a Q)
  (+ (* (- (car Q) (car P)) (cos a)) (* (- (cadr Q) (cadr P)) (sin a))))

;; Fill a closed edge-point loop with a triangle fan from the centroid.
(defun rdb-fill-fan (pts lay / c n i)
  (setq c (rdb-centroid pts) n (length pts) i 0)
  (repeat n
    (rdb-make-solid-tri c (nth i pts) (nth (rem (1+ i) n) pts) lay)
    (setq i (1+ i))))

;; Draw one arm. Returns the mouth (a_start . a_end) for the kerb, or nil.
(defun rdb-draw-arm (P a Rb ap / we wx wm Ls Re Rx lArm gap drop W sL sR
                                 flL flR TlL TcL thL OL TlR TcR thR OR
                                 aL aR uEnd endL endR bnd nose tail uin innerL innerR)
  (setq we (nth 0 ap) wx (nth 1 ap) wm (nth 2 ap) Ls (nth 3 ap)
        Re (nth 4 ap) Rx (nth 5 ap) lArm (nth 6 ap) gap (nth 7 ap) drop (nth 8 ap)
        W  (+ we wm wx) sL (/ W 2.0) sR (- (/ W 2.0))
        flL (rdb-fillet P a sL Re Rb)
        flR (rdb-fillet P a sR Rx Rb))
  (cond
    ;; ---- full arm with fillets ----
    ((and flL flR)
     (setq TlL (nth 0 flL) TcL (nth 1 flL) thL (nth 2 flL) OL (nth 3 flL)
           TlR (nth 0 flR) TcR (nth 1 flR) thR (nth 2 flR) OR (nth 3 flR)
           aL  (rdb-proj-u P a TlL) aR (rdb-proj-u P a TlR)
           uEnd (+ (max aL aR) lArm)
           endL (rdb-loc P a uEnd sL) endR (rdb-loc P a uEnd sR))
     ;; asphalt fill (triangle fan along the true edge, incl. the flare)
     (setq bnd (append
                 (rdb-arc-pts P Rb thR thL *rdb-nmouth*)                          ; mouth arc (TcR..TcL)
                 (cdr (rdb-arc-pts-short OL Re (angle OL TcL) (angle OL TlL) *rdb-nfil*)) ; left fillet (TcL doubled -> cdr)
                 (list endL endR)                                                 ; left-edge end + right-edge end
                 (rdb-arc-pts-short OR Rx (angle OR TlR) (angle OR TcR) *rdb-nfil*))) ; right fillet (TlR..TcR)
     (rdb-fill-fan bnd "RDB-Carriageway")
     ;; kerb (edges + fillets), on top
     (rdb-make-arc-short OL Re (angle OL TcL) (angle OL TlL) "RDB-Kerb")
     (rdb-make-line TlL endL "RDB-Kerb")
     (rdb-make-line endL endR "RDB-Kerb")
     (rdb-make-line endR TlR "RDB-Kerb")
     (rdb-make-arc-short OR Rx (angle OR TlR) (angle OR TcR) "RDB-Kerb")
     ;; splitter island
     (setq nose (rdb-loc P a (+ Rb gap) 0.0)
           tail (rdb-loc P a (+ Rb gap Ls) 0.0))
     (if drop
       (rdb-make-taper nose 0.0 tail wm "RDB-Splitter")    ; teardrop (pointed nose)
       (rdb-make-taper nose wm  tail wm "RDB-Splitter"))   ; straight (capsule/rectangle)
     (cons thR thL))
    ;; ---- fallback: straight radial connection (fillet does not fit) ----
    ((< (/ W 2.0) Rb)
     (princ "\nNote: entry/exit radius does not fit; straight connection used.")
     (setq uin  (sqrt (- (* Rb Rb) (* (/ W 2.0) (/ W 2.0))))
           innerL (rdb-loc P a uin sL) innerR (rdb-loc P a uin sR)
           endL (rdb-loc P a (+ uin lArm) sL) endR (rdb-loc P a (+ uin lArm) sR))
     (rdb-fill-fan (list innerL endL endR innerR) "RDB-Carriageway")
     (rdb-make-line innerL endL "RDB-Kerb")
     (rdb-make-line endL endR "RDB-Kerb")
     (rdb-make-line endR innerR "RDB-Kerb")
     (setq nose (rdb-loc P a (+ Rb gap) 0.0) tail (rdb-loc P a (+ Rb gap Ls) 0.0))
     (if drop (rdb-make-taper nose 0.0 tail wm "RDB-Splitter")
              (rdb-make-taper nose wm  tail wm "RDB-Splitter"))
     (cons (angle P innerR) (angle P innerL)))
    (T (princ "\nArm skipped: road width too large for the outer radius.") nil)))

;; Draw the outer radius as arc segments between the arm mouths.
;; mouths = list of (a_start . a_end); nil -> full circle.
(defun rdb-kerb-arcs (ctr Rb mouths / spans)
  (if (null mouths)
    (rdb-make-circle ctr Rb "RDB-Kerb")
    (progn
      (setq spans (rdb-complement-spans mouths))
      (foreach g spans
        (if (> (rdb-norm-ang (- (cdr g) (car g))) 1e-6)
          (rdb-make-arc ctr Rb (car g) (cdr g) "RDB-Kerb"))))))

(princ)
