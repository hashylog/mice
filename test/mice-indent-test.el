;;; mice-indent-test.el --- Tests for mice-indent -*- lexical-binding: t; -*-

;;; Code:

(require 'mice-test-helpers)

(ert-deftest mice-indent-test-tab-inserts-up-to-next-tab-stop ()
  (mice-test-with-buffer #'python-mode "ab|"
    (mice-test-press "TAB")
    (should (equal (mice-test-text) "ab  |"))
    (mice-test-press "TAB")
    (should (equal (mice-test-text) "ab      |"))))

(ert-deftest mice-indent-test-tab-is-the-same-in-every-mode ()
  (dolist (mode '(python-mode emacs-lisp-mode text-mode))
    (mice-test-with-buffer mode "if x:\n|y"
      (mice-test-press "TAB")
      (should (equal (mice-test-text) "if x:\n    |y")))))

(ert-deftest mice-indent-test-tab-inserts-real-tabs ()
  (mice-test-with-buffer #'python-mode "|x"
    (setq indent-tabs-mode t)
    (mice-test-press "TAB")
    (should (equal (mice-test-text) "\t|x"))))

(ert-deftest mice-indent-test-tab-indents-selection ()
  (mice-test-with-buffer #'python-mode "a\nb\nc\n"
    (mice-test-select 1 5)
    (mice-test-press "TAB")
    (should (equal (buffer-string) "    a\n    b\nc\n"))
    (should (region-active-p))))

(ert-deftest mice-indent-test-backtab-outdents-selection ()
  (mice-test-with-buffer #'python-mode "    a\n  b\n\tc\n"
    (mice-test-select (point-min) (point-max))
    (mice-test-press "<backtab>")
    (should (equal (buffer-string) "a\nb\nc\n"))))

(ert-deftest mice-indent-test-backtab-outdents-current-line ()
  (mice-test-with-buffer #'python-mode "        a|b"
    (mice-test-press "<backtab>")
    (should (equal (mice-test-text) "    a|b"))))

(ert-deftest mice-indent-test-newline-copies-indentation ()
  (mice-test-with-buffer #'python-mode "    def f():|"
    (mice-test-press "RET")
    (should (equal (mice-test-text) "    def f():\n    |"))))

(ert-deftest mice-indent-test-newline-clears-blank-line ()
  (mice-test-with-buffer #'python-mode "    a\n    |"
    (mice-test-press "RET")
    (should (equal (mice-test-text) "    a\n\n    |"))))

(ert-deftest mice-indent-test-newline-inside-indentation ()
  (mice-test-with-buffer #'python-mode "  |  a"
    (mice-test-press "RET")
    (should (equal (mice-test-text) "\n  |  a"))))

(ert-deftest mice-indent-test-newline-replaces-selection ()
  (mice-test-with-buffer #'python-mode "  abc"
    (mice-test-select 4 5)
    (mice-test-press "RET")
    (should (equal (mice-test-text) "  a\n  |c"))))

(ert-deftest mice-indent-test-backspace-removes-indentation-level ()
  (mice-test-with-buffer #'python-mode "        |a"
    (mice-test-press "DEL")
    (should (equal (mice-test-text) "    |a"))))

(ert-deftest mice-indent-test-backspace-removes-single-character ()
  (mice-test-with-buffer #'python-mode "   |a"
    (mice-test-press "DEL")
    (should (equal (mice-test-text) "  |a"))
    (goto-char (point-max))
    (mice-test-press "DEL")
    (should (equal (mice-test-text) "  |"))))

(ert-deftest mice-indent-test-backspace-at-buffer-start ()
  (mice-test-with-buffer #'python-mode "|a"
    (mice-test-press "DEL")
    (should (equal (mice-test-text) "|a"))))

(ert-deftest mice-indent-test-indent-line-follows-previous-line ()
  (mice-test-with-buffer #'python-mode "    a\n\nb|"
    (indent-according-to-mode)
    (should (equal (mice-test-text) "    a\n\n    b|"))))

(provide 'mice-indent-test)
;;; mice-indent-test.el ends here
