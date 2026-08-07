;;; EG_05_Hatch.lsp
;;; SOLID hatch creation for closed polygon boundary features.

(defun eg:closedp (obj)
  (and
    (vlax-property-available-p obj 'Closed)
    (= (vla-get-Closed obj) :vlax-true)))

(defun eg:hatch-boundary (ename layer r g b / doc ms obj h arr res)
  (setq obj (vlax-ename->vla-object ename))
  (if (eg:closedp obj)
    (progn
      (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
      (setq ms (vla-get-ModelSpace doc))
      (setq h (vl-catch-all-apply 'vla-AddHatch (list ms 0 "SOLID" :vlax-true)))
      (if (not (vl-catch-all-error-p h))
        (progn
          (setq arr (vlax-make-safearray vlax-vbObject '(0 . 0)))
          (vlax-safearray-put-element arr 0 obj)
          (setq res (vl-catch-all-apply 'vla-AppendOuterLoop (list h (vlax-make-variant arr))))
          (if (vl-catch-all-error-p res)
            (progn
              (vl-catch-all-apply 'vla-Delete (list h))
              nil)
            (progn
              (vla-Evaluate h)
              (vla-put-Layer h layer)
              (vla-put-TrueColor h (eg:rgb r g b))
              (vlax-vla-object->ename h))))))))

(defun eg:hatches-to-back (ss)
  (if (and ss (> (sslength ss) 0))
    (command "_.DRAWORDER" ss "" "_Back")))

(princ "\nLoaded EG_05_Hatch.lsp")
(princ)
