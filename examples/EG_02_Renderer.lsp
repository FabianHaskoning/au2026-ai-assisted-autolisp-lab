;;; EG_02_Renderer.lsp
;;; Downloads and parses ArcGIS REST uniqueValueInfos into ((value r g b) ...).

(defun eg:http-get (url / h status txt)
  (setq txt nil)
  (setq h (vl-catch-all-apply 'vlax-create-object (list "MSXML2.ServerXMLHTTP.6.0")))
  (if (not (vl-catch-all-error-p h))
    (progn
      (vl-catch-all-apply 'vlax-invoke-method (list h 'open "GET" url :vlax-false))
      (vl-catch-all-apply 'vlax-invoke-method (list h 'setRequestHeader "User-Agent" "Mozilla/5.0 AutoCAD"))
      (vl-catch-all-apply 'vlax-invoke-method (list h 'setRequestHeader "Referer" "https://maps.prorail.nl/"))
      (vl-catch-all-apply 'vlax-invoke-method (list h 'send))
      (setq status (vl-catch-all-apply 'vlax-get-property (list h 'status)))
      (if (and (not (vl-catch-all-error-p status)) (= status 200))
        (setq txt (vlax-get-property h 'responseText))
        (princ (strcat "\nHTTP failed. Status: " (if (numberp status) (itoa status) "unknown"))))
      (vl-catch-all-apply 'vlax-release-object (list h))))
  txt)

(defun eg:skip-val (s keypos / p len)
  (setq len (strlen s) p (+ keypos 1))
  (while (and (<= p len) (/= (eg:at s p) ":")) (setq p (1+ p)))
  (setq p (1+ p))
  (while (and (<= p len) (eg:blankp (eg:at s p))) (setq p (1+ p)))
  p)

(defun eg:json-val (s keypos / p st quoted ch len)
  (setq len (strlen s) p (eg:skip-val s keypos) quoted nil)
  (if (= (eg:at s p) "\"") (setq quoted T p (1+ p)))
  (setq st p)
  (while (and (<= p len) (setq ch (eg:at s p))
              (if quoted (/= ch "\"") (not (wcmatch ch "[,}]"))))
    (setq p (1+ p)))
  (eg:trim (substr s st (- p st))))

(defun eg:json-array-at (s keypos / p st len)
  (setq len (strlen s) p (eg:skip-val s keypos))
  (while (and (<= p len) (/= (eg:at s p) "[")) (setq p (1+ p)))
  (setq p (1+ p) st p)
  (while (and (<= p len) (/= (eg:at s p) "]")) (setq p (1+ p)))
  (substr s st (- p st)))

(defun eg:json-block (s key / kp p st len d ch)
  (setq kp (vl-string-search key s))
  (if kp
    (progn
      (setq len (strlen s) p (+ kp 1))
      (while (and (<= p len) (/= (eg:at s p) "[")) (setq p (1+ p)))
      (setq d 1 p (1+ p) st p)
      (while (and (<= p len) (> d 0))
        (setq ch (eg:at s p))
        (cond ((= ch "[") (setq d (1+ d))) ((= ch "]") (setq d (1- d))))
        (setq p (1+ p)))
      (if (= d 0) (substr s st (- (- p 1) st))))))

(defun eg:nums (txt / expr out)
  (setq expr (strcat "(" (eg:rep txt "," " ") ")"))
  (setq out (vl-catch-all-apply 'read (list expr)))
  (if (vl-catch-all-error-p out) nil out))

(defun eg:get-perceelscore-renderer (url / json block pos vp cp value rgba out)
  (setq json (eg:http-get url) out nil)
  (if json
    (progn
      (setq block (eg:json-block json "\"uniqueValueInfos\"") pos 0)
      (while (and block (setq vp (vl-string-search "\"value\"" block pos)))
        (setq value (eg:json-val block vp))
        (setq cp (vl-string-search "\"color\"" block vp))
        (if cp
          (progn
            (setq rgba (eg:nums (eg:json-array-at block cp)))
            (if (and rgba (>= (length rgba) 3))
              (setq out (cons (list value (nth 0 rgba) (nth 1 rgba) (nth 2 rgba)) out)))
            (setq pos (+ cp 10)))
          (setq pos (+ vp 7))))))
  (reverse out))

(princ "\nLoaded EG_02_Renderer.lsp")
(princ)
