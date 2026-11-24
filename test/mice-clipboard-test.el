;;; mice-clipboard-test.el --- Tests for mice-clipboard -*- lexical-binding: t; -*-

;;; Code:

(require 'cl-lib)
(require 'mice-test-helpers)

(defconst mice-clipboard-test--tool
  '(wayland ("wl-copy") ("wl-paste" "--no-newline")))

(defun mice-clipboard-test--osc52 (text)
  "Return the OSC 52 sequence that sets the clipboard to TEXT."
  (concat "\e]52;c;" (base64-encode-string (encode-coding-string text 'utf-8) t) "\a"))

(defmacro mice-clipboard-test-in-terminal (&rest body)
  "Run BODY as if Emacs ran in a local terminal, recording terminal output.
The variable `sent' holds the strings sent to the terminal, newest first."
  (declare (indent 0))
  `(let ((sent nil)
         (mice-clipboard 'auto)
         (mice-clipboard--last-text nil))
     (cl-letf (((symbol-function 'mice-clipboard--graphic-p) #'ignore)
               ((symbol-function 'mice-clipboard--tty-p) #'always)
               ((symbol-function 'mice-clipboard--ssh-p) #'ignore)
               ((symbol-function 'discard-input) #'ignore)
               ((symbol-function 'send-string-to-terminal)
                (lambda (string &rest _) (push string sent))))
       (unwind-protect
           (progn ,@body)
         (define-key input-decode-map "\e]52;" nil)
         (set-terminal-parameter nil 'mice-clipboard-read nil)))))

(defmacro mice-clipboard-test-with-events (events &rest body)
  "Run BODY with `read-event' returning the characters of EVENTS, then nil."
  (declare (indent 1))
  `(let ((queue (append ,events nil)))
     (cl-letf (((symbol-function 'read-event) (lambda (&rest _) (pop queue))))
       ,@body)))

(ert-deftest mice-clipboard-test-copy-goes-through-terminal ()
  (mice-clipboard-test-in-terminal
    (mice-clipboard-cut "héllo")
    (should (equal sent (list (mice-clipboard-test--osc52 "héllo"))))))

(ert-deftest mice-clipboard-test-copy-too-large-is-not-sent ()
  (mice-clipboard-test-in-terminal
    (let ((mice-clipboard-max-length 4)
          (inhibit-message t))
      (mice-clipboard-cut "hello")
      (should-not sent))))

(ert-deftest mice-clipboard-test-auto-pastes-with-tool ()
  (mice-clipboard-test-in-terminal
    (cl-letf (((symbol-function 'mice-clipboard--tool)
               (lambda () mice-clipboard-test--tool))
              ((symbol-function 'mice-clipboard--external-read)
               (lambda (command)
                 (should (equal command '("wl-paste" "--no-newline")))
                 "system")))
      (should (equal (mice-clipboard-paste) "system"))
      (should-not (mice-clipboard-paste))
      (should-not sent))))

(ert-deftest mice-clipboard-test-auto-without-tool-asks-terminal ()
  (mice-clipboard-test-in-terminal
    (cl-letf (((symbol-function 'mice-clipboard--tool) #'ignore))
      (mice-clipboard-test-with-events
          (concat "\e]52;c;" (base64-encode-string "from terminal") "\e\\")
        (should (equal (mice-clipboard-paste) "from terminal"))
        (should (equal sent '("\e]52;c;?\e\\")))))))

(ert-deftest mice-clipboard-test-auto-over-ssh-only-uses-terminal ()
  (mice-clipboard-test-in-terminal
    (cl-letf (((symbol-function 'mice-clipboard--ssh-p) #'always)
              ((symbol-function 'mice-clipboard--tool)
               (lambda () mice-clipboard-test--tool))
              ((symbol-function 'mice-clipboard--external-read)
               (lambda (_) (error "Clipboard tool used over SSH"))))
      (mice-clipboard-test-with-events
          (concat "\e]52;c;" (base64-encode-string "remote") "\a")
        (should (equal (mice-clipboard-paste) "remote"))))))

(ert-deftest mice-clipboard-test-internal-never-leaves-emacs ()
  (mice-clipboard-test-in-terminal
    (let ((mice-clipboard 'internal))
      (cl-letf (((symbol-function 'mice-clipboard--tool)
                 (lambda () (error "Clipboard tool used"))))
        (mice-clipboard-cut "text")
        (should-not (mice-clipboard-paste))
        (should-not sent)))))

(ert-deftest mice-clipboard-test-own-copy-is-not-pasted-twice ()
  (mice-clipboard-test-in-terminal
    (cl-letf (((symbol-function 'mice-clipboard--tool)
               (lambda () mice-clipboard-test--tool))
              ((symbol-function 'mice-clipboard--external-read)
               (lambda (_) "copied")))
      (mice-clipboard-cut "copied")
      (should-not (mice-clipboard-paste)))))

(ert-deftest mice-clipboard-test-graphic-frames-use-native-clipboard ()
  (let* ((native nil)
         (mice-clipboard--saved-functions
          (cons (lambda (text) (push text native)) (lambda () "native"))))
    (cl-letf (((symbol-function 'mice-clipboard--graphic-p) #'always)
              ((symbol-function 'send-string-to-terminal)
               (lambda (&rest _) (error "Terminal used in a graphic frame"))))
      (mice-clipboard-cut "text")
      (should (equal native '("text")))
      (should (equal (mice-clipboard-paste) "native")))))

(ert-deftest mice-clipboard-test-terminal-timeout-is-remembered ()
  (mice-clipboard-test-in-terminal
    (let ((mice-clipboard 'terminal))
      (mice-clipboard-test-with-events ""
        (should-not (mice-clipboard-paste))
        (should-not (mice-clipboard-paste)))
      (should (equal (length sent) 1))
      (should (eq (lookup-key input-decode-map "\e]52;")
                  #'mice-clipboard--discard-late-reply)))))

(ert-deftest mice-clipboard-test-late-reply-is-discarded ()
  (mice-clipboard-test-in-terminal
    (set-terminal-parameter nil 'mice-clipboard-read 'unsupported)
    (define-key input-decode-map "\e]52;" #'mice-clipboard--discard-late-reply)
    (mice-clipboard-test-with-events "c;aGk=\a"
      (should (equal (mice-clipboard--discard-late-reply) []))
      (should-not queue))
    (should-not (terminal-parameter nil 'mice-clipboard-read))
    (should-not (lookup-key input-decode-map "\e]52;"))))

(ert-deftest mice-clipboard-test-unexpected-input-is-kept ()
  (mice-clipboard-test-in-terminal
    (let ((mice-clipboard 'terminal)
          (unread-command-events nil))
      (mice-clipboard-test-with-events "ab"
        (should-not (mice-clipboard-paste))
        (should (equal unread-command-events '(?a)))))))

(ert-deftest mice-clipboard-test-external-read-runs-tool ()
  (should (equal (mice-clipboard--external-read '("printf" "%s" "héllo")) "héllo"))
  (should-not (mice-clipboard--external-read '("false"))))

(ert-deftest mice-clipboard-test-external-write-runs-tool ()
  (let ((file (make-temp-file "mice-clipboard-")))
    (unwind-protect
        (progn
          (mice-clipboard--external-write
           (list "sh" "-c" (format "cat > %s" (shell-quote-argument file)))
           "héllo")
          (with-timeout (5 (error "Clipboard tool did not finish"))
            (while (zerop (file-attribute-size (file-attributes file)))
              (accept-process-output nil 0.05)))
          (should (equal (with-temp-buffer
                           (let ((coding-system-for-read 'utf-8))
                             (insert-file-contents file))
                           (buffer-string))
                         "héllo")))
      (delete-file file))))

(ert-deftest mice-clipboard-test-paste-key-uses-system-clipboard ()
  (mice-test-with-buffer #'text-mode "ab|"
    (mice-clipboard-test-in-terminal
      (cl-letf (((symbol-function 'mice-clipboard--read) (lambda () "XY")))
        (mice-test-press "C-v")
        (should (equal (mice-test-text) "abXY|"))))))

(ert-deftest mice-clipboard-test-terminal-paste-replaces-selection ()
  (mice-test-with-buffer #'text-mode "abcd"
    (should (eq (key-binding [xterm-paste]) #'mice-terminal-paste))
    (mice-test-select 2 4)
    (mice-terminal-paste '(xterm-paste "XY"))
    (should (equal (buffer-string) "aXYd"))
    (should (= (point) 4))))

(provide 'mice-clipboard-test)
;;; mice-clipboard-test.el ends here
