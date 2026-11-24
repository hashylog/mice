;;; mice-commands.el --- Micro-style editor commands -*- lexical-binding: t; -*-

;;; Commentary:

;; Commands that act on buffers and the editor as a whole: closing,
;; quitting and recording macros.

;;; Code:

(require 'kmacro)

(defun mice--other-file-buffers-p ()
  "Return non-nil if a live file buffer other than the current one exists."
  (seq-some (lambda (buffer)
              (and (not (eq buffer (current-buffer)))
                   (buffer-file-name buffer)))
            (buffer-list)))

(defun mice-close ()
  "Close the current buffer, quitting Emacs when nothing else is open.
A split showing the buffer is closed as well."
  (interactive)
  (when (and buffer-file-name (buffer-modified-p))
    (if (y-or-n-p (format "Save changes to %s before closing? " (buffer-name)))
        (save-buffer)
      (set-buffer-modified-p nil)))
  (cond
   ((not (one-window-p))
    (kill-buffer)
    (delete-window))
   ((mice--other-file-buffers-p)
    (kill-buffer))
   (t
    (mice-quit))))

(defun mice-quit ()
  "Offer to save every modified file, then quit Emacs."
  (interactive)
  (save-some-buffers)
  (kill-emacs))

(defun mice-toggle-macro ()
  "Start recording a keyboard macro, or stop the current recording."
  (interactive)
  (if defining-kbd-macro
      (kmacro-end-macro nil)
    (kmacro-start-macro nil)))

(defun mice-play-macro ()
  "Play the last recorded keyboard macro."
  (interactive)
  (kmacro-call-macro nil))

(defun mice-toggle-ruler ()
  "Toggle line numbers."
  (interactive)
  (display-line-numbers-mode 'toggle))

(provide 'mice-commands)
;;; mice-commands.el ends here
