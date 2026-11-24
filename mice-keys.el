;;; mice-keys.el --- Micro-style keybindings -*- lexical-binding: t; -*-

;;; Commentary:

;; Every key belongs to a scope that decides where it is active:
;;
;; - edit:   editable buffers managed by mice
;; - view:   buffers managed by mice, including read-only ones
;; - copy:   like view, plus any buffer with an active selection
;; - global: every buffer except the minibuffer
;;
;; Outside its scope a key keeps its usual Emacs meaning.

;;; Code:

(require 'mice-indent)
(require 'mice-modes)
(require 'mice-motion)
(require 'mice-edit)
(require 'mice-search)
(require 'mice-commands)
(require 'mice-clipboard)
(require 'mice-mouse)

(defconst mice-keys--bindings
  '((edit "TAB" mice-insert-tab)
    (edit "<backtab>" mice-outdent)
    (edit "RET" mice-newline)
    (edit "DEL" mice-backspace)
    (edit "C-h" mice-backspace)
    (edit "C-<backspace>" mice-delete-word-left)
    (edit "M-DEL" mice-delete-word-left)
    (edit "C-M-h" mice-delete-word-left)
    (edit "C-<delete>" mice-delete-word-right)
    (edit "C-x" mice-cut)
    (edit "C-k" mice-cut-line)
    (edit "C-v" mice-paste)
    (edit "C-z" mice-undo)
    (edit "C-y" mice-redo)
    (edit "C-d" mice-duplicate)
    (edit "M-<up>" mice-move-lines-up)
    (edit "M-<down>" mice-move-lines-down)
    (edit "C-/" mice-comment)
    (edit "C-_" mice-comment)
    (edit "M-/" mice-comment)
    (edit "<xterm-paste>" mice-terminal-paste)

    (view "<left>" mice-left)
    (view "<right>" mice-right)
    (view "<up>" mice-up)
    (view "<down>" mice-down)
    (view "C-<left>" mice-word-left)
    (view "C-<right>" mice-word-right)
    (view "<home>" mice-home)
    (view "<end>" mice-end)
    (view "M-<left>" mice-home)
    (view "M-<right>" mice-end)
    (view "C-<up>" mice-buffer-start)
    (view "C-<down>" mice-buffer-end)
    (view "C-<home>" mice-buffer-start)
    (view "C-<end>" mice-buffer-end)
    (view "<prior>" mice-page-up)
    (view "<next>" mice-page-down)
    (view "S-<left>" mice-select-left)
    (view "S-<right>" mice-select-right)
    (view "S-<up>" mice-select-up)
    (view "S-<down>" mice-select-down)
    (view "C-S-<left>" mice-select-word-left)
    (view "C-S-<right>" mice-select-word-right)
    (view "S-<home>" mice-select-home)
    (view "S-<end>" mice-select-end)
    (view "M-S-<left>" mice-select-home)
    (view "M-S-<right>" mice-select-end)
    (view "C-S-<up>" mice-select-buffer-start)
    (view "C-S-<down>" mice-select-buffer-end)
    (view "C-S-<home>" mice-select-buffer-start)
    (view "C-S-<end>" mice-select-buffer-end)
    (view "S-<prior>" mice-select-page-up)
    (view "S-<next>" mice-select-page-down)
    (view "C-a" mice-select-all)
    (view "C-s" save-buffer)
    (view "C-u" mice-toggle-macro)
    (view "C-j" mice-play-macro)

    (copy "C-c" mice-copy)

    (global "C-o" find-file)
    (global "C-q" mice-close)
    (global "M-q" mice-quit)
    (global "C-e" execute-extended-command)
    (global "C-f" mice-find)
    (global "C-n" mice-find-next)
    (global "C-p" mice-find-previous)
    (global "C-l" goto-line)
    (global "C-w" other-window)
    (global "C-r" mice-toggle-ruler)
    (global "<wheel-up>" mice-mouse-scroll-up)
    (global "<wheel-down>" mice-mouse-scroll-down)
    (global "<mouse-4>" mice-mouse-scroll-up)
    (global "<mouse-5>" mice-mouse-scroll-down))
  "Entries (SCOPE KEY COMMAND) defining `mice-mode-map'.")

(defun mice-keys--edit-filter (command)
  "Return COMMAND in editable buffers managed by mice."
  (and mice--managed (not buffer-read-only) command))

(defun mice-keys--view-filter (command)
  "Return COMMAND in buffers managed by mice."
  (and mice--managed command))

(defun mice-keys--copy-filter (command)
  "Return COMMAND in managed buffers or when a selection is active."
  (and (not (minibufferp))
       (or mice--managed (use-region-p))
       command))

(defun mice-keys--global-filter (command)
  "Return COMMAND outside the minibuffer."
  (and (not (minibufferp)) command))

(defun mice-keys--make-map ()
  "Build the keymap described by `mice-keys--bindings'."
  (let ((map (make-sparse-keymap)))
    (pcase-dolist (`(,scope ,key ,command) mice-keys--bindings)
      (keymap-set map key
                  `(menu-item "" ,command
                              :filter ,(intern (format "mice-keys--%s-filter" scope)))))
    map))

(defvar mice-mode-map (mice-keys--make-map)
  "Keymap of `mice-mode', taking priority over every other keymap.")

(provide 'mice-keys)
;;; mice-keys.el ends here
