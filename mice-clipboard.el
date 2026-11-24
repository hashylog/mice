;;; mice-clipboard.el --- System clipboard in the terminal -*- lexical-binding: t; -*-

;;; Commentary:

;; Connects the kill ring to the system clipboard when Emacs runs in a
;; terminal.  Copying goes through the terminal with OSC 52, which works
;; with any system and over SSH.  Pasting prefers a clipboard tool found
;; on the system, falling back to asking the terminal through OSC 52.
;; Graphical frames keep the native Emacs clipboard.

;;; Code:

(require 'seq)
(require 'subr-x)

(defcustom mice-clipboard 'auto
  "How mice reaches the system clipboard from a terminal.
`auto':     copy through the terminal; paste with a clipboard tool when
            one is available, otherwise through the terminal.  Over SSH
            only the terminal is used.
`terminal': only the terminal, through OSC 52.
`external': only clipboard tools such as wl-clipboard, xclip or pbcopy.
`internal': only the Emacs kill ring."
  :type '(choice (const auto) (const terminal) (const external) (const internal))
  :group 'mice)

(defcustom mice-clipboard-terminal-timeout 1.0
  "Seconds to wait for the terminal to answer a clipboard request."
  :type 'number
  :group 'mice)

(defcustom mice-clipboard-max-length 100000
  "Largest encoded text, in bytes, sent to the terminal clipboard."
  :type 'integer
  :group 'mice)

(defconst mice-clipboard--tools
  '((wayland ("wl-copy") ("wl-paste" "--no-newline"))
    (x11 ("xclip" "-selection" "clipboard" "-in")
         ("xclip" "-selection" "clipboard" "-out"))
    (x11 ("xsel" "--clipboard" "--input")
         ("xsel" "--clipboard" "--output"))
    (macos ("pbcopy") ("pbpaste")))
  "Entries (SESSION COPY-COMMAND PASTE-COMMAND) of known clipboard tools.")

(defvar mice-clipboard--last-text nil
  "Text most recently exchanged with the system clipboard.")

(defvar mice-clipboard--saved-functions nil
  "Interprogram functions in place before mice took over, as (CUT . PASTE).")

;;; Environment

(defun mice-clipboard--graphic-p ()
  "Return non-nil if the selected frame is graphical."
  (display-graphic-p))

(defun mice-clipboard--tty-p ()
  "Return non-nil if the selected frame is a real terminal."
  (and (not (display-graphic-p))
       (not (equal (terminal-name) "initial_terminal"))))

(defun mice-clipboard--ssh-p ()
  "Return non-nil if Emacs runs in an SSH session."
  (or (getenv "SSH_TTY") (getenv "SSH_CONNECTION")))

(defun mice-clipboard--session-p (session)
  "Return non-nil if the current graphical SESSION is available."
  (pcase session
    ('wayland (getenv "WAYLAND_DISPLAY"))
    ('x11 (getenv "DISPLAY"))
    ('macos (eq system-type 'darwin))))

(defun mice-clipboard--tool ()
  "Return the first usable entry of `mice-clipboard--tools'."
  (seq-find (pcase-lambda (`(,session ,copy ,paste))
              (and (mice-clipboard--session-p session)
                   (executable-find (car copy))
                   (executable-find (car paste))))
            mice-clipboard--tools))

;;; Clipboard tools

(defun mice-clipboard--external-write (command text)
  "Send TEXT to the clipboard tool COMMAND."
  (let* ((process-connection-type nil)
         (process (apply #'start-process "mice-clipboard" nil command)))
    (set-process-query-on-exit-flag process nil)
    (set-process-coding-system process 'utf-8-unix 'utf-8-unix)
    (process-send-string process text)
    (process-send-eof process)))

(defun mice-clipboard--external-read (command)
  "Return the clipboard text printed by the tool COMMAND, or nil."
  (with-temp-buffer
    (let ((coding-system-for-read 'utf-8-unix))
      (when (eql 0 (apply #'call-process (car command) nil '(t nil) nil
                          (cdr command)))
        (buffer-string)))))

;;; Terminal (OSC 52)

(defun mice-clipboard--terminal-write (text)
  "Ask the terminal to put TEXT in the system clipboard."
  (let ((encoded (base64-encode-string (encode-coding-string text 'utf-8-unix) t)))
    (if (> (length encoded) mice-clipboard-max-length)
        (message "Selection too large for the terminal clipboard")
      (send-string-to-terminal (concat "\e]52;c;" encoded "\a")))))

(defun mice-clipboard--read-terminated ()
  "Read events up to BEL or ESC \\ and return them as a string.
Return nil if the terminal stops sending before the terminator."
  (let (chars last event done)
    (while (not done)
      (setq event (read-event nil nil 0.5))
      (cond
       ((null event) (setq done 'timeout))
       ((eq event ?\a) (setq done t))
       ((and (eq event ?\\) (eq last ?\e)) (pop chars) (setq done t))
       (t (push event chars)))
      (setq last event))
    (and (eq done t) (concat (nreverse chars)))))

(defun mice-clipboard--read-reply ()
  "Read the terminal reply to a clipboard request.
Return the encoded payload, nil for an unexpected reply, or `timeout'."
  (let ((first (read-event nil nil mice-clipboard-terminal-timeout)))
    (if (null first)
        'timeout
      (let ((expected (append "\e]52;" nil))
            (events (list first))
            (matched (eq first ?\e)))
        (setq expected (cdr expected))
        (while (and matched expected)
          (let ((event (read-event nil nil 0.5)))
            (when event (push event events))
            (setq matched (eq event (pop expected)))))
        (if (not matched)
            (progn
              (setq unread-command-events
                    (append (nreverse events) unread-command-events))
              nil)
          (when-let* ((payload (mice-clipboard--read-terminated)))
            (substring payload (1+ (or (string-search ";" payload) -1)))))))))

(defun mice-clipboard--decode (payload)
  "Decode the base64 PAYLOAD of a terminal reply, or return nil."
  (ignore-errors
    (decode-coding-string (base64-decode-string payload) 'utf-8-unix)))

(defun mice-clipboard--discard-late-reply (&optional _prompt)
  "Consume a terminal reply that arrived after the request timed out."
  (define-key input-decode-map "\e]52;" nil)
  (set-terminal-parameter nil 'mice-clipboard-read nil)
  (let ((inhibit-quit t))
    (mice-clipboard--read-terminated)
    (setq quit-flag nil))
  [])

(defun mice-clipboard--terminal-read ()
  "Ask the terminal for the system clipboard text, or return nil.
A terminal that does not answer is not asked again, unless a late
answer shows that it only needed more time.  The request ends with ST
so that the answer does too: a BEL terminator is read as \\`C-g'."
  (unless (eq (terminal-parameter nil 'mice-clipboard-read) 'unsupported)
    (discard-input)
    (send-string-to-terminal "\e]52;c;?\e\\")
    (let ((reply (let ((inhibit-quit t))
                   (prog1 (mice-clipboard--read-reply)
                     (setq quit-flag nil)))))
      (if (eq reply 'timeout)
          (progn
            (set-terminal-parameter nil 'mice-clipboard-read 'unsupported)
            (define-key input-decode-map "\e]52;" #'mice-clipboard--discard-late-reply)
            nil)
        (and reply (mice-clipboard--decode reply))))))

;;; Interprogram functions

(defun mice-clipboard--read ()
  "Return the system clipboard text according to `mice-clipboard'."
  (pcase mice-clipboard
    ('internal nil)
    ('terminal (mice-clipboard--terminal-read))
    ('external (when-let* ((tool (mice-clipboard--tool)))
                 (mice-clipboard--external-read (nth 2 tool))))
    (_ (let ((tool (and (not (mice-clipboard--ssh-p)) (mice-clipboard--tool))))
         (if tool
             (mice-clipboard--external-read (nth 2 tool))
           (mice-clipboard--terminal-read))))))

(defun mice-clipboard--write (text)
  "Put TEXT in the system clipboard according to `mice-clipboard'."
  (pcase mice-clipboard
    ('internal nil)
    ('external (when-let* ((tool (mice-clipboard--tool)))
                 (mice-clipboard--external-write (nth 1 tool) text)))
    (_ (mice-clipboard--terminal-write text))))

(defun mice-clipboard-cut (text)
  "Send TEXT to the system clipboard.  Used as `interprogram-cut-function'."
  (cond
   ((mice-clipboard--graphic-p)
    (when (car mice-clipboard--saved-functions)
      (funcall (car mice-clipboard--saved-functions) text)))
   ((mice-clipboard--tty-p)
    (setq mice-clipboard--last-text text)
    (mice-clipboard--write text))))

(defun mice-clipboard-paste ()
  "Return new system clipboard text.  Used as `interprogram-paste-function'.
Return nil when the clipboard holds what Emacs itself last put there."
  (cond
   ((mice-clipboard--graphic-p)
    (when (cdr mice-clipboard--saved-functions)
      (funcall (cdr mice-clipboard--saved-functions))))
   ((mice-clipboard--tty-p)
    (let ((text (mice-clipboard--read)))
      (unless (or (null text)
                  (string-empty-p text)
                  (equal text mice-clipboard--last-text))
        (setq mice-clipboard--last-text text))))))

(defun mice-terminal-paste (event)
  "Insert the text of a terminal paste EVENT, replacing the selection."
  (interactive "*e")
  (when (use-region-p)
    (delete-region (region-beginning) (region-end)))
  (insert-for-yank (nth 1 event)))

(defun mice-clipboard-enable ()
  "Connect the kill ring to the system clipboard."
  (unless mice-clipboard--saved-functions
    (setq mice-clipboard--saved-functions
          (cons interprogram-cut-function interprogram-paste-function)
          interprogram-cut-function #'mice-clipboard-cut
          interprogram-paste-function #'mice-clipboard-paste)))

(defun mice-clipboard-disable ()
  "Restore the previous clipboard functions."
  (when mice-clipboard--saved-functions
    (setq interprogram-cut-function (car mice-clipboard--saved-functions)
          interprogram-paste-function (cdr mice-clipboard--saved-functions)
          mice-clipboard--saved-functions nil)))

(provide 'mice-clipboard)
;;; mice-clipboard.el ends here
