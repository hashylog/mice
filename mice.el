;;; mice.el --- Micro-Inspired Configuration for Emacs -*- lexical-binding: t; -*-

;;; User options

(defcustom my/indent-width 4
  "Default indentation and tab display width."
  :type 'integer)

(defcustom my/mouse-scroll-lines 3
  "Number of lines scrolled by one mouse wheel event."
  :type 'integer)

;; General shortcuts. Change the key strings here, not in the implementation.
(defcustom my/global-keybindings
  '(("C-s" . save-buffer)
    ("C-S-s" . write-file)
    ("C-f" . consult-line)
    ("C-S-f" . consult-ripgrep)
    ("M-s l" . consult-line)
    ("M-s r" . consult-ripgrep)
    ("M-y" . consult-yank-pop)
    ("C-z" . undo-only)
    ("C-y" . undo-redo)
    ("C-d" . my/duplicate-line-or-region)
    ("C-/" . comment-line)
    ("<left>" . my/move-left)
    ("<right>" . my/move-right)
    ("<up>" . my/move-up)
    ("<down>" . my/move-down)
    ("<S-left>" . my/select-left)
    ("<S-right>" . my/select-right)
    ("<S-up>" . my/select-up)
    ("<S-down>" . my/select-down)
    ("C-<left>" . my/micro-word-left)
    ("C-<right>" . my/micro-word-right)
    ("C-S-<left>" . my/select-word-left)
    ("C-S-<right>" . my/select-word-right)
    ("C-<backspace>" . my/micro-delete-word-left)
    ("C-DEL" . my/micro-delete-word-left)
    ("M-<backspace>" . my/micro-delete-word-left)
    ("M-DEL" . my/micro-delete-word-left)
    ("M-C-h" . my/micro-delete-word-left)
    ("<wheel-up>" . my/mouse-wheel-up)
    ("<wheel-down>" . my/mouse-wheel-down)
    ("<mouse-4>" . my/mouse-wheel-up)
    ("<mouse-5>" . my/mouse-wheel-down)
    ("M-<up>" . my/move-line-up)
    ("M-<down>" . my/move-line-down)
    ("M-S-<up>" . mc/mark-previous-like-this)
    ("M-S-<down>" . mc/mark-next-like-this)
    ("<f1>" . help-command)
    ("<f12>" . xref-find-definitions)
    ("S-<f12>" . xref-find-references))
  "Global keybindings as key strings paired with commands."
  :type '(alist :key-type string :value-type function))

;; These take priority over major-mode maps and replace Emacs prefix keys.
(defcustom my/familiar-keybindings
  '(("C-c" . my/copy-region-or-line)
    ("C-x" . my/cut-region-or-line)
    ("C-v" . yank)
    ("C-q" . kill-current-buffer)
    ("M-q" . my/quit-emacs)
    ("C-e" . execute-extended-command)
    ("C-a" . my/select-all))
  "High-priority familiar keybindings."
  :type '(alist :key-type string :value-type function))

(defcustom my/isearch-keybindings
  '(("<down>" . isearch-repeat-forward)
    ("<up>" . isearch-repeat-backward))
  "Bindings active while an incremental search is running."
  :type '(alist :key-type string :value-type function))

;;; Generated state

;; Keep Emacs' generated state out of this file and inside var/.
(defconst my/cache-directory (expand-file-name "var/" user-emacs-directory))
(defconst my/package-directory (expand-file-name "elpa/" my/cache-directory))
(dolist (directory (list my/cache-directory
                         my/package-directory
                         (expand-file-name "auto-save/" my/cache-directory)
                         (expand-file-name "auto-save-list/" my/cache-directory)
                         (expand-file-name "backups/" my/cache-directory)
                         (expand-file-name "eln-cache/" my/cache-directory)))
  (make-directory directory t))

(setq package-user-dir my/package-directory
      custom-file null-device
      auto-save-list-file-prefix (expand-file-name "auto-save-list/.saves-" my/cache-directory)
      auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-save/" my/cache-directory) t))
      backup-directory-alist `(("." . ,(expand-file-name "backups/" my/cache-directory)))
      tramp-persistency-file-name (expand-file-name "tramp" my/cache-directory)
      recentf-save-file (expand-file-name "recentf" my/cache-directory)
      savehist-file (expand-file-name "savehist" my/cache-directory)
      bookmark-default-file (expand-file-name "bookmarks" my/cache-directory)
      project-list-file (expand-file-name "projects" my/cache-directory)
      mc/list-file (expand-file-name "multiple-cursors.el" my/cache-directory)
      url-configuration-directory (expand-file-name "url/" my/cache-directory))

(when (boundp 'native-comp-eln-load-path)
  (let ((cache (expand-file-name "eln-cache/" my/cache-directory))
        (default-cache (expand-file-name "eln-cache/" user-emacs-directory)))
    (setq native-comp-eln-load-path
          (cons cache (delete default-cache native-comp-eln-load-path)))))

;;; Packages

(require 'package)
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("melpa" . "https://melpa.org/packages/"))
      package-archive-priorities '(("gnu" . 30) ("nongnu" . 20) ("melpa" . 10)))
(package-initialize)

(require 'use-package)
(setq use-package-always-ensure t
      use-package-expand-minimally t)

;;; Core behavior

(setq initial-major-mode 'fundamental-mode
      ring-bell-function #'ignore
      confirm-kill-emacs #'y-or-n-p
      sentence-end-double-space nil
      scroll-conservatively 101
      scroll-margin 2
      mouse-wheel-scroll-amount '(3 ((shift) . 1))
      mouse-wheel-progressive-speed nil
      redisplay-dont-pause t
      fast-but-imprecise-scrolling t
      native-comp-jit-compilation nil
      read-process-output-max (* 1024 1024)
      kill-do-not-save-duplicates t
      delete-by-moving-to-trash t
      uniquify-buffer-name-style 'forward
      vc-follow-symlinks t
      compilation-scroll-output 'first-error)

(setq-default tab-width my/indent-width
              standard-indent my/indent-width
              indent-tabs-mode nil
              require-final-newline t)

(global-auto-revert-mode 1)
(global-so-long-mode 1)
(electric-pair-mode 1)
(delete-selection-mode 1)
(save-place-mode -1)
(savehist-mode 1)
(recentf-mode 1)
(when (fboundp 'xterm-mouse-mode)
  (xterm-mouse-mode 1))
(when (fboundp 'mouse-wheel-mode)
  (mouse-wheel-mode 1))

(setq shift-select-mode t)

(add-hook 'before-save-hook #'delete-trailing-whitespace)

;;; Completion and navigation

(use-package orderless
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(use-package consult)

(use-package dtrt-indent
  :init
  (setq dtrt-indent-lighter nil
        dtrt-indent-verbosity 0
        dtrt-indent-run-after-smie t)
  :config
  (dtrt-indent-global-mode 1))

(use-package multiple-cursors)

(use-package clipetty
  :if (not (display-graphic-p))
  :config
  (global-clipetty-mode 1))

;;; Editor functions

(require 'project)

(defun my/project-root ()
  "Return the current project root, falling back to `default-directory'."
  (if-let ((project (project-current)))
      (project-root project)
    default-directory))

(defun my/quick-open ()
  "Open a project file like VS Code's Quick Open."
  (interactive)
  (if (project-current)
      (call-interactively #'project-find-file)
    (call-interactively #'find-file)))

(defun my/mouse-event-window (event)
  "Select the live window under mouse EVENT."
  (let ((window (posn-window (event-start event))))
    (when (window-live-p window)
      (select-window window))))

(defun my/mouse-wheel-up (event)
  "Scroll toward the beginning at mouse EVENT."
  (interactive "e")
  (my/mouse-event-window event)
  (condition-case nil
      (scroll-down-line my/mouse-scroll-lines)
    (beginning-of-buffer nil)))

(defun my/mouse-wheel-down (event)
  "Scroll toward the end at mouse EVENT."
  (interactive "e")
  (my/mouse-event-window event)
  (condition-case nil
      (scroll-up-line my/mouse-scroll-lines)
    (end-of-buffer nil)))

(defun my/quit-emacs ()
  "Offer to save each file, then exit without a modified-buffer prompt."
  (interactive)
  (let ((confirm-kill-emacs nil))
    (save-some-buffers)
    (kill-emacs)))

(defun my/copy-region-or-line ()
  "Copy the active region or the current line."
  (interactive)
  (let ((start (if (use-region-p) (region-beginning) (line-beginning-position)))
        (end (if (use-region-p) (region-end) (line-beginning-position 2))))
    (kill-ring-save start end)
    (deactivate-mark)))

(defun my/cut-region-or-line ()
  "Cut the active region or the current line."
  (interactive)
  (let ((start (if (use-region-p) (region-beginning) (line-beginning-position)))
        (end (if (use-region-p) (region-end) (line-beginning-position 2))))
    (kill-region start end)))

(defun my/move-left ()
  "Move left and clear an active selection."
  (interactive)
  (if (use-region-p)
      (let ((start (region-beginning)))
        (deactivate-mark)
        (goto-char start))
    (backward-char)))

(defun my/move-right ()
  "Move right and clear an active selection."
  (interactive)
  (if (use-region-p)
      (let ((end (region-end)))
        (deactivate-mark)
        (goto-char end))
    (forward-char)))

(defun my/move-up ()
  "Move up and clear an active selection."
  (interactive)
  (deactivate-mark)
  (previous-line))

(defun my/move-down ()
  "Move down and clear an active selection."
  (interactive)
  (deactivate-mark)
  (next-line))

(defun my/start-selection ()
  "Start a selection at point unless one is already active."
  (unless (use-region-p)
    (set-mark (point))
    (activate-mark)))

(defun my/select-all ()
  "Select the whole buffer with point at the end."
  (interactive)
  (set-mark (point-min))
  (goto-char (point-max))
  (activate-mark))

(defun my/select-left ()
  "Extend the selection one character left."
  (interactive)
  (my/start-selection)
  (backward-char))

(defun my/select-right ()
  "Extend the selection one character right."
  (interactive)
  (my/start-selection)
  (forward-char))

(defun my/select-up ()
  "Extend the selection one line up."
  (interactive)
  (my/start-selection)
  (previous-line))

(defun my/select-down ()
  "Extend the selection one line down."
  (interactive)
  (my/start-selection)
  (next-line))

(defun my/duplicate-line-or-region ()
  "Duplicate the active region or the current line."
  (interactive)
  (let* ((region (use-region-p))
         (start (if region (region-beginning) (line-beginning-position)))
         (end (if region (region-end) (line-beginning-position 2)))
         (text (buffer-substring start end)))
    (goto-char end)
    (insert text)
    (when region
      (set-mark end)
      (activate-mark))))

(defun my/move-line-up ()
  "Move the current line one line up."
  (interactive)
  (unless (bobp)
    (transpose-lines 1)
    (forward-line -2)))

(defun my/move-line-down ()
  "Move the current line one line down."
  (interactive)
  (forward-line 1)
  (unless (eobp)
    (transpose-lines 1)
    (forward-line -1)))

;;; Micro-style word movement

(defun my/micro-mark-p (char)
  "Return non-nil when CHAR is a Unicode combining mark."
  (memq (and char (get-char-code-property char 'general-category))
        '(Mn Mc Me)))

(defun my/micro-word-char-p (char)
  "Return non-nil when CHAR belongs to a Micro-style word."
  (or (eq char ?_)
      (memq (and char (get-char-code-property char 'general-category))
            '(Lu Ll Lt Lm Lo Nd Nl No))))

(defun my/micro-whitespace-p (char)
  "Return non-nil when CHAR is whitespace according to Micro."
  (and char
       (or (memq char '(9 10 11 12 13 32 133 160 5760 8232 8233
                          8239 8287 12288))
           (and (<= 8192 char) (<= char 8202)))))

(defun my/micro-forward-character ()
  "Move over one character as represented internally by Micro."
  (unless (eobp)
    (forward-char)
    (while (and (not (eobp)) (my/micro-mark-p (char-after)))
      (forward-char))))

(defun my/micro-backward-character ()
  "Move back over one character as represented internally by Micro."
  (unless (bobp)
    (backward-char)
    (while (and (not (bobp)) (my/micro-mark-p (char-after)))
      (backward-char))))

(defun my/micro-next-character ()
  "Return the character following the Micro character at point."
  (save-excursion
    (my/micro-forward-character)
    (char-after)))

(defun my/micro-previous-character ()
  "Return the Micro character before point, clamped at line start."
  (save-excursion
    (unless (bolp)
      (my/micro-backward-character))
    (char-after)))

(defun my/micro-word-right (&optional keep-selection)
  "Move right using Micro's WordRight algorithm.
Preserve an active selection when KEEP-SELECTION is non-nil."
  (interactive)
  (when (and (not keep-selection) (use-region-p))
    (goto-char (region-end))
    (deactivate-mark))
  (catch 'done
    (when (eobp)
      (throw 'done nil))
    (when (eolp)
      (my/micro-forward-character)
      (throw 'done nil))
    (while (my/micro-whitespace-p (char-after))
      (when (eolp)
        (throw 'done nil))
      (my/micro-forward-character))
    (when (and (not (my/micro-word-char-p (char-after)))
               (not (my/micro-whitespace-p (char-after)))
               (not (my/micro-word-char-p (my/micro-next-character))))
      (while (and (not (my/micro-word-char-p (char-after)))
                  (not (my/micro-whitespace-p (char-after))))
        (when (eolp)
          (throw 'done nil))
        (my/micro-forward-character))
      (throw 'done nil))
    (my/micro-forward-character)
    (while (my/micro-word-char-p (char-after))
      (when (eolp)
        (throw 'done nil))
      (my/micro-forward-character))))

(defun my/micro-word-left (&optional keep-selection)
  "Move left using Micro's WordLeft algorithm.
Preserve an active selection when KEEP-SELECTION is non-nil."
  (interactive)
  (when (and (not keep-selection) (use-region-p))
    (goto-char (region-beginning))
    (deactivate-mark))
  (catch 'done
    (when (bobp)
      (throw 'done nil))
    (when (bolp)
      (my/micro-backward-character)
      (throw 'done nil))
    (my/micro-backward-character)
    (while (my/micro-whitespace-p (char-after))
      (when (bolp)
        (throw 'done nil))
      (my/micro-backward-character))
    (when (and (not (my/micro-word-char-p (char-after)))
               (not (my/micro-whitespace-p (char-after)))
               (not (my/micro-word-char-p (my/micro-previous-character))))
      (while (and (not (my/micro-word-char-p (char-after)))
                  (not (my/micro-whitespace-p (char-after))))
        (when (bolp)
          (throw 'done nil))
        (my/micro-backward-character))
      (my/micro-forward-character)
      (throw 'done nil))
    (my/micro-backward-character)
    (while (my/micro-word-char-p (char-after))
      (when (bolp)
        (throw 'done nil))
      (my/micro-backward-character))
    (my/micro-forward-character)))

(defun my/select-word-left ()
  "Extend the selection left using Micro's word movement."
  (interactive)
  (my/start-selection)
  (my/micro-word-left t)
  (activate-mark))

(defun my/select-word-right ()
  "Extend the selection right using Micro's word movement."
  (interactive)
  (my/start-selection)
  (my/micro-word-right t)
  (activate-mark))

(defun my/micro-delete-word-left ()
  "Delete left using Micro's DeleteWordLeft algorithm."
  (interactive)
  (my/select-word-left)
  (when (use-region-p)
    (delete-region (region-beginning) (region-end)))
  (deactivate-mark))

;;; Keybinding implementation

(defvar my/familiar-keys-map (make-sparse-keymap))

(define-minor-mode my/familiar-keys-mode
  "Use conventional copy and cut keys instead of Emacs prefix maps."
  :global t
  :keymap my/familiar-keys-map)

(defvar my/familiar-keys-emulation-alist
  `((my/familiar-keys-mode . ,my/familiar-keys-map)))

(defun my/apply-keybindings ()
  "Apply the keybinding tables declared in the user options section."
  (dolist (binding my/global-keybindings)
    (global-set-key (kbd (car binding)) (cdr binding)))
  (dolist (binding my/familiar-keybindings)
    (define-key my/familiar-keys-map (kbd (car binding)) (cdr binding)))
  (dolist (binding my/isearch-keybindings)
    (define-key isearch-mode-map (kbd (car binding)) (cdr binding))))

(add-to-list 'emulation-mode-map-alists 'my/familiar-keys-emulation-alist)
(my/apply-keybindings)
(my/familiar-keys-mode 1)

(provide 'mice)
;;; mice.el ends here
