# nvim-xdg-installer

Register `nvim://` as a custom URL protocol handler on Linux via XDG. Click links like `nvim://open?url=file:///path/to/file&line=10&column=5` to open files directly in Neovim at the specified position.

## Installation

```bash
./install.sh
```

## Uninstallation

```bash
./install.sh --uninstall
```

## Usage

After installation, you can open files in Neovim via URLs:

```bash
# Open file at specific line and column
xdg-open 'nvim://open?url=file:///home/user/project/main.py&line=42&column=10'

# Open file at specific line
xdg-open 'nvim://open?url=file:///etc/hosts&line=5'

# Open file only
xdg-open 'nvim://open?url=file:///etc/hosts'
```

### URL Format

```
nvim://open?url=file:///path/to/file&line=N&column=N
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `url`     | Yes      | File path as `file://` URI (URL-encoded) |
| `line`    | No       | Line number to jump to |
| `column`  | No       | Column number to jump to |

## Requirements

- Neovim (`nvim`)
- Python 3 (for URL decoding)
- xdg-utils (`xdg-mime`)

## How It Works

The installer creates:

1. A handler script at `~/.local/bin/nvim-url-handler` that parses nvim:// URLs and opens Neovim with the correct cursor position
2. A desktop entry at `~/.local/share/applications/nvim-url-handler.desktop` that registers the handler with the XDG mime system

## License

MIT
