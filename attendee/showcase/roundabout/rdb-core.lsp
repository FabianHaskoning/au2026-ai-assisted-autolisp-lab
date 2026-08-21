;;; ============================================================================
;;;  rdb-core.lsp  -  The round core (concentric rings)
;;; ============================================================================

;; Draw the filled core areas (from the inside out). Edges/cross are drawn
;; by rdb-draw-core-edges (on top, after all fills).
(defun rdb-draw-core-fills (ctr Rb Ri Ro)
  (rdb-make-donut ctr 0.0 Ro "RDB-CentralIsland")  ; disc (central island)
  (rdb-make-donut ctr Ro  Ri "RDB-Mountable")      ; ring (mountable apron)
  (rdb-make-donut ctr Ri  Rb "RDB-Carriageway"))   ; ring (carriageway)

;; Draw the edge circles (inner/central island) and the center cross.
;; The outer radius (Rb) is NOT drawn here: it is drawn as arc segments
;; between the arm mouths (rdb-kerb-arcs).
(defun rdb-draw-core-edges (ctr Rb Ri Ro / m)
  (rdb-make-circle ctr Ri "RDB-Kerb")
  (rdb-make-circle ctr Ro "RDB-Kerb")
  (setq m (max 0.5 (* Ro 0.1)))
  (rdb-make-line (list (- (car ctr) m) (cadr ctr))
                 (list (+ (car ctr) m) (cadr ctr)) "RDB-Centreline")
  (rdb-make-line (list (car ctr) (- (cadr ctr) m))
                 (list (car ctr) (+ (cadr ctr) m)) "RDB-Centreline"))

(princ)
