;;; mice-edit-test.el --- Tests for mice-edit -*- lexical-binding: t; -*-

;;; Code:

(require 'mice-test-helpers)

(ert-deftest mice-edit-test-copy-line ()
  (mice-test-with-buffer #'text-mode "a\nb|c\nd"
    (mice-test-press "C-c")
    (should (equal (current-kill 0) "bc\n"))
    (should (equal (mice-test-text) "a\nb|c\nd"))))

(ert-deftest mice-edit-test-copy-selection ()
  (mice-test-with-buffer #'text-mode "abcd"
    (mice-test-select 2 4)
    (mice-test-press "C-c")
    (should (equal (current-kill 0) "bc"))
    (should-not (region-active-p))))

(ert-deftest mice-edit-test-cut-line ()
  (mice-test-with-buffer #'text-mode "a\nb|b\nc\nd"
    (mice-test-press "C-x")
    (should (equal (mice-test-text) "a\n|c\nd"))
    (should (equal (current-kill 0) "bb\n"))))

(ert-deftest mice-edit-test-consecutive-line-cuts-accumulate ()
  (mice-test-with-buffer #'text-mode "a\n|b\nc\nd"
    (mice-test-press "C-k")
    (mice-test-press "C-k")
    (should (equal (mice-test-text) "a\n|d"))
    (should (equal (current-kill 0) "b\nc\n"))))

(ert-deftest mice-edit-test-cut-last-line ()
  (mice-test-with-buffer #'text-mode "a\nb|"
    (mice-test-press "C-x")
    (should (equal (buffer-string) "a"))
    (should (equal (current-kill 0) "b\n"))))

(ert-deftest mice-edit-test-cut-selection ()
  (mice-test-with-buffer #'text-mode "abcd"
    (mice-test-select 2 4)
    (mice-test-press "C-x")
    (should (equal (mice-test-text) "a|d"))
    (should (equal (current-kill 0) "bc"))))

(ert-deftest mice-edit-test-paste-replaces-selection ()
  (mice-test-with-buffer #'text-mode "abcd"
    (kill-new "XY")
    (mice-test-select 2 4)
    (mice-test-press "C-v")
    (should (equal (mice-test-text) "aXY|d"))))

(ert-deftest mice-edit-test-typing-replaces-selection ()
  (mice-test-with-buffer #'text-mode "abcd"
    (mice-test-select 2 4)
    (mice-test-press "x")
    (should (equal (mice-test-text) "ax|d"))))

(ert-deftest mice-edit-test-undo-and-redo ()
  (mice-test-with-buffer #'text-mode "ab|"
    (mice-test-press "x")
    (mice-test-press "RET")
    (should (equal (buffer-string) "abx\n"))
    (mice-test-press "C-z")
    (should (equal (buffer-string) "abx"))
    (mice-test-press "C-z")
    (should (equal (buffer-string) "ab"))
    (mice-test-press "C-y")
    (should (equal (buffer-string) "abx"))))

(ert-deftest mice-edit-test-move-line-down-and-up ()
  (mice-test-with-buffer #'text-mode "a|a\nbb\ncc"
    (mice-test-press "M-<down>")
    (should (equal (mice-test-text) "bb\na|a\ncc"))
    (mice-test-press "M-<down>")
    (should (equal (mice-test-text) "bb\ncc\na|a"))
    (mice-test-press "M-<down>")
    (should (equal (mice-test-text) "bb\ncc\na|a"))
    (mice-test-press "M-<up>")
    (should (equal (mice-test-text) "bb\na|a\ncc"))))

(ert-deftest mice-edit-test-move-selected-lines ()
  (mice-test-with-buffer #'text-mode "aa\nbb\ncc\ndd\n"
    (mice-test-select 4 9)
    (mice-test-press "M-<up>")
    (should (equal (mice-test-text) "[bb\ncc|]\naa\ndd\n"))
    (mice-test-press "M-<up>")
    (should (equal (mice-test-text) "[bb\ncc|]\naa\ndd\n"))))

(ert-deftest mice-edit-test-duplicate-line ()
  (mice-test-with-buffer #'text-mode "a|b\nc"
    (mice-test-press "C-d")
    (should (equal (buffer-string) "ab\nab\nc"))))

(ert-deftest mice-edit-test-comment-toggles ()
  (mice-test-with-buffer #'python-mode "x = |1\ny = 2\n"
    (mice-test-press "C-/")
    (should (equal (buffer-string) "# x = 1\ny = 2\n"))
    (mice-test-press "C-/")
    (should (equal (buffer-string) "x = 1\ny = 2\n"))))

(ert-deftest mice-edit-test-comment-without-syntax ()
  (mice-test-with-buffer #'fundamental-mode "a"
    (setq buffer-file-name "/nonexistent/notes")
    (run-hooks 'find-file-hook)
    (should-error (mice-test-press "C-/") :type 'user-error)
    (setq buffer-file-name nil)))

(ert-deftest mice-edit-test-delete-word-left ()
  (mice-test-with-buffer #'text-mode "foo bar|"
    (mice-test-press "M-DEL")
    (should (equal (mice-test-text) "foo |"))))

(provide 'mice-edit-test)
;;; mice-edit-test.el ends here
