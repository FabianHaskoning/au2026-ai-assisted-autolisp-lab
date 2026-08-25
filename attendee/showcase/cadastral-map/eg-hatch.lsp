;; eg-hatch.lsp - putting a solid fill behind a closed boundary.
;;
;; Loaded by: eg-loader.lsp (never load this file on its own).
;; Defines no commands. Needs eg-color.lsp.
;;
;; The interesting part is the rollback: building a hatch is two steps
;; (create it, then give it a boundary loop), and if the second step fails the
;; first one has already put a broken hatch in the drawing. So it deletes it
;; again rather than leaving the mess behind. That habit - undo your own half
;; finished work - is worth more than the hatch code itself.

;; Is this a closed object, i.e. can it be a hatch boundary?
(defun eg:closedp (obj)
  (and
    (vlax-property-available-p obj 'Closed)
    (= (vla-get-Closed obj) :vlax-true)
  )
)

;; Solid-fill the closed entity 'ename' on 'layer' in the colour object
;; 'col'. Returns the hatch's entity name, or nil if it could not be made.
(defun eg:hatch-boundary (ename layer col / doc ms obj h arr res)
  (setq obj (vlax-ename->vla-object ename))
  (if (eg:closedp obj)
    (progn
      (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
      (setq ms  (vla-get-ModelSpace doc))
      (setq h   (vl-catch-all-apply 'vla-AddHatch (list ms 0 "SOLID" :vlax-true)))
      (if (not (vl-catch-all-error-p h))
        (progn
          (setq arr (vlax-make-safearray vlax-vbObject '(0 . 0)))
          (vlax-safearray-put-element arr 0 obj)
          (setq res (vl-catch-all-apply 'vla-AppendOuterLoop
                                        (list h (vlax-make-variant arr))))
          (if (vl-catch-all-error-p res)
            ;; Roll back the half-built hatch instead of leaving it behind.
            (progn (vl-catch-all-apply 'vla-Delete (list h)) nil)
            (progn
              (vl-catch-all-apply 'vla-Evaluate (list h))
              (vl-catch-all-apply 'vla-put-Layer (list h layer))
              (if col (vl-catch-all-apply 'vla-put-TrueColor (list h col)))
              (vlax-vla-object->ename h)
            )
          )
        )
      )
    )
  )
)

;; Push a set of hatches behind everything else, so they read as a background
;; instead of covering the lines they belong to.
;; CMDECHO is the caller's responsibility - see eg-command.lsp.
(defun eg:hatches-to-back (ss)
  (if (and ss (> (sslength ss) 0))
    (command "_.DRAWORDER" ss "" "_Back")
  )
)

(princ "\n  eg-hatch.lsp loaded")
(princ)
