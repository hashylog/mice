;;; mice-indent.el --- Micro-style indentation commands -*- lexical-binding: t; -*-

;;; Commentary:

;; Indentation that behaves the same in every buffer, following Micro:
;; TAB inserts up to the next tab stop, RET copies the current line's
;; indentation, and BACKSPACE removes whole indentation levels.

;;; Code:

(defun mice--indent-string ()
  "Return the string for one indentation level."
  (if indent-tabs-mode "\t" (make-string tab-width ?\s)))

(defun mice--map-region-lines (function)
  "Call FUNCTION at the start of every line covered by the region."
  (let ((end (copy-marker (region-end)))
        (deactivate-mark nil))
    (save-excursion
      (goto-char (region-beginning))
      (forward-line 0)
      (while (< (point) end)
        (funcall function)
        (forward-line 1)))
    (set-marker end nil)))

(defun mice--indent-line-once ()
  "Add one indentation level at the start of the current line."
  (forward-line 0)
  (insert (mice--indent-string)))

(defun mice--outdent-line-once ()
  "Remove one indentation level from the start of the current line."
  (forward-line 0)
  (if (eq (char-after) ?\t)
      (delete-char 1)
    (let ((count 0))
      (while (and (< count tab-width)
                  (eq (char-after (+ (point) count)) ?\s))
        (setq count (1+ count)))
      (delete-char count))))

(defun mice-indent-line ()
  "Indent the current line like the previous non-blank line.
Used as `indent-line-function' in buffers managed by mice."
  (let ((column (save-excursion
                  (forward-line 0)
                  (if (re-search-backward "^[ \t]*[^ \t\n]" nil t)
                      (current-indentation)
                    0))))
    (if (> (current-column) (current-indentation))
        (save-excursion (indent-line-to column))
      (indent-line-to column))))

(defun mice-insert-tab ()
  "Indent the selection, or insert indentation up to the next tab stop."
  (interactive "*")
  (cond
   ((use-region-p)
    (mice--map-region-lines #'mice--indent-line-once))
   (indent-tabs-mode
    (insert "\t"))
   (t
    (insert (make-string (- tab-width (% (current-column) tab-width)) ?\s)))))

(defun mice-outdent ()
  "Remove one indentation level from the selection or the current line."
  (interactive "*")
  (if (use-region-p)
      (mice--map-region-lines #'mice--outdent-line-once)
    (save-excursion (mice--outdent-line-once))))

(defun mice-newline ()
  "Insert a newline that keeps the current line's indentation.
A line left containing only whitespace is cleared."
  (interactive "*")
  (when (use-region-p)
    (delete-region (region-beginning) (region-end)))
  (let ((indent (buffer-substring
                 (line-beginning-position)
                 (min (point)
                      (save-excursion
                        (forward-line 0)
                        (skip-chars-forward " \t")
                        (point))))))
    (insert "\n" indent)
    (save-excursion
      (forward-line -1)
      (when (looking-at "[ \t]+$")
        (delete-region (point) (line-end-position))))))

(defun mice-backspace ()
  "Delete the selection, one indentation level, or the previous character."
  (interactive "*")
  (undo-auto-amalgamate)
  (cond
   ((use-region-p)
    (delete-region (region-beginning) (region-end)))
   ((bobp))
   ((and (not indent-tabs-mode)
         (> (current-column) 0)
         (zerop (% (current-column) tab-width))
         (save-excursion
           (skip-chars-backward " " (line-beginning-position))
           (bolp)))
    (delete-char (- tab-width)))
   (t
    (delete-char -1))))

(provide 'mice-indent)
;;; mice-indent.el ends here
