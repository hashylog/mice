;;; mice-mouse.el --- Mouse support in the terminal -*- lexical-binding: t; -*-

;;; Commentary:

;; Enables the mouse in terminal frames: clicking moves the cursor,
;; dragging selects, double and triple clicks select a word and a line,
;; and the wheel scrolls the window under the pointer by a fixed amount.

;;; Code:

(require 'xt-mouse)

(defcustom mice-mouse-scroll-lines 2
  "Number of lines scrolled by one mouse wheel step."
  :type 'integer
  :group 'mice)

(defvar mice-mouse--saved-xterm-mouse-mode nil
  "State of `xterm-mouse-mode' before mice enabled it.")

(defvar mice-mouse--enabled nil
  "Non-nil while mice controls the mouse.")

(defun mice-mouse--scroll (event lines)
  "Scroll the window under mouse EVENT by LINES, negative meaning up."
  (let ((window (posn-window (event-start event))))
    (when (window-live-p window)
      (with-selected-window window
        (condition-case nil
            (if (< lines 0) (scroll-down (- lines)) (scroll-up lines))
          ((beginning-of-buffer end-of-buffer) nil))))))

(defun mice-mouse-scroll-up (event)
  "Scroll the window under the mouse up."
  (interactive "e")
  (mice-mouse--scroll event (- mice-mouse-scroll-lines)))

(defun mice-mouse-scroll-down (event)
  "Scroll the window under the mouse down."
  (interactive "e")
  (mice-mouse--scroll event mice-mouse-scroll-lines))

(defun mice-mouse-enable ()
  "Enable the mouse in terminal frames."
  (unless mice-mouse--enabled
    (setq mice-mouse--saved-xterm-mouse-mode xterm-mouse-mode
          mice-mouse--enabled t)
    (xterm-mouse-mode 1)))

(defun mice-mouse-disable ()
  "Restore the previous mouse state."
  (when mice-mouse--enabled
    (unless mice-mouse--saved-xterm-mouse-mode
      (xterm-mouse-mode -1))
    (setq mice-mouse--enabled nil)))

(provide 'mice-mouse)
;;; mice-mouse.el ends here
