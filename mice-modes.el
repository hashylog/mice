;;; mice-modes.el --- Reduce major modes to syntax providers -*- lexical-binding: t; -*-

;;; Commentary:

;; Major modes keep providing syntax highlighting, comment syntax and
;; the language identity used by tools such as LSP.  In buffers managed
;; by mice they lose their keymaps and their indentation rules, so that
;; editing behaves the same regardless of the file type.

;;; Code:

(require 'mice-indent)

(defcustom mice-preserved-modes nil
  "Major modes that mice leaves untouched, including derived modes."
  :type '(repeat symbol)
  :group 'mice)

(defvar mice-neutral-map (make-sparse-keymap)
  "Local keymap that replaces major mode keymaps in managed buffers.")

(defvar-local mice--managed nil
  "Non-nil when the current buffer is managed by mice.")

(defvar-local mice--saved-local-map nil
  "Local keymap the buffer had before mice managed it.")

(defvar-local mice--saved-variables nil
  "Entries (VARIABLE LOCALP VALUE) to restore when mice releases the buffer.")

(defun mice-managed-buffer-p ()
  "Return non-nil if mice should manage editing in the current buffer."
  (and (not (minibufferp))
       (not (derived-mode-p 'special-mode))
       (not (derived-mode-p mice-preserved-modes))
       (or buffer-file-name
           (derived-mode-p '(prog-mode text-mode conf-mode)))))

(defun mice--set-local (variable value)
  "Set VARIABLE to VALUE locally, remembering its previous state."
  (unless (assq variable mice--saved-variables)
    (push (list variable (local-variable-p variable) (symbol-value variable))
          mice--saved-variables))
  (set (make-local-variable variable) value))

(defun mice-modes--manage ()
  "Take control of editing in the current buffer if appropriate."
  (when (and (not mice--managed) (mice-managed-buffer-p))
    (setq mice--saved-local-map (current-local-map))
    (use-local-map mice-neutral-map)
    (mice--set-local 'indent-line-function #'mice-indent-line)
    (mice--set-local 'electric-indent-mode nil)
    (setq mice--managed t)))

(defun mice-modes--release ()
  "Give editing in the current buffer back to its major mode."
  (when mice--managed
    (use-local-map mice--saved-local-map)
    (pcase-dolist (`(,variable ,localp ,value) mice--saved-variables)
      (if localp
          (set (make-local-variable variable) value)
        (kill-local-variable variable)))
    (setq mice--saved-local-map nil
          mice--saved-variables nil
          mice--managed nil)))

(defconst mice-modes--hooks
  '(after-change-major-mode-hook
    find-file-hook
    after-set-visited-file-name-hook)
  "Hooks after which a buffer may need to be managed.")

(defun mice-modes-enable ()
  "Manage existing and future buffers."
  (dolist (hook mice-modes--hooks)
    (add-hook hook #'mice-modes--manage))
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (mice-modes--manage))))

(defun mice-modes-disable ()
  "Release every managed buffer and stop managing new ones."
  (dolist (hook mice-modes--hooks)
    (remove-hook hook #'mice-modes--manage))
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (mice-modes--release))))

(provide 'mice-modes)
;;; mice-modes.el ends here
