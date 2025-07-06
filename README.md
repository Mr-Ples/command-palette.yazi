# WARNING

This plugin is completely vibe coded, i have no idea how it works. I didn't even read this readme lmao. use at own risk.

# Command Palette Plugin for Yazi

A command palette plugin that allows you to search and execute yazi commands from your keymap configuration.

[Watch Demo Video](https://github.com/Mr-Ples/command-palette.yazi/blob/main/showcase.gif)

## Features

- Parses your `keymap.toml` files to extract all available commands
- Provides a searchable interface to find commands by description or key binding
- Executes commands directly within yazi
- Supports both built-in selection interface and external fzf for fuzzy searching
- Handles shell commands, plugin commands, and native yazi commands

## Installation

This plugin is already installed in your yazi plugins directory.

## Usage

### Fuzzy Search with fzf (Default)

The default behavior uses fzf for fuzzy searching:

```toml
[[manager.prepend_keymap]]
on = ["<C-c>", "p"]
desc = "Command palette (fzf)"
run = "plugin command-palette"
```

### Built-in Interface

For a simpler built-in selection interface:

```toml
[[manager.prepend_keymap]]
on = ["<C-c>", "P"]
desc = "Command palette (built-in)"
run = "plugin command-palette --args=builtin"
```

## How It Works

1. **Parsing**: The plugin reads your `keymap.toml` files from:
   - `~/.config/yazi/keymap.toml`
   - any `.toml` files found in `~/.config/yazi/plugins/`

2. **Display**: Shows all available commands with their descriptions and key bindings

3. **Execution**: When you select a command, it:
   - Executes shell commands directly
   - Runs plugin commands with proper arguments
   - Handles native yazi commands

## Command Types Supported

- **Shell commands**: `shell 'command'` or `shell --block 'command'`
- **Plugin commands**: `plugin plugin-name` or `plugin plugin-name --args=...`
- **Native yazi commands**: `search`, `filter`, `find`, etc.

## Requirements

- For fzf mode: `fzf` must be installed and available in PATH 