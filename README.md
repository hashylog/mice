# MICE

Micro-Inspired Configuration for Emacs is a terminal-first Emacs configuration
with familiar Micro and conventional editor behavior.

## Loading

Place `mice.el` anywhere and load it from your Emacs `init.el`:

```elisp
(load "/absolute/path/to/mice.el")
```

The default local installation uses:

```elisp
(load (expand-file-name "var/mice.el" user-emacs-directory))
```

MICE stores generated state relative to `user-emacs-directory`, so `mice.el`
does not depend on its own installation location.
