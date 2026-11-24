;;; mice-search.el --- Micro-style search -*- lexical-binding: t; -*-

;;; Commentary:

;; Find uses incremental regexp search.  A finished search selects the
;; match, and find next or previous repeat the last search with
;; wrap-around, selecting each match.

;;; Code:

(require 'isearch)

(defconst mice-search--bindings
  '(("<down>" . isearch-repeat-forward)
    ("<up>" . isearch-repeat-backward)
    ("C-n" . isearch-repeat-forward)
    ("C-p" . isearch-repeat-backward)
    ("C-f" . isearch-repeat-forward)
    ("C-v" . isearch-yank-kill))
  "Keys bound in `isearch-mode-map' while `mice-mode' is on.")

(defvar mice-search--saved-bindings nil
  "Bindings of `isearch-mode-map' replaced by mice.")

(defun mice-find ()
  "Search forward incrementally for a regular expression."
  (interactive)
  (deactivate-mark)
  (isearch-forward-regexp))

(defun mice--select-match ()
  "Select the match of a search that finished normally."
  (when (and (not isearch-mode-end-hook-quit)
             isearch-other-end
             (not (string-empty-p isearch-string)))
    (set-mark isearch-other-end)))

(defun mice--find-again (forward)
  "Select the next match of the last search, FORWARD or backward."
  (let ((regexp (car regexp-search-ring)))
    (unless regexp
      (user-error "No previous search"))
    (let ((start (if (region-active-p)
                     (if forward (region-end) (region-beginning))
                   (point)))
          (search (if forward #'re-search-forward #'re-search-backward)))
      (deactivate-mark)
      (goto-char start)
      (unless (or (funcall search regexp nil t)
                  (progn
                    (goto-char (if forward (point-min) (point-max)))
                    (funcall search regexp nil t)))
        (goto-char start)
        (user-error "Not found: %s" regexp))
      (if forward
          (progn (set-mark (match-beginning 0)) (goto-char (match-end 0)))
        (set-mark (match-end 0))
        (goto-char (match-beginning 0))))))

(defun mice-find-next ()
  "Select the next match of the last search."
  (interactive)
  (mice--find-again t))

(defun mice-find-previous ()
  "Select the previous match of the last search."
  (interactive)
  (mice--find-again nil))

(defun mice-search-enable ()
  "Install the search keys and match selection."
  (unless mice-search--saved-bindings
    (dolist (binding mice-search--bindings)
      (push (cons (car binding) (keymap-lookup isearch-mode-map (car binding)))
            mice-search--saved-bindings)
      (keymap-set isearch-mode-map (car binding) (cdr binding))))
  (add-hook 'isearch-mode-end-hook #'mice--select-match))

(defun mice-search-disable ()
  "Restore the original search keys."
  (pcase-dolist (`(,key . ,command) mice-search--saved-bindings)
    (keymap-set isearch-mode-map key command))
  (setq mice-search--saved-bindings nil)
  (remove-hook 'isearch-mode-end-hook #'mice--select-match))

(provide 'mice-search)
;;; mice-search.el ends here
