;;; mice-search-test.el --- Tests for mice-search -*- lexical-binding: t; -*-

;;; Code:

(require 'mice-test-helpers)

(ert-deftest mice-search-test-find-next-selects-and-wraps ()
  (mice-test-with-buffer #'text-mode "foo |bar foo bar"
    (push "foo" regexp-search-ring)
    (mice-test-press "C-n")
    (should (equal (mice-test-text) "foo bar [foo|] bar"))
    (mice-test-press "C-n")
    (should (equal (mice-test-text) "[foo|] bar foo bar"))))

(ert-deftest mice-search-test-find-previous ()
  (mice-test-with-buffer #'text-mode "foo bar foo |bar"
    (push "foo" regexp-search-ring)
    (mice-test-press "C-p")
    (should (equal (mice-test-text) "foo bar [|foo] bar"))
    (mice-test-press "C-p")
    (should (equal (mice-test-text) "[|foo] bar foo bar"))))

(ert-deftest mice-search-test-not-found ()
  (mice-test-with-buffer #'text-mode "ab|c"
    (push "zzz" regexp-search-ring)
    (should-error (mice-test-press "C-n") :type 'user-error)
    (should (equal (mice-test-text) "ab|c"))))

(ert-deftest mice-search-test-finished-search-selects-match ()
  (mice-test-with-buffer #'text-mode "foo bar|"
    (let ((isearch-mode-end-hook-quit nil)
          (isearch-other-end 5)
          (isearch-string "bar"))
      (run-hooks 'isearch-mode-end-hook))
    (should (equal (mice-test-text) "foo [bar|]"))))

(provide 'mice-search-test)
;;; mice-search-test.el ends here
