;;; mice-mouse-test.el --- Tests for mice-mouse -*- lexical-binding: t; -*-

;;; Code:

(require 'mice-test-helpers)

(defun mice-mouse-test--event (type)
  "Return a mouse wheel event of TYPE over the selected window."
  (list type (list (selected-window) 1 '(0 . 0) 0)))

(ert-deftest mice-mouse-test-wheel-keys ()
  (mice-test-with-buffer #'text-mode ""
    (should (eq (key-binding [wheel-up]) #'mice-mouse-scroll-up))
    (should (eq (key-binding [wheel-down]) #'mice-mouse-scroll-down))
    (should (eq (key-binding [mouse-4]) #'mice-mouse-scroll-up))
    (should (eq (key-binding [mouse-5]) #'mice-mouse-scroll-down))))

(ert-deftest mice-mouse-test-wheel-scrolls-fixed-lines ()
  (mice-test-with-buffer #'text-mode ""
    (dotimes (i 200) (insert (format "line %d\n" i)))
    (goto-char (point-min))
    (set-window-buffer (selected-window) (current-buffer))
    (set-window-start (selected-window) (point-min))
    (let ((mice-mouse-scroll-lines 3))
      (mice-mouse-scroll-down (mice-mouse-test--event 'wheel-down))
      (should (= (line-number-at-pos (window-start)) 4)))))

(ert-deftest mice-mouse-test-wheel-stops-at-buffer-start ()
  (mice-test-with-buffer #'text-mode "a\nb|\nc"
    (set-window-buffer (selected-window) (current-buffer))
    (set-window-start (selected-window) (point-min))
    (mice-mouse-scroll-up (mice-mouse-test--event 'wheel-up))
    (should (equal (mice-test-text) "a\nb|\nc"))))

(ert-deftest mice-mouse-test-disabling-restores-mouse-mode ()
  (let ((before xterm-mouse-mode))
    (unwind-protect
        (progn
          (xterm-mouse-mode -1)
          (mice-mode 1)
          (should xterm-mouse-mode)
          (mice-mode -1)
          (should-not xterm-mouse-mode)
          (xterm-mouse-mode 1)
          (mice-mode 1)
          (mice-mode -1)
          (should xterm-mouse-mode))
      (mice-mode -1)
      (xterm-mouse-mode (if before 1 -1)))))

(provide 'mice-mouse-test)
;;; mice-mouse-test.el ends here
