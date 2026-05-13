# AGENTS.md

## Overview

Single-file bash installer that registers `nvim://` as a custom URL protocol handler via XDG on Linux systems. Clicking URLs like `nvim://open?url=file:///path/to/file&line=10&column=5` opens the file in Neovim at the specified position.

## Commands

```bash
./install.sh              # Install handler (default)
./install.sh --install    # Explicit install
./install.sh --uninstall  # Remove handler
```

**Testing after install:**
```bash
xdg-open 'nvim://open?url=file:///etc/hosts&line=1&column=1'
```

## Architecture

The installer generates two artifacts at install time:

1. **Handler script** (`~/.local/bin/nvim-url-handler`) - Parses nvim:// URLs, extracts file path + line + column, invokes nvim with cursor positioning
2. **Desktop entry** (`~/.local/share/applications/nvim-url-handler.desktop`) - Registers the handler with XDG mime system

URL format: `nvim://open?url=file:///path/to/file&line=N&column=N` (line/column optional)

## Dependencies

Runtime requirements checked by installer:
- `nvim` - Target editor
- `python3` - URL decoding via `urllib.parse`
- `xdg-mime` - Protocol registration (from xdg-utils)

## Gotchas

- **Python3 dependency for URL decoding**: The handler pipes through `python3 -c "import urllib.parse..."` to decode percent-encoded paths. No pure-bash fallback exists.
- **Terminal=true in desktop file**: Handler opens nvim in a terminal, which may behave differently across desktop environments/terminal emulators.
- **sed -i portability**: Uninstall uses GNU sed's `-i` flag without backup suffix - not portable to BSD/macOS sed.
- **File path extraction regex**: The sed pattern assumes `url=file://` prefix and `&` as parameter delimiter. Malformed URLs may parse incorrectly.
