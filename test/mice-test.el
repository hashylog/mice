;;; mice-test.el --- Tests for mice -*- lexical-binding: t; -*-

;;; Code:

(require 'ert)
(require 'mice)
(require 'python)
(require 'help-mode)

(setq python-indent-guess-indent-offset-verbose nil)

(defmacro mice-test-with-buffer (mode content &rest body)
  "Run BODY with `mice-mode' on, in a MODE buffer holding CONTENT.
Point starts where CONTENT has a | character."
  (declare (indent 2))
  `(with-temp-buffer
     (insert ,content)
     (goto-char (point-min))
     (when (search-forward "|" nil t)
       (delete-char -1))
     (unwind-protect
         (progn
           (mice-mode 1)
           (funcall ,mode)
           (setq-local tab-width 4
                       indent-tabs-mode nil)
           ,@body)
       (mice-mode -1))))

(defun mice-test-press (key)
  "Run the command bound to KEY in the current buffer."
  (let ((command (key-binding (kbd key))))
    (setq last-command-event (aref (kbd key) 0))
    (call-interactively command)))

(defun mice-test-text ()
  "Return the buffer text with a | character at point."
  (concat (buffer-substring (point-min) (point))
          "|"
          (buffer-substring (point) (point-max))))

(ert-deftest mice-test-major-mode-is-neutralized ()
  (mice-test-with-buffer #'python-mode ""
    (should mice--managed)
    (should (eq (current-local-map) mice-neutral-map))
    (should (eq indent-line-function #'mice-indent-line))
    (should-not electric-indent-mode)
    (should (eq (key-binding (kbd "TAB")) #'mice-insert-tab))
    (should (eq (key-binding (kbd "RET")) #'mice-newline))))

(ert-deftest mice-test-major-mode-is-restored ()
  (mice-test-with-buffer #'python-mode ""
    (mice-mode -1)
    (should-not mice--managed)
    (should (eq (current-local-map) python-mode-map))
    (should (eq indent-line-function #'python-indent-line-function))
    (should (eq electric-indent-mode (default-value 'electric-indent-mode)))))

(ert-deftest mice-test-mode-change-is-managed ()
  (mice-test-with-buffer #'python-mode ""
    (emacs-lisp-mode)
    (should mice--managed)
    (should (eq (current-local-map) mice-neutral-map))))

(ert-deftest mice-test-special-buffers-are-untouched ()
  (mice-test-with-buffer #'help-mode ""
    (should-not mice--managed)
    (should (eq (current-local-map) help-mode-map))
    (should-not (eq (key-binding (kbd "TAB")) #'mice-insert-tab))))

(ert-deftest mice-test-read-only-buffers-keep-their-keys ()
  (mice-test-with-buffer #'python-mode ""
    (setq buffer-read-only t)
    (should-not (eq (key-binding (kbd "TAB")) #'mice-insert-tab))))

(ert-deftest mice-test-preserved-modes-are-untouched ()
  (let ((mice-preserved-modes '(prog-mode)))
    (mice-test-with-buffer #'python-mode ""
      (should-not mice--managed)
      (should (eq (current-local-map) python-mode-map)))))

(ert-deftest mice-test-files-in-fundamental-mode-are-managed ()
  (mice-test-with-buffer #'fundamental-mode ""
    (should-not mice--managed)
    (setq buffer-file-name "/nonexistent/notes")
    (run-hooks 'find-file-hook)
    (should mice--managed)
    (setq buffer-file-name nil)))

(ert-deftest mice-test-tab-inserts-up-to-next-tab-stop ()
  (mice-test-with-buffer #'python-mode "ab|"
    (mice-test-press "TAB")
    (should (equal (mice-test-text) "ab  |"))
    (mice-test-press "TAB")
    (should (equal (mice-test-text) "ab      |"))))

(ert-deftest mice-test-tab-is-the-same-in-every-mode ()
  (dolist (mode '(python-mode emacs-lisp-mode text-mode))
    (mice-test-with-buffer mode "if x:\n|y"
      (mice-test-press "TAB")
      (should (equal (mice-test-text) "if x:\n    |y")))))

(ert-deftest mice-test-tab-inserts-real-tabs ()
  (mice-test-with-buffer #'python-mode "|x"
    (setq indent-tabs-mode t)
    (mice-test-press "TAB")
    (should (equal (mice-test-text) "\t|x"))))

(ert-deftest mice-test-tab-indents-selection ()
  (mice-test-with-buffer #'python-mode "|a\nb\nc\n"
    (set-mark (point))
    (forward-line 2)
    (activate-mark)
    (mice-test-press "TAB")
    (should (equal (buffer-string) "    a\n    b\nc\n"))
    (should (region-active-p))))

(ert-deftest mice-test-backtab-outdents-selection ()
  (mice-test-with-buffer #'python-mode "|    a\n  b\n\tc\n"
    (set-mark (point))
    (goto-char (point-max))
    (activate-mark)
    (mice-test-press "<backtab>")
    (should (equal (buffer-string) "a\nb\nc\n"))))

(ert-deftest mice-test-backtab-outdents-current-line ()
  (mice-test-with-buffer #'python-mode "        a|b"
    (mice-test-press "<backtab>")
    (should (equal (mice-test-text) "    a|b"))))

(ert-deftest mice-test-newline-copies-indentation ()
  (mice-test-with-buffer #'python-mode "    def f():|"
    (mice-test-press "RET")
    (should (equal (mice-test-text) "    def f():\n    |"))))

(ert-deftest mice-test-newline-clears-blank-line ()
  (mice-test-with-buffer #'python-mode "    a\n    |"
    (mice-test-press "RET")
    (should (equal (mice-test-text) "    a\n\n    |"))))

(ert-deftest mice-test-newline-inside-indentation ()
  (mice-test-with-buffer #'python-mode "  |  a"
    (mice-test-press "RET")
    (should (equal (mice-test-text) "\n  |  a"))))

(ert-deftest mice-test-newline-replaces-selection ()
  (mice-test-with-buffer #'python-mode "  a|bc"
    (set-mark (point))
    (forward-char 1)
    (activate-mark)
    (mice-test-press "RET")
    (should (equal (mice-test-text) "  a\n  |c"))))

(ert-deftest mice-test-backspace-removes-indentation-level ()
  (mice-test-with-buffer #'python-mode "        |a"
    (mice-test-press "DEL")
    (should (equal (mice-test-text) "    |a"))))

(ert-deftest mice-test-backspace-removes-single-character ()
  (mice-test-with-buffer #'python-mode "   |a"
    (mice-test-press "DEL")
    (should (equal (mice-test-text) "  |a"))
    (goto-char (point-max))
    (mice-test-press "DEL")
    (should (equal (mice-test-text) "  |"))))

(ert-deftest mice-test-backspace-at-buffer-start ()
  (mice-test-with-buffer #'python-mode "|a"
    (mice-test-press "DEL")
    (should (equal (mice-test-text) "|a"))))

(ert-deftest mice-test-indent-line-follows-previous-line ()
  (mice-test-with-buffer #'python-mode "    a\n\nb|"
    (indent-according-to-mode)
    (should (equal (mice-test-text) "    a\n\n    b|"))))

(provide 'mice-test)
;;; mice-test.el ends here
