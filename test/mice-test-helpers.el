;;; mice-test-helpers.el --- Shared helpers for mice tests -*- lexical-binding: t; -*-

;;; Code:

(require 'ert)
(require 'mice)
(require 'python)
(require 'help-mode)

(setq python-indent-guess-indent-offset-verbose nil)
(transient-mark-mode 1)

(defmacro mice-test-with-buffer (mode content &rest body)
  "Run BODY with `mice-mode' on, in a MODE buffer holding CONTENT.
Point starts where CONTENT has a | character."
  (declare (indent 2))
  `(let ((kill-ring nil)
         (kill-ring-yank-pointer nil)
         (interprogram-cut-function nil)
         (interprogram-paste-function nil)
         (regexp-search-ring nil)
         (last-command nil))
     (with-temp-buffer
       (buffer-enable-undo)
       (insert ,content)
       (goto-char (point-min))
       (when (search-forward "|" nil t)
         (delete-char -1))
       (unwind-protect
           (progn
             (mice-mode 1)
             (funcall ,mode)
             (setq-local tab-width 4
                         indent-tabs-mode nil)
             ,@body)
         (mice-mode -1)))))

(defun mice-test-press (key)
  "Run the command bound to KEY like the command loop would."
  (let* ((keys (kbd key))
         (command (key-binding keys)))
    (unless (commandp command)
      (error "%s is not bound to a command: %S" key command))
    (undo-boundary)
    (setq this-command command
          last-command-event (aref keys (1- (length keys)))
          deactivate-mark nil)
    (run-hooks 'pre-command-hook)
    (call-interactively command)
    (when deactivate-mark
      (deactivate-mark))
    (setq last-command this-command)))

(defun mice-test-select (from to)
  "Select from FROM to TO, leaving point at TO."
  (goto-char from)
  (set-mark from)
  (goto-char to)
  (activate-mark))

(defun mice-test-text ()
  "Return the buffer text with | at point and [ ] around the selection."
  (let ((text (buffer-string))
        (point (1- (point))))
    (if (region-active-p)
        (let ((beg (1- (region-beginning)))
              (end (1- (region-end))))
          (concat (substring text 0 beg)
                  "[" (if (= point beg) "|" "")
                  (substring text beg end)
                  (if (= point end) "|" "") "]"
                  (substring text end)))
      (concat (substring text 0 point) "|" (substring text point)))))

(provide 'mice-test-helpers)
;;; mice-test-helpers.el ends here
