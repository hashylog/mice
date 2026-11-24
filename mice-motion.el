;;; mice-motion.el --- Micro-style cursor movement and selection -*- lexical-binding: t; -*-

;;; Commentary:

;; Cursor movement and selection following Micro: plain movement
;; collapses the selection, shifted movement extends it, and word
;; movement uses Micro's word boundaries.

;;; Code:

(defun mice--start-selection ()
  "Start a selection at point unless one is already active."
  (unless (region-active-p)
    (set-mark (point))))

(defun mice--collapse-selection (to-end)
  "Deactivate the selection, leaving point at its end if TO-END is non-nil.
Return non-nil if there was a selection."
  (when (region-active-p)
    (goto-char (if to-end (region-end) (region-beginning)))
    (deactivate-mark)
    t))

(defun mice--line (count)
  "Move COUNT lines, keeping the goal column across consecutive moves."
  (setq this-command (if (< count 0) 'previous-line 'next-line))
  (line-move count t))

(defun mice--page (direction)
  "Move one page up when DIRECTION is negative, down otherwise."
  (condition-case nil
      (if (< direction 0) (scroll-down-command) (scroll-up-command))
    (beginning-of-buffer (goto-char (point-min)))
    (end-of-buffer (goto-char (point-max)))))

(defun mice--home ()
  "Toggle point between the first non-blank character and the line start."
  (let ((indentation (save-excursion (back-to-indentation) (point))))
    (goto-char (if (= (point) indentation) (line-beginning-position) indentation))))

;;; Micro word boundaries

(defun mice--mark-char-p (char)
  "Return non-nil when CHAR is a Unicode combining mark."
  (memq (and char (get-char-code-property char 'general-category))
        '(Mn Mc Me)))

(defun mice--word-char-p (char)
  "Return non-nil when CHAR belongs to a Micro word."
  (or (eq char ?_)
      (memq (and char (get-char-code-property char 'general-category))
            '(Lu Ll Lt Lm Lo Nd Nl No))))

(defun mice--whitespace-p (char)
  "Return non-nil when CHAR is whitespace according to Micro."
  (and char
       (or (memq char '(9 10 11 12 13 32 133 160 5760 8232 8233 8239 8287 12288))
           (<= 8192 char 8202))))

(defun mice--forward-character ()
  "Move over one character, including its combining marks."
  (unless (eobp)
    (forward-char)
    (while (and (not (eobp)) (mice--mark-char-p (char-after)))
      (forward-char))))

(defun mice--backward-character ()
  "Move back over one character, including its combining marks."
  (unless (bobp)
    (backward-char)
    (while (and (not (bobp)) (mice--mark-char-p (char-after)))
      (backward-char))))

(defun mice--next-character ()
  "Return the character following the one at point."
  (save-excursion
    (mice--forward-character)
    (char-after)))

(defun mice--previous-character ()
  "Return the character before point, clamped at the line start."
  (save-excursion
    (unless (bolp)
      (mice--backward-character))
    (char-after)))

(defun mice--word-right ()
  "Move right using Micro's WordRight algorithm."
  (catch 'done
    (when (eobp)
      (throw 'done nil))
    (when (eolp)
      (mice--forward-character)
      (throw 'done nil))
    (while (mice--whitespace-p (char-after))
      (when (eolp)
        (throw 'done nil))
      (mice--forward-character))
    (when (and (not (mice--word-char-p (char-after)))
               (not (mice--whitespace-p (char-after)))
               (not (mice--word-char-p (mice--next-character))))
      (while (and (not (mice--word-char-p (char-after)))
                  (not (mice--whitespace-p (char-after))))
        (when (eolp)
          (throw 'done nil))
        (mice--forward-character))
      (throw 'done nil))
    (mice--forward-character)
    (while (mice--word-char-p (char-after))
      (when (eolp)
        (throw 'done nil))
      (mice--forward-character))))

(defun mice--word-left ()
  "Move left using Micro's WordLeft algorithm."
  (catch 'done
    (when (bobp)
      (throw 'done nil))
    (when (bolp)
      (mice--backward-character)
      (throw 'done nil))
    (mice--backward-character)
    (while (mice--whitespace-p (char-after))
      (when (bolp)
        (throw 'done nil))
      (mice--backward-character))
    (when (and (not (mice--word-char-p (char-after)))
               (not (mice--whitespace-p (char-after)))
               (not (mice--word-char-p (mice--previous-character))))
      (while (and (not (mice--word-char-p (char-after)))
                  (not (mice--whitespace-p (char-after))))
        (when (bolp)
          (throw 'done nil))
        (mice--backward-character))
      (mice--forward-character)
      (throw 'done nil))
    (mice--backward-character)
    (while (mice--word-char-p (char-after))
      (when (bolp)
        (throw 'done nil))
      (mice--backward-character))
    (mice--forward-character)))

;;; Movement commands

(defun mice-left ()
  "Move left, or collapse the selection to its start."
  (interactive)
  (unless (mice--collapse-selection nil)
    (mice--backward-character)))

(defun mice-right ()
  "Move right, or collapse the selection to its end."
  (interactive)
  (unless (mice--collapse-selection t)
    (mice--forward-character)))

(defun mice-up ()
  "Move up from the start of the selection or from point."
  (interactive)
  (mice--collapse-selection nil)
  (mice--line -1))

(defun mice-down ()
  "Move down from the end of the selection or from point."
  (interactive)
  (mice--collapse-selection t)
  (mice--line 1))

(defun mice-word-left ()
  "Move to the previous word boundary."
  (interactive)
  (mice--collapse-selection nil)
  (mice--word-left))

(defun mice-word-right ()
  "Move to the next word boundary."
  (interactive)
  (mice--collapse-selection t)
  (mice--word-right))

(defun mice-home ()
  "Toggle between the first non-blank character and the line start."
  (interactive)
  (mice--collapse-selection nil)
  (mice--home))

(defun mice-end ()
  "Move to the end of the line."
  (interactive)
  (mice--collapse-selection t)
  (end-of-line))

(defun mice-buffer-start ()
  "Move to the start of the buffer."
  (interactive)
  (deactivate-mark)
  (goto-char (point-min)))

(defun mice-buffer-end ()
  "Move to the end of the buffer."
  (interactive)
  (deactivate-mark)
  (goto-char (point-max)))

(defun mice-page-up ()
  "Move one page up."
  (interactive)
  (mice--collapse-selection nil)
  (mice--page -1))

(defun mice-page-down ()
  "Move one page down."
  (interactive)
  (mice--collapse-selection t)
  (mice--page 1))

;;; Selection commands

(defun mice-select-left ()
  "Extend the selection one character left."
  (interactive)
  (mice--start-selection)
  (mice--backward-character))

(defun mice-select-right ()
  "Extend the selection one character right."
  (interactive)
  (mice--start-selection)
  (mice--forward-character))

(defun mice-select-up ()
  "Extend the selection one line up."
  (interactive)
  (mice--start-selection)
  (mice--line -1))

(defun mice-select-down ()
  "Extend the selection one line down."
  (interactive)
  (mice--start-selection)
  (mice--line 1))

(defun mice-select-word-left ()
  "Extend the selection to the previous word boundary."
  (interactive)
  (mice--start-selection)
  (mice--word-left))

(defun mice-select-word-right ()
  "Extend the selection to the next word boundary."
  (interactive)
  (mice--start-selection)
  (mice--word-right))

(defun mice-select-home ()
  "Extend the selection to the first non-blank character or line start."
  (interactive)
  (mice--start-selection)
  (mice--home))

(defun mice-select-end ()
  "Extend the selection to the end of the line."
  (interactive)
  (mice--start-selection)
  (end-of-line))

(defun mice-select-buffer-start ()
  "Extend the selection to the start of the buffer."
  (interactive)
  (mice--start-selection)
  (goto-char (point-min)))

(defun mice-select-buffer-end ()
  "Extend the selection to the end of the buffer."
  (interactive)
  (mice--start-selection)
  (goto-char (point-max)))

(defun mice-select-page-up ()
  "Extend the selection one page up."
  (interactive)
  (mice--start-selection)
  (mice--page -1))

(defun mice-select-page-down ()
  "Extend the selection one page down."
  (interactive)
  (mice--start-selection)
  (mice--page 1))

(defun mice-select-all ()
  "Select the whole buffer."
  (interactive)
  (set-mark (point-min))
  (goto-char (point-max)))

(provide 'mice-motion)
;;; mice-motion.el ends here
