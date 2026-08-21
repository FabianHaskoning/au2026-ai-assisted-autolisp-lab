;;; ============================================================================
;;;  rdb-util.lsp  -  Math and drawing helpers for the ROUNDABOUT tool
;;; ----------------------------------------------------------------------------
;;;  Contains no commands; loaded first by rdb-loader.lsp.
;;;  All angles in radians. All points 2D (list x y) unless stated otherwise.
;;; ============================================================================

(vl-load-com)

;;; ----------------------------------------------------------------- numeric

;; 24-bit truecolor value for group code 420.
(defun rdb-rgb (r g b) (+ (* r 65536) (* g 256) b))

;; Locale-safe string -> number (comma -> dot).
(defun rdb-atof (s) (atof (vl-string-translate "," "." s)))

;; Sign of a number as a float.
(defun rdb-sign (x) (cond ((> x 0) 1.0) ((< x 0) -1.0) (T 0.0)))

;; Normalize an angle to [0, 2*pi).
(defun rdb-norm-ang (a / twopi)
  (setq twopi (* 2.0 pi))
  (rem (+ (rem a twopi) twopi) twopi))

;; Local (au along u, sn along n) -> world point, with
;; u = (cos a, sin a) pointing outward and n = (-sin a, cos a) to the left.
(defun rdb-loc (P a au sn)
  (list (+ (car P)  (* au (cos a)) (* sn (- (sin a))))
        (+ (cadr P) (* au (sin a)) (* sn (cos a)))))

;;; ---------------------------------------------------------------- entities

;; Filled "donut" (ring or disc) as a closed wide LWPOLYLINE.
;;   rin = 0.0 -> full disc.
(defun rdb-make-donut (ctr rin rout lay / cx cy rmean w)
  (setq cx (car ctr) cy (cadr ctr)
        rmean (/ (+ rin rout) 2.0) w (- rout rin))
  (entmake
    (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 lay)
          '(100 . "AcDbPolyline") '(90 . 2) '(70 . 1) (cons 43 w)
          (cons 10 (list (- cx rmean) cy)) (cons 42 1.0)
          (cons 10 (list (+ cx rmean) cy)) (cons 42 1.0))))

;; Filled ring segment (curved wide LWPOLYLINE) from a0 to a1 (CCW).
(defun rdb-make-arcband (ctr rin rout a0 a1 lay / rmean w span bulge p0 p1)
  (setq rmean (/ (+ rin rout) 2.0) w (- rout rin)
        span  (rdb-norm-ang (- a1 a0)))
  (if (> span 1e-9)
    (progn
      (setq bulge (/ (sin (/ span 4.0)) (cos (/ span 4.0)))  ; tan(span/4)
            p0 (list (+ (car ctr) (* rmean (cos a0))) (+ (cadr ctr) (* rmean (sin a0))))
            p1 (list (+ (car ctr) (* rmean (cos a1))) (+ (cadr ctr) (* rmean (sin a1)))))
      (entmake
        (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 lay)
              '(100 . "AcDbPolyline") '(90 . 2) '(70 . 0) (cons 43 w)
              (cons 10 p0) (cons 42 bulge) (cons 10 p1))))))

;; Filled tapering strip (triangle/teardrop): p0 with width w0,
;; p1 with width w1.
(defun rdb-make-taper (p0 w0 p1 w1 lay)
  (entmake
    (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 lay)
          '(100 . "AcDbPolyline") '(90 . 2) '(70 . 0)
          (cons 10 p0) (cons 40 w0) (cons 41 w1)
          (cons 10 p1))))

;; Circle (group 10 = 3D point).
(defun rdb-make-circle (ctr rad lay)
  (entmake
    (list '(0 . "CIRCLE") '(100 . "AcDbEntity") (cons 8 lay) '(100 . "AcDbCircle")
          (cons 10 (list (car ctr) (cadr ctr) 0.0)) (cons 40 rad))))

;; Arc. Angles in RADIANS, CCW from a0 (group 50) to a1 (group 51).
(defun rdb-make-arc (ctr rad a0 a1 lay)
  (entmake
    (list '(0 . "ARC") '(100 . "AcDbEntity") (cons 8 lay) '(100 . "AcDbCircle")
          (cons 10 (list (car ctr) (cadr ctr) 0.0)) (cons 40 rad)
          '(100 . "AcDbArc") (cons 50 a0) (cons 51 a1))))

;; Short arc between two absolute angles (picks CCW or CW = shortest).
(defun rdb-make-arc-short (ctr rad aA aB lay / d)
  (setq d (- aB aA))
  (while (> d pi)        (setq d (- d (* 2.0 pi))))
  (while (<= d (- pi))   (setq d (+ d (* 2.0 pi))))
  (if (>= d 0.0) (rdb-make-arc ctr rad aA aB lay)
                 (rdb-make-arc ctr rad aB aA lay)))

;; Line.
(defun rdb-make-line (p1 p2 lay)
  (entmake
    (list '(0 . "LINE") '(100 . "AcDbEntity") (cons 8 lay) '(100 . "AcDbLine")
          (cons 10 (list (car p1) (cadr p1) 0.0))
          (cons 11 (list (car p2) (cadr p2) 0.0)))))

;; Filled triangle (2D SOLID, subclass AcDbTrace). Always fills at FILLMODE=1.
(defun rdb-make-solid-tri (p1 p2 p3 lay)
  (entmake
    (list '(0 . "SOLID") '(100 . "AcDbEntity") (cons 8 lay) '(100 . "AcDbTrace")
          (cons 10 (list (car p1) (cadr p1) 0.0))
          (cons 11 (list (car p2) (cadr p2) 0.0))
          (cons 12 (list (car p3) (cadr p3) 0.0))
          (cons 13 (list (car p3) (cadr p3) 0.0)))))

;; Open/closed LWPOLYLINE with n vertices and constant width w (fills at FILLMODE=1).
(defun rdb-make-wpoly (pts w closed lay / l)
  (setq l (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 lay)
                '(100 . "AcDbPolyline") (cons 90 (length pts))
                (cons 70 (if closed 1 0)) (cons 43 w)))
  (foreach p pts
    (setq l (append l (list (cons 10 (list (car p) (cadr p)))))))
  (entmake l))

;; Left-normal unit vector from p to q (rotated 90 degrees CCW).
(defun rdb-lnorm (p q / dx dy len)
  (setq dx (- (car q) (car p)) dy (- (cadr q) (cadr p)) len (distance p q))
  (if (> len 1e-12) (list (/ (- dy) len) (/ dx len)) (list 0.0 0.0)))

;; Shift point p over distance d along direction n.
(defun rdb-off (p d n)
  (list (+ (car p) (* d (car n))) (+ (cadr p) (* d (cadr n)))))

;;; ---------------------------------------------------------------- sampling

;; List of nseg+1 points on an arc from a0 to a1 (CCW), radius rad around ctr.
(defun rdb-arc-pts (ctr rad a0 a1 nseg / span i ang pts)
  (setq span (rdb-norm-ang (- a1 a0)) pts '() i 0)
  (repeat (1+ nseg)
    (setq ang (+ a0 (* span (/ (float i) (float nseg)))))
    (setq pts (cons (list (+ (car ctr) (* rad (cos ang)))
                          (+ (cadr ctr) (* rad (sin ang)))) pts)
          i (1+ i)))
  (reverse pts))

;; Same, but via the SHORTEST direction (|span| <= pi), CCW or CW.
(defun rdb-arc-pts-short (ctr rad a0 a1 nseg / d i ang pts)
  (setq d (- a1 a0))
  (while (> d pi)      (setq d (- d (* 2.0 pi))))
  (while (<= d (- pi)) (setq d (+ d (* 2.0 pi))))
  (setq pts '() i 0)
  (repeat (1+ nseg)
    (setq ang (+ a0 (* d (/ (float i) (float nseg)))))
    (setq pts (cons (list (+ (car ctr) (* rad (cos ang)))
                          (+ (cadr ctr) (* rad (sin ang)))) pts)
          i (1+ i)))
  (reverse pts))

;; Centroid of a point list.
(defun rdb-centroid (pts / sx sy n)
  (setq sx 0.0 sy 0.0 n 0)
  (foreach p pts (setq sx (+ sx (car p)) sy (+ sy (cadr p)) n (1+ n)))
  (list (/ sx n) (/ sy n)))

;;; ------------------------------------------------------------------ fillet

;; Entry/exit fillet: arc of radius Rf, externally tangent to circle C(P,Rb)
;; and to the straight road edge at normal offset s (s>0 left, s<0 right).
;; Returns (list T_l T_c theta_c O) or nil when there is no solution.
;;   T_l    = tangent point on the straight road edge
;;   T_c    = tangent point on the outer-radius circle
;;   theta_c= absolute angle of T_c relative to P
;;   O      = center of the fillet arc
(defun rdb-fillet (P a s Rf Rb / b disc aa O Tl f Tc)
  (setq b    (+ s (* (rdb-sign s) Rf))
        disc (- (* (+ Rb Rf) (+ Rb Rf)) (* b b)))
  (if (and (> Rf 0.0) (>= disc 0.0))
    (progn
      (setq aa (sqrt disc)
            O  (rdb-loc P a aa b)
            Tl (rdb-loc P a aa s)
            f  (/ Rb (+ Rb Rf))
            Tc (rdb-loc P a (* aa f) (* b f)))
      (list Tl Tc (angle P Tc) O))))

;;; -------------------------------------------------------- complement spans

;; Given mouths as a list of (a_start . a_end) (CCW openings), return the
;; complement spans (closed kerb/ring segments) as a list of (g0 . g1),
;; with g0 < g1 (non-wrapping). Overlapping mouths are merged.
;; With 0 mouths: the whole circle as (0 . 2pi).
(defun rdb-complement-spans (mouths / twopi eps ivals merged gaps cur iv i s e lastm)
  (setq twopi (* 2.0 pi) eps 1e-9)
  (if (null mouths)
    (list (cons 0.0 twopi))
    (progn
      ;; 1) split wrapping mouths into non-wrapping [s,e) intervals
      (setq ivals '())
      (foreach m mouths
        (setq s (rdb-norm-ang (car m)) e (rdb-norm-ang (cdr m)))
        (if (< e s)
          (setq ivals (cons (cons s twopi) (cons (cons 0.0 e) ivals)))
          (setq ivals (cons (cons s e) ivals))))
      (setq ivals (vl-remove-if '(lambda (x) (<= (- (cdr x) (car x)) eps)) ivals))
      (if (null ivals)
        (list (cons 0.0 twopi))
        (progn
          ;; 2) sort on start (tie-break on end, so vl-sort does not drop
          ;;    intervals with an equal start), 3) merge overlaps
          (setq ivals (vl-sort ivals
                        '(lambda (a b)
                           (cond ((< (car a) (car b)) T)
                                 ((> (car a) (car b)) nil)
                                 (T (< (cdr a) (cdr b))))))
                merged '() cur (car ivals))
          (foreach iv (cdr ivals)
            (if (<= (car iv) (+ (cdr cur) eps))
              (setq cur (cons (car cur) (max (cdr cur) (cdr iv))))
              (setq merged (cons cur merged) cur iv)))
          (setq merged (reverse (cons cur merged)))
          ;; 4) complement gaps within [0, 2pi)
          (setq gaps '())
          (if (> (car (car merged)) eps)
            (setq gaps (cons (cons 0.0 (car (car merged))) gaps)))
          (setq i 0)
          (while (< i (1- (length merged)))
            (setq gaps (cons (cons (cdr (nth i merged)) (car (nth (1+ i) merged))) gaps)
                  i (1+ i)))
          (setq lastm (last merged))
          (if (< (cdr lastm) (- twopi eps))
            (setq gaps (cons (cons (cdr lastm) twopi) gaps)))
          (reverse gaps))))))

(princ)
