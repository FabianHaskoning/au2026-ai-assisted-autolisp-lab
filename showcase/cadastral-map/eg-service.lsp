;; eg-service.lsp - fetches the map service definition and reads the colours
;; out of it.
;;
;; Loaded by: eg-loader.lsp (never load this file on its own).
;; Defines no commands. Needs eg-util.lsp.
;;
;; ---------------------------------------------------------------------------
;; READ THIS ONE LAST. It is the most advanced file in the showcase, and it is
;; deliberately not a model to copy.
;;
;; It does two things AutoLISP is bad at: an HTTP request (through a Windows
;; COM object) and reading JSON (by walking the text character by character,
;; because AutoLISP has no JSON parser). The character walk below handles the
;; exact shape this one service returns and nothing more - it does not cope
;; with escaped quotes inside strings, nulls, or nested objects. In a real
;; project you would push the JSON out to a language that has a parser, or use
;; the .NET API. It is here because this is what the working tool actually
;; does, and pretending otherwise would be dishonest.
;; ---------------------------------------------------------------------------

;; GET a URL and return the response body as a string, or nil.
;; Every COM call is wrapped: a failure here must not take the drawing down.
(defun eg:http-get (url / h status txt)
  (setq txt nil)
  (setq h (vl-catch-all-apply 'vlax-create-object (list "MSXML2.ServerXMLHTTP.6.0")))
  (if (vl-catch-all-error-p h)
    ;; Silence here was the original behaviour and it is the worst case for a
    ;; user: no drawing change, no message, no idea why.
    (princ "\nCould not create the HTTP object (MSXML2.ServerXMLHTTP.6.0). This machine may block it.")
    (progn
      (vl-catch-all-apply 'vlax-invoke-method (list h 'open "GET" url :vlax-false))
      (vl-catch-all-apply 'vlax-invoke-method (list h 'send))
      (setq status (vl-catch-all-apply 'vlax-get-property (list h 'status)))
      (cond
        ((vl-catch-all-error-p status)
         (princ "\nThe request never completed - no network, or the host is unreachable."))
        ((/= status 200)
         (princ (strcat "\nHTTP " (itoa status) " from the service. The URL may be wrong, or it may require a login.")))
        (T
         (setq txt (vl-catch-all-apply 'vlax-get-property (list h 'responseText)))
         (if (vl-catch-all-error-p txt)
           (progn
             (princ "\nThe service answered but the response could not be read.")
             (setq txt nil)
           )
         )
        )
      )
      (vl-catch-all-apply 'vlax-release-object (list h))
    )
  )
  txt
)

;; Move past  "key" :  and any whitespace, and return the position of the
;; first character of the value.
(defun eg:skip-val (s keypos / p len)
  (setq len (strlen s) p (+ keypos 1))
  (while (and (<= p len) (/= (eg:at s p) ":")) (setq p (1+ p)))
  (setq p (1+ p))
  (while (and (<= p len) (eg:blankp (eg:at s p))) (setq p (1+ p)))
  p
)

;; The scalar value belonging to the key at keypos, quoted or not.
(defun eg:json-val (s keypos / p st quoted ch len)
  (setq len (strlen s) p (eg:skip-val s keypos) quoted nil)
  (if (= (eg:at s p) "\"") (setq quoted T p (1+ p)))
  (setq st p)
  (while (and (<= p len) (setq ch (eg:at s p))
              (if quoted (/= ch "\"") (not (wcmatch ch "[,}]"))))
    (setq p (1+ p))
  )
  (eg:trim (substr s st (- p st)))
)

;; The contents of the [ ... ] array belonging to the key at keypos.
(defun eg:json-array-at (s keypos / p st len)
  (setq len (strlen s) p (eg:skip-val s keypos))
  (while (and (<= p len) (/= (eg:at s p) "[")) (setq p (1+ p)))
  (setq p (1+ p) st p)
  (while (and (<= p len) (/= (eg:at s p) "]")) (setq p (1+ p)))
  (substr s st (- p st))
)

;; The contents of the [ ... ] array belonging to 'key', counting bracket
;; depth so nested arrays inside it are kept intact.
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
        (setq p (1+ p))
      )
      (if (= d 0) (substr s st (- (- p 1) st)))
    )
  )
)

;; "250,249,175,255" -> (250 249 175 255). Rewrites the text as a Lisp list
;; and lets `read` do the number parsing.
(defun eg:nums (txt / expr out)
  (setq expr (strcat "(" (eg:rep txt "," " ") ")"))
  (setq out (vl-catch-all-apply 'read (list expr)))
  (if (vl-catch-all-error-p out) nil out)
)

;; Download the service definition and return its renderer classes as
;; ((value r g b) (value r g b) ...), or nil.
;;
;; The two step sizes below (10 and 7) are the lengths of the keys we just
;; consumed - "color" plus quotes and colon, and "value" plus quotes - which
;; is how the scan moves on to the next class instead of finding the same one
;; again.
(defun eg:get-renderer-classes (url / json block pos vp cp value rgba out)
  (setq json (eg:http-get url) out nil)
  (if json
    (progn
      (setq block (eg:json-block json "\"uniqueValueInfos\"") pos 0)
      (if (null block)
        (princ "\nThe service answered, but it has no uniqueValueInfos block - it may not be a layer with a classified renderer.")
      )
      (while (and block (setq vp (vl-string-search "\"value\"" block pos)))
        (setq value (eg:json-val block vp))
        (setq cp (vl-string-search "\"color\"" block vp))
        (if cp
          (progn
            (setq rgba (eg:nums (eg:json-array-at block cp)))
            (if (and rgba (>= (length rgba) 3))
              (setq out (cons (list value (nth 0 rgba) (nth 1 rgba) (nth 2 rgba)) out))
            )
            (setq pos (+ cp 10))
          )
          (setq pos (+ vp 7))
        )
      )
    )
  )
  (reverse out)
)

(princ "\n  eg-service.lsp loaded")
(princ)
