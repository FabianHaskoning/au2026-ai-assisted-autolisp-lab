;; read-the-drawing.lsp
;; A routine that READS the drawing instead of drawing into it. This is the
;; gateway to tools that understand what's already there: it recognizes a
;; roundabout from nothing but its own circles.
;; Uses the same technique as rdb-connect.lsp in the roundabout showcase.
;;
;; Try it:   APPLOAD C:\LabWork\showcase\roundabout\rdb-loader.lsp first and
;;           draw a roundabout with the ROUNDABOUT command.
;; Load it:  APPLOAD this file.
;; Run it:   type RDBINFO, then click the outer circle of the roundabout.
;;
;; Read-only by design: nothing is drawn, modified or deleted.
;;
;; The three techniques to study:
;;   1. entsel  - let the user click ONE entity, then inspect it.
;;   2. ssget "_X" with a filter list - collect matching entities
;;      drawing-wide (here: circles/arcs on layer RDB-Kerb).
;;   3. entget + assoc - read DXF group codes off an entity
;;      (10 = centre, 40 = radius).
;;
;; Extend it (pick one, ask your assistant to help):
;;   - Also report how many arms the roundabout has. Hint: each mouth
;;     opening turns the outer circle into ARC segments - count them.
;;   - Report the carriageway width (difference of the two largest radii).
;;   - Make it work when two roundabouts exist in the same drawing.

(defun c:RDBINFO ( / e ed centre ss i en ed2 cc radii r report)

  ;; 1) one click from the user, validated.
  (setq e (entsel "\nClick a circle or arc of a roundabout: "))
  (cond
    ((null e)
     (princ "\nNothing selected."))
    ((not (member (cdr (assoc 0 (entget (car e)))) '("CIRCLE" "ARC")))
     (princ "\nThat is not a circle or arc - try the roundabout's outer edge."))
    (T
     (setq ed     (entget (car e))
           cc     (cdr (assoc 10 ed))
           centre (list (car cc) (cadr cc)))
     ;; 2) all kerb circles/arcs in the whole drawing.
     (setq ss (ssget "_X" '((0 . "CIRCLE,ARC") (8 . "RDB-Kerb"))))
     (if (null ss)
       (princ "\nNo entities on layer RDB-Kerb found. Draw one with ROUNDABOUT first.")
       (progn
         ;; 3) keep the radii of those sharing our centre (tolerance 1e-4).
         (setq radii '() i 0)
         (repeat (sslength ss)
           (setq en  (ssname ss i)
                 ed2 (entget en)
                 cc  (cdr (assoc 10 ed2)))
           (if (< (distance centre (list (car cc) (cadr cc))) 1e-4)
             (setq r (cdr (assoc 40 ed2))
                   radii (if (member r radii) radii (cons r radii)))
           )
           (setq i (1+ i))
         )
         (setq radii (vl-sort radii '<))
         (if (< (length radii) 3)
           (princ "\nNo valid roundabout at that centre (expected 3 distinct radii).")
           (progn
             (setq report (strcat
               "\n--- Roundabout at ("
               (rtos (car centre) 2 2) ", " (rtos (cadr centre) 2 2) ") ---"
               "\nCentral island radius Ro: " (rtos (nth 0 radii) 2 2) " m"
               "\nInner radius Ri:          " (rtos (nth 1 radii) 2 2) " m"
               "\nOuter radius Rb:          " (rtos (nth 2 radii) 2 2) " m"))
             (princ report)
           )
         )
       )
     )
    )
  )
  (princ)
)

(princ "\nRDBINFO loaded. Type RDBINFO to run it.")
(princ)
