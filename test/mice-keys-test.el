;;; mice-keys-test.el --- Tests for mice-keys and mice-mode -*- lexical-binding: t; -*-

;;; Code:

(require 'mice-test-helpers)

(ert-deftest mice-keys-test-prefixes-are-replaced-in-managed-buffers ()
  (mice-test-with-buffer #'python-mode ""
    (should (eq (key-binding (kbd "C-x")) #'mice-cut))
    (should (eq (key-binding (kbd "C-c")) #'mice-copy))
    (should (eq (key-binding (kbd "C-z")) #'mice-undo))))

(ert-deftest mice-keys-test-read-only-buffers-keep-edit-keys ()
  (mice-test-with-buffer #'python-mode ""
    (setq buffer-read-only t)
    (should-not (eq (key-binding (kbd "TAB")) #'mice-insert-tab))
    (should (keymapp (key-binding (kbd "C-x"))))
    (should (eq (key-binding (kbd "C-c")) #'mice-copy))
    (should (eq (key-binding (kbd "<left>")) #'mice-left))))

(ert-deftest mice-keys-test-special-buffers ()
  (mice-test-with-buffer #'help-mode "abc"
    (should (eq (key-binding (kbd "C-q")) #'mice-close))
    (should (eq (key-binding (kbd "C-f")) #'mice-find))
    (should-not (eq (key-binding (kbd "<left>")) #'mice-left))
    (should-not (eq (key-binding (kbd "C-c")) #'mice-copy))
    (mice-test-select 1 3)
    (should (eq (key-binding (kbd "C-c")) #'mice-copy))))

(ert-deftest mice-keys-test-every-binding-is-a-command ()
  (pcase-dolist (`(,_scope ,key ,command) mice-keys--bindings)
    (should (commandp command))
    (should (key-valid-p key))))

(ert-deftest mice-keys-test-disabling-restores-state ()
  (let ((delete-selection-before delete-selection-mode))
    (delete-selection-mode -1)
    (unwind-protect
        (progn
          (mice-mode 1)
          (mice-mode 1)
          (should delete-selection-mode)
          (should (eq (keymap-lookup isearch-mode-map "<down>")
                      #'isearch-repeat-forward))
          (mice-mode -1)
          (should-not delete-selection-mode)
          (should-not (memq 'mice--emulation-alist emulation-mode-map-alists))
          (should-not (eq (keymap-lookup isearch-mode-map "C-v")
                          #'isearch-yank-kill)))
      (mice-mode -1)
      (delete-selection-mode (if delete-selection-before 1 -1)))))

(provide 'mice-keys-test)
;;; mice-keys-test.el ends here
