# MICE

Micro-Inspired Changes for Emacs is a package that aggressively changes how
Emacs edits text so that it behaves like the [Micro](https://micro-editor.github.io)
editor, the same way Evil makes Emacs behave like Vim.

MICE is not a configuration. Themes, UI and third-party plugins belong to the
distribution built on top of it.

## Usage

```elisp
(add-to-list 'load-path "/path/to/mice")
(require 'mice)
(mice-mode 1)
```

Requires Emacs 30.1 or newer.

## What it changes

### Major modes only provide syntax

In file buffers and in `prog-mode`, `text-mode` and `conf-mode` buffers, major
modes keep providing syntax highlighting, comment syntax and the language
identity used by tools such as LSP. MICE removes their keymaps and their
indentation rules, so editing behaves the same in every file type.

Special buffers (help, dired, ...) and the minibuffer are left untouched.
Modes listed in `mice-preserved-modes` are left untouched as well.

### Indentation

| Key         | Behavior                                                        |
|-------------|-----------------------------------------------------------------|
| `TAB`       | Indent the selection, or insert up to the next tab stop         |
| `S-TAB`     | Remove one indentation level from the selection or the line     |
| `RET`       | New line keeping the current indentation; clears blank lines    |
| `BACKSPACE` | Delete the selection, a whole indentation level, or a character |

Width and style come from the standard `tab-width` and `indent-tabs-mode`
variables.

Disabling `mice-mode` gives every buffer back to its major mode.

## Development

```sh
make compile
make test
```
