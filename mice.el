;;; mice.el --- Micro-inspired editing for Emacs -*- lexical-binding: t; -*-

;; Author: hashylog
;; Version: 0.1.0
;; Package-Requires: ((emacs "30.1"))
;; Keywords: emulations, convenience
;; URL: https://github.com/hashylog/mice

;;; Commentary:

;; mice changes how Emacs edits text so that it behaves like the Micro
;; editor, the same way Evil makes Emacs behave like Vim.  Enable it
;; with (mice-mode 1).

;;; Code:

(defgroup mice nil
  "Micro-inspired editing for Emacs."
  :group 'emulations
  :prefix "mice-")

(require 'mice-indent)
(require 'mice-modes)

(defun mice--editing-filter (command)
  "Return COMMAND when the current buffer is an editable managed buffer."
  (and mice--managed (not buffer-read-only) command))

(defun mice--editing-binding (command)
  "Return a binding for COMMAND active only in editable managed buffers."
  `(menu-item "" ,command :filter mice--editing-filter))

(defvar mice-mode-map
  (let ((map (make-sparse-keymap)))
    (keymap-set map "TAB" (mice--editing-binding #'mice-insert-tab))
    (keymap-set map "<backtab>" (mice--editing-binding #'mice-outdent))
    (keymap-set map "RET" (mice--editing-binding #'mice-newline))
    (keymap-set map "DEL" (mice--editing-binding #'mice-backspace))
    map)
  "Keymap of `mice-mode', taking priority over every other keymap.")

(defvar mice--emulation-alist `((mice-mode . ,mice-mode-map))
  "Entry for `emulation-mode-map-alists'.")

;;;###autoload
(define-minor-mode mice-mode
  "Toggle Micro-inspired editing in every buffer."
  :global t
  :group 'mice
  (if mice-mode
      (progn
        (add-to-list 'emulation-mode-map-alists 'mice--emulation-alist)
        (mice-modes-enable))
    (setq emulation-mode-map-alists
          (delq 'mice--emulation-alist emulation-mode-map-alists))
    (mice-modes-disable)))

(provide 'mice)
;;; mice.el ends here
