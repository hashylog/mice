;;; mice-motion-test.el --- Tests for mice-motion -*- lexical-binding: t; -*-

;;; Code:

(require 'mice-test-helpers)

(ert-deftest mice-motion-test-arrows-collapse-selection ()
  (mice-test-with-buffer #'text-mode "abcdef"
    (mice-test-select 2 5)
    (mice-test-press "<left>")
    (should (equal (mice-test-text) "a|bcdef"))
    (mice-test-select 2 5)
    (mice-test-press "<right>")
    (should (equal (mice-test-text) "abcd|ef"))))

(ert-deftest mice-motion-test-shift-arrows-select ()
  (mice-test-with-buffer #'text-mode "ab|cdef"
    (mice-test-press "S-<right>")
    (mice-test-press "S-<right>")
    (should (equal (mice-test-text) "ab[cd|]ef"))
    (mice-test-press "S-<left>")
    (should (equal (mice-test-text) "ab[c|]def"))))

(ert-deftest mice-motion-test-vertical-moves-keep-goal-column ()
  (mice-test-with-buffer #'text-mode "abcde|f\nab\nabcdefgh"
    (mice-test-press "<down>")
    (should (equal (mice-test-text) "abcdef\nab|\nabcdefgh"))
    (mice-test-press "<down>")
    (should (equal (mice-test-text) "abcdef\nab\nabcde|fgh"))))

(ert-deftest mice-motion-test-up-starts-from-selection-start ()
  (mice-test-with-buffer #'text-mode "abc\nabc\nabc"
    (mice-test-select 6 10)
    (mice-test-press "<up>")
    (should (equal (mice-test-text) "a|bc\nabc\nabc"))))

(ert-deftest mice-motion-test-home-toggles ()
  (mice-test-with-buffer #'text-mode "    ab|c"
    (mice-test-press "<home>")
    (should (equal (mice-test-text) "    |abc"))
    (mice-test-press "<home>")
    (should (equal (mice-test-text) "|    abc"))
    (mice-test-press "<home>")
    (should (equal (mice-test-text) "    |abc"))))

(ert-deftest mice-motion-test-select-to-end ()
  (mice-test-with-buffer #'text-mode "ab|cd\nef"
    (mice-test-press "S-<end>")
    (should (equal (mice-test-text) "ab[cd|]\nef"))))

(ert-deftest mice-motion-test-word-right ()
  (mice-test-with-buffer #'text-mode "|foo.bar baz"
    (let (stops)
      (dotimes (_ 3)
        (mice-test-press "C-<right>")
        (push (1- (point)) stops))
      (should (equal (nreverse stops) '(3 7 11))))))

(ert-deftest mice-motion-test-word-left ()
  (mice-test-with-buffer #'text-mode "foo.bar baz|"
    (let (stops)
      (dotimes (_ 3)
        (mice-test-press "C-<left>")
        (push (1- (point)) stops))
      (should (equal (nreverse stops) '(8 4 0))))))

(ert-deftest mice-motion-test-select-word ()
  (mice-test-with-buffer #'text-mode "|foo bar"
    (mice-test-press "C-S-<right>")
    (should (equal (mice-test-text) "[foo|] bar"))))

(ert-deftest mice-motion-test-buffer-start-and-end ()
  (mice-test-with-buffer #'text-mode "a\nb|\nc"
    (mice-test-press "C-<down>")
    (should (equal (mice-test-text) "a\nb\nc|"))
    (mice-test-press "C-<up>")
    (should (equal (mice-test-text) "|a\nb\nc"))))

(ert-deftest mice-motion-test-select-all ()
  (mice-test-with-buffer #'text-mode "a|b"
    (mice-test-press "C-a")
    (should (equal (mice-test-text) "[ab|]"))))

(provide 'mice-motion-test)
;;; mice-motion-test.el ends here
