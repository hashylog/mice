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

(require 'delsel)
(require 'mice-keys)

(defvar mice--emulation-alist `((mice-mode . ,mice-mode-map))
  "Entry for `emulation-mode-map-alists'.")

(defvar mice--saved-delete-selection-mode nil
  "State of `delete-selection-mode' before `mice-mode' was enabled.")

;;;###autoload
(define-minor-mode mice-mode
  "Toggle Micro-inspired editing in every buffer."
  :global t
  :group 'mice
  (if mice-mode
      (progn
        (unless (memq 'mice--emulation-alist emulation-mode-map-alists)
          (setq mice--saved-delete-selection-mode delete-selection-mode)
          (push 'mice--emulation-alist emulation-mode-map-alists))
        (delete-selection-mode 1)
        (mice-search-enable)
        (mice-modes-enable))
    (when (memq 'mice--emulation-alist emulation-mode-map-alists)
      (setq emulation-mode-map-alists
            (delq 'mice--emulation-alist emulation-mode-map-alists))
      (unless mice--saved-delete-selection-mode
        (delete-selection-mode -1)))
    (mice-search-disable)
    (mice-modes-disable)))

(provide 'mice)
;;; mice.el ends here
