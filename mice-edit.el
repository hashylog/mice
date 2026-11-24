;;; mice-edit.el --- Micro-style editing commands -*- lexical-binding: t; -*-

;;; Commentary:

;; Clipboard, undo, line and comment commands following Micro.  Without
;; a selection, copy and cut act on the whole current line, and
;; consecutive line cuts accumulate in the clipboard.

;;; Code:

(require 'subr-x)
(require 'mice-motion)

(defun mice--line-block ()
  "Return (BEG . END) of the whole lines covered by the selection or point.
A selection ending at the start of a line does not include that line."
  (let* ((region (use-region-p))
         (start (if region (region-beginning) (point)))
         (stop (if region (region-end) (point)))
         (beg (save-excursion (goto-char start) (line-beginning-position)))
         (end (save-excursion
                (goto-char stop)
                (if (and region (bolp) (> stop start))
                    (point)
                  (line-beginning-position 2)))))
    (cons beg end)))

(defun mice--line-text ()
  "Return the current line as clipboard text, always ending in a newline."
  (concat (buffer-substring (line-beginning-position) (line-end-position)) "\n"))

(defun mice-copy ()
  "Copy the selection, or the current line when nothing is selected."
  (interactive)
  (if (use-region-p)
      (progn
        (kill-new (filter-buffer-substring (region-beginning) (region-end)))
        (deactivate-mark))
    (kill-new (mice--line-text))
    (message "Copied line")))

(defun mice-cut-line ()
  "Cut the current line.  Consecutive line cuts accumulate."
  (interactive "*")
  (let ((text (mice--line-text))
        (beg (line-beginning-position))
        (end (line-beginning-position 2)))
    (when (and (= end (point-max))
               (not (eq (char-before end) ?\n))
               (> beg (point-min)))
      (setq beg (1- beg)))
    (if (eq last-command 'mice-cut-line)
        (kill-append text nil)
      (kill-new text))
    (delete-region beg end)
    (unless (bolp) (forward-line 0))
    (setq this-command 'mice-cut-line)))

(defun mice-cut ()
  "Cut the selection, or the current line when nothing is selected."
  (interactive "*")
  (if (use-region-p)
      (kill-new (filter-buffer-substring (region-beginning) (region-end) t))
    (mice-cut-line)))

(defun mice-paste ()
  "Paste the clipboard, replacing the selection."
  (interactive "*")
  (when (use-region-p)
    (delete-region (region-beginning) (region-end)))
  (insert-for-yank (current-kill 0)))

(defun mice-undo ()
  "Undo the last change."
  (interactive "*")
  (deactivate-mark)
  (undo-only))

(defun mice-redo ()
  "Redo the last undone change."
  (interactive "*")
  (deactivate-mark)
  (undo-redo))

(defun mice--move-lines (direction)
  "Move the selected lines, or the current line, up or down by DIRECTION."
  (pcase-let* ((`(,beg . ,end) (mice--line-block))
               (point-offset (- (point) beg))
               (mark-offset (and (region-active-p) (- (mark) beg)))
               (deactivate-mark nil)
               (moved nil))
    (cond
     ((and (> direction 0) (< end (point-max)))
      (let* ((next (save-excursion (goto-char end) (line-beginning-position 2)))
             (block (string-remove-suffix "\n" (buffer-substring beg end)))
             (below (buffer-substring end next))
             (line (string-remove-suffix "\n" below)))
        (delete-region beg next)
        (goto-char beg)
        (insert line "\n" block (if (string-suffix-p "\n" below) "\n" ""))
        (setq beg (+ beg (length line) 1)
              moved t)))
     ((and (< direction 0) (> beg (point-min)))
      (let* ((previous (save-excursion (goto-char beg) (line-beginning-position 0)))
             (above (string-remove-suffix "\n" (buffer-substring previous beg)))
             (text (buffer-substring beg end))
             (block (string-remove-suffix "\n" text)))
        (delete-region previous end)
        (goto-char previous)
        (insert block "\n" above (if (string-suffix-p "\n" text) "\n" ""))
        (setq beg previous
              moved t))))
    (when moved
      (goto-char (+ beg point-offset))
      (when mark-offset
        (set-mark (+ beg mark-offset))))))

(defun mice-move-lines-up ()
  "Move the selected lines, or the current line, one line up."
  (interactive "*")
  (mice--move-lines -1))

(defun mice-move-lines-down ()
  "Move the selected lines, or the current line, one line down."
  (interactive "*")
  (mice--move-lines 1))

(defun mice-duplicate ()
  "Duplicate the selection, or the current line when nothing is selected."
  (interactive "*")
  (duplicate-dwim))

(defun mice-comment ()
  "Toggle comments on the selected lines, or on the current line."
  (interactive "*")
  (unless comment-start
    (user-error "No comment syntax defined for this buffer"))
  (pcase-let ((`(,beg . ,end) (mice--line-block))
              (deactivate-mark nil))
    (save-excursion
      (comment-or-uncomment-region beg end))))

(defun mice-delete-word-left ()
  "Delete the selection, or back to the previous word boundary."
  (interactive "*")
  (if (use-region-p)
      (delete-region (region-beginning) (region-end))
    (let ((end (point)))
      (mice--word-left)
      (delete-region (point) end))))

(defun mice-delete-word-right ()
  "Delete the selection, or up to the next word boundary."
  (interactive "*")
  (if (use-region-p)
      (delete-region (region-beginning) (region-end))
    (let ((start (point)))
      (mice--word-right)
      (delete-region start (point)))))

(provide 'mice-edit)
;;; mice-edit.el ends here
