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

### Keybindings

MICE keys take priority over every other keymap, including the `C-x` and `C-c`
prefixes. Each key is active in a scope; outside it, the key keeps its usual
Emacs meaning:

- **edit**: editable buffers managed by MICE
- **view**: buffers managed by MICE, including read-only ones
- **copy**: like view, plus any buffer with an active selection
- **global**: every buffer except the minibuffer

Without a selection, copy and cut act on the whole line, and consecutive line
cuts accumulate. Typing replaces the selection.

#### Editing (edit)

| Key                                  | Action                                                          |
|--------------------------------------|-----------------------------------------------------------------|
| `TAB`                                | Indent the selection, or insert up to the next tab stop         |
| `S-TAB`                              | Remove one indentation level from the selection or the line     |
| `RET`                                | New line keeping the current indentation; clears blank lines    |
| `BACKSPACE`, `C-h`                   | Delete the selection, a whole indentation level, or a character |
| `C-BACKSPACE`, `M-BACKSPACE`, `C-M-h` | Delete the previous word                                        |
| `C-DELETE`                           | Delete the next word                                            |
| `C-x` / `C-k`                        | Cut selection or line / cut line                                |
| `C-v`                                | Paste                                                           |
| `C-z` / `C-y`                        | Undo / redo                                                     |
| `C-d`                                | Duplicate selection or line                                     |
| `M-UP` / `M-DOWN`                    | Move selected lines or the line                                 |
| `C-/`, `M-/`                         | Toggle comments                                                 |

#### Movement and selection (view)

Hold `SHIFT` with any movement key to extend the selection. Plain movement
collapses the selection.

| Key                          | Action                                         |
|------------------------------|------------------------------------------------|
| Arrows                       | Move by character or line                      |
| `C-LEFT` / `C-RIGHT`         | Move by word, using Micro's word boundaries    |
| `HOME`, `M-LEFT`             | Toggle first non-blank character / line start  |
| `END`, `M-RIGHT`             | End of line                                    |
| `C-UP` / `C-DOWN`, `C-HOME` / `C-END` | Start / end of buffer                 |
| `PAGEUP` / `PAGEDOWN`        | Move by page                                   |
| `C-a`                        | Select all                                     |
| `C-c`                        | Copy selection or line (copy scope)            |
| `C-s`                        | Save                                           |
| `C-u` / `C-j`                | Record macro / play macro                      |

#### Editor (global)

| Key           | Action                                              |
|---------------|-----------------------------------------------------|
| `C-f`         | Find (regexp); the match is selected on exit        |
| `C-n` / `C-p` | Select next / previous match, wrapping around       |
| `C-o`         | Open file                                           |
| `C-q`         | Close buffer; quits when no other file is open      |
| `M-q`         | Quit                                                |
| `C-e`         | Run command                                         |
| `C-l`         | Go to line                                          |
| `C-w`         | Next window                                         |
| `C-r`         | Toggle line numbers                                 |

While finding, `UP` / `DOWN` and `C-p` / `C-n` move between matches and `C-v`
pastes into the search.

### Clipboard

In a terminal, copy and cut reach the system clipboard and paste reads from
it, without configuration. `mice-clipboard` selects how:

| Value                | Copy                  | Paste                                                    |
|----------------------|-----------------------|----------------------------------------------------------|
| `auto` (default)     | Terminal (OSC 52)     | Clipboard tool if available, otherwise terminal (OSC 52) |
| `terminal`           | Terminal (OSC 52)     | Terminal (OSC 52)                                        |
| `external`           | Clipboard tool        | Clipboard tool                                           |
| `internal`           | Emacs only            | Emacs only                                               |

Clipboard tools are detected automatically: `wl-clipboard` on Wayland, `xclip`
or `xsel` on X11 and `pbcopy` on macOS. Over SSH, `auto` only uses the
terminal. When the terminal does not answer a paste request, paste falls back
to the Emacs clipboard and the terminal is not asked again.

Pasting with the terminal itself (for example `C-S-v`) always works and
replaces the selection. Graphical frames keep the native Emacs clipboard.

Reading the clipboard through the terminal is disabled or asks for
permission by default in most terminals. Installing a clipboard tool avoids
that; alternatively, allow it in the terminal (Alacritty: `terminal.osc52 =
"CopyPaste"`). Inside tmux, OSC 52 requires `set -g set-clipboard on`.

### Mouse

In a terminal, clicking moves the cursor, dragging selects, double and triple
clicks select a word and a line, and the wheel scrolls the window under the
pointer by `mice-mouse-scroll-lines` lines (2 by default). Scrolling stops
at the buffer edges.

### Indentation

Width and style come from the standard `tab-width` and `indent-tabs-mode`
variables.

Disabling `mice-mode` gives every buffer back to its major mode and restores
the previous state of `delete-selection-mode`, `xterm-mouse-mode`, the
clipboard functions and the search keys.

## Development

```sh
make compile
make test
```
