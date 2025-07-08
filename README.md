# WARNING

This plugin is completely vibe coded, i have no idea how it works. I didn't even read this readme lmao. use at own risk.

# Command Palette Plugin for Yazi

A command palette plugin that allows you to search and execute yazi commands from your keymap configuration.

![Watch Demo Video](https://github.com/Mr-Ples/command-palette.yazi/blob/main/showcase.gif)

## Features

- Parses your `keymap.toml` files to extract all available commands
- Provides a searchable interface to find commands by description or key binding
- Executes commands directly within yazi
- Supports both built-in selection interface and external fzf for fuzzy searching
- Handles shell commands, plugin commands, and native yazi commands

## Installation

Install the plugin using the yazi package manager:

```bash
ya pkg add Mr-Ples/command-palette.yazi
```

Then copy the compatible keymap format to your plugin directory. The plugin includes a `compatible-formate-keymap.toml` file that demonstrates the proper format for the parser.

## Usage

### Fuzzy Search with fzf (Default)

The default behavior uses fzf for fuzzy searching:

```toml
[[manager.prepend_keymap]]
on = ["`"]
desc = "Command palette (fzf)"
run = "plugin command-palette"
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

## Keymap Format Requirements

The parser expects keymap entries in this specific format:

```toml
[[manager.prepend_keymap]]
on = "q"
run = "quit"
desc = "Quit the process"

[[manager.prepend_keymap]]
on = ["g", "g"]
run = "arrow -99999999"
desc = "Move cursor to the top"
```

**Important Notes:**
- Use `on` for key bindings (supports both string and array formats)
- Use `run` for the command to execute
- Use `desc` for the description that appears in the palette
- Each entry must be in a `[[manager.prepend_keymap]]` section
- The parser is somewhat basic and expects this exact format

## Command Types Supported

- **Shell commands**: `shell 'command'` or `shell --block 'command'`
- **Plugin commands**: `plugin plugin-name` or `plugin plugin-name --args=...`
- **Native yazi commands**: `search`, `filter`, `find`, etc.

## Requirements

- For fzf mode: `fzf` must be installed and available in PATH
- Keymap files must be in the compatible format shown above

## Troubleshooting

If commands aren't being detected:
1. Check that your keymap file follows the exact format shown above
2. Ensure the file is located in `~/.config/yazi/` or `~/.config/yazi/plugins/`
3. Verify that each keymap entry has `on`, `run`, and `desc` fields
4. The parser looks for `[[manager.prepend_keymap]]` sections specifically 