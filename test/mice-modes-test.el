;;; mice-modes-test.el --- Tests for mice-modes -*- lexical-binding: t; -*-

;;; Code:

(require 'mice-test-helpers)

(ert-deftest mice-modes-test-major-mode-is-neutralized ()
  (mice-test-with-buffer #'python-mode ""
    (should mice--managed)
    (should (eq (current-local-map) mice-neutral-map))
    (should (eq indent-line-function #'mice-indent-line))
    (should-not electric-indent-mode)
    (should (eq (key-binding (kbd "TAB")) #'mice-insert-tab))
    (should (eq (key-binding (kbd "RET")) #'mice-newline))))

(ert-deftest mice-modes-test-major-mode-is-restored ()
  (mice-test-with-buffer #'python-mode ""
    (mice-mode -1)
    (should-not mice--managed)
    (should (eq (current-local-map) python-mode-map))
    (should (eq indent-line-function #'python-indent-line-function))
    (should (eq electric-indent-mode (default-value 'electric-indent-mode)))))

(ert-deftest mice-modes-test-mode-change-is-managed ()
  (mice-test-with-buffer #'python-mode ""
    (emacs-lisp-mode)
    (should mice--managed)
    (should (eq (current-local-map) mice-neutral-map))))

(ert-deftest mice-modes-test-special-buffers-are-untouched ()
  (mice-test-with-buffer #'help-mode ""
    (should-not mice--managed)
    (should (eq (current-local-map) help-mode-map))
    (should-not (eq (key-binding (kbd "TAB")) #'mice-insert-tab))))

(ert-deftest mice-modes-test-preserved-modes-are-untouched ()
  (let ((mice-preserved-modes '(prog-mode)))
    (mice-test-with-buffer #'python-mode ""
      (should-not mice--managed)
      (should (eq (current-local-map) python-mode-map)))))

(ert-deftest mice-modes-test-files-in-fundamental-mode-are-managed ()
  (mice-test-with-buffer #'fundamental-mode ""
    (should-not mice--managed)
    (setq buffer-file-name "/nonexistent/notes")
    (run-hooks 'find-file-hook)
    (should mice--managed)
    (setq buffer-file-name nil)))

(provide 'mice-modes-test)
;;; mice-modes-test.el ends here
