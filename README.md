# acterm.nvim

A focused, floating terminal workspace for Neovim: a live sidebar plus a main terminal pane.

![](https://via.placeholder.com/800x400?text=Demo+image+coming+soon)

## Why acterm.nvim

- **Stay oriented**: Always see your terminal list and current selection.
- **Fast switching**: Jump between sessions without leaving the UI.
- **Signal, not noise**: Live activity status tells you what’s running.
- **Compact workflow**: One UI for create, rename, and navigate.

## Quick Start

1. Install the plugin.
2. Add `require('acterm').setup({})` to your config.
3. Run `:AcTermUI` and start a terminal with `n` in the sidebar.

## Features

- **Two-pane floating UI**: Sidebar terminal list + main terminal view
- **Multiple terminals**: Create and manage multiple terminal sessions
- **Easy navigation**: Cycle through terminals with keyboard shortcuts
- **Customizable layout**: Configure sidebar width, main pane size, gap, and position
- **Relative sizing**: Specify sizes as percentages (0-1.0) or absolute values
- **Seamless borders**: Shared border between sidebar and main pane for a clean look
- **Live status**: Activity-based running/idle indicators
- **Rename terminals**: Give custom names to terminals for easy identification
- **Focus sidebar**: Jump to sidebar from anywhere with a keybinding
- **Clean UI**: Rounded borders, transparency support, and centered layout
- **Custom commands**: Add named terminal commands with their own keybindings
- **Auto-create**: Optionally create a terminal automatically on first open
- **Always up to date**: Sidebar refreshes while the UI is open

## Installation

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'huypl53/acterm.nvim'
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use 'huypl53/acterm.nvim'
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
require('lazy').setup({
  'huypl53/acterm.nvim',
  config = function()
    require('acterm').setup({})
  end
})
```

## Configuration

### Default Configuration

```lua
require('acterm').setup({
  sidebar = {
    width = 25,           -- Sidebar width (or 0.2 for 20% of screen)
  },
  main = {
    width = 80,           -- Main pane width (or 0.6 for 60% of screen)
    height = 30,          -- Main pane height (or 0.6 for 60% of screen)
  },
  gap = 0,                -- Gap between panes (0 for seamless borders)
  layout = 'horizontal',  -- Layout direction ('horizontal' or 'vertical')
  auto_create = true,     -- Auto-create terminal when opening UI
  wrap_around = true,     -- Wrap around when cycling terminals
  border = 'rounded',     -- Border style
  seamless_borders = true, -- Share border between panes
  winblend = 10,          -- Window transparency (0-100)
  activity = {
    enabled = true,       -- Track terminal activity for status
    poll_ms = 200,        -- Sidebar refresh interval while open
    idle_ms = 1000,       -- Idle threshold for status (ms)
  },
  status_icons = {        -- Status indicators for terminals
    running = '',        -- Icon for running terminals
    idle = '',           -- Icon for idle terminals
  },
  keys = {
    toggle = '<leader>tt',    -- Toggle UI
    new = '<leader>tn',       -- Create new terminal
    next = '<leader>tj',      -- Next terminal
    prev = '<leader>tk',      -- Previous terminal
    focus_sidebar = '<leader>ts', -- Focus sidebar
  },
})
```

### Border Styles

Available border styles:
- `none` - No border
- `single` - Single line border
- `double` - Double line border
- `rounded` - Rounded corners (default)
- `solid` - Solid border
- `shadow` - Drop shadow

### Relative vs Absolute Sizing

Sizes can be specified as:
- **Relative (0-1.0)**: `width = 0.5` means 50% of screen width
- **Absolute (>= 1)**: `width = 80` means 80 columns

```lua
-- Relative sizing (recommended for responsiveness)
sidebar = { width = 0.2 },  -- 20% of screen
main = { width = 0.6, height = 0.6 },  -- 60% of screen

-- Absolute sizing
sidebar = { width = 25 },
main = { width = 80, height = 30 },
```

### Seamless Borders

When `seamless_borders = true`, the left border of the main pane is removed, creating a seamless look with the sidebar. For best results, set `gap = 0`.

```lua
{
  gap = 0,
  seamless_borders = true,
  border = 'rounded',
}
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `:AcTermUI` | Toggle the multi-terminal UI |
| `:AcTermOpen` | Open the multi-terminal UI |
| `:AcTermClose` | Close the multi-terminal UI |
| `:AcTermNew [dir]` | Create a new terminal (optionally in directory) |
| `:AcTermNext` | Switch to next terminal |
| `:AcTermPrev` | Switch to previous terminal |
| `:AcTermGoto N` | Go to terminal N (by index) |
| `:AcTermFocusSidebar` | Focus the sidebar |
| `:AcTermRename <name>` | Rename current terminal |

### Default Keybindings

| Keybinding | Action |
|------------|--------|
| `<leader>tt` | Toggle UI |
| `<leader>tn` | Create new terminal |
| `<leader>tj` | Next terminal |
| `<leader>tk` | Previous terminal |
| `<leader>ts` | Focus sidebar |

### Sidebar Controls

When the sidebar is focused:
- `j` / `<down>`: Next terminal
- `k` / `<up>`: Previous terminal
- `1-9`: Jump to terminal by index
- `n`: Create a new terminal
- `r`: Rename the current terminal
- `q` / `<esc>`: Close the UI

### Typical Flow

1. Open the UI with `:AcTermUI` or `<leader>tt`.
2. Create terminals with `:AcTermNew` or `n` in the sidebar.
3. Switch between terminals using `j/k`, `<leader>tj/<leader>tk`, or `:AcTermGoto N`.
4. Rename with `:AcTermRename` or `r` in the sidebar.

### Use Cases

- **Project shells**: Keep per-project terminals in one spot.
- **Build/test loops**: Run commands and watch activity at a glance.
- **Git helpers**: Bind `gitui`, `lazygit`, or custom commands.
- **Scratch pads**: Quick one-off terminals without leaving the editor.

### Sidebar Keybindings

When focused in the sidebar:

| Key | Action |
|-----|--------|
| `j` / `<down>` | Next terminal |
| `k` / `<up>` | Previous terminal |
| `1-9` | Jump to terminal by index |
| `n` | Create new terminal |
| `r` | Rename current terminal |
| `q` / `<esc>` | Close UI |

### Terminal Status Indicators

The sidebar shows the status of each terminal:
- ** (running)**: Terminal has recent output/activity
- ** (idle)**: Terminal is idle (no activity for the idle threshold)

## Lua API

You can also use the plugin programmatically:

```lua
local acterm = require('acterm')

-- Toggle UI
acterm.toggle()

-- Open/close UI
acterm.open()
acterm.close()

-- Focus sidebar
acterm.focus_sidebar()

-- Create new terminal (optional: specify working directory)
acterm.new_terminal('/path/to/directory')

-- Navigate terminals
acterm.next_terminal()
acterm.prev_terminal()
acterm.goto_terminal(2)  -- Jump to terminal 2

-- Rename current terminal
acterm.rename_terminal('my-terminal')
```

## Examples

### Basic Usage

```lua
-- In your init.lua
require('acterm').setup({
  keys = {
    toggle = '<leader>tt',
    new = '<leader>tn',
    next = '<leader>tj',
    prev = '<leader>tk',
    focus_sidebar = '<leader>ts',
  },
})

-- Press <leader>tt to toggle the UI
-- Press <leader>tn to create a new terminal
-- Press <leader>ts to focus the sidebar
-- Use j/k in the sidebar to navigate between terminals
-- Press r to rename a terminal
```

### Custom Commands

```lua
require('acterm').setup({
  custom_commands = {
    rg = { cmd = "rg --files", key = "<leader>tr" },
    gitui = { cmd = "gitui", key = "<leader>tg" },
  },
})
```

### Activity-Based Status

```lua
require('acterm').setup({
  activity = {
    enabled = true,
    poll_ms = 200,
    idle_ms = 1000,
  },
  status_icons = {
    running = "",
    idle = "",
  },
})
```

## Screenshots

Placeholder for now. If you have a screenshot or gif, drop it in and update the image link above.

## Comparison

acterm.nvim is optimized for a focused, always-visible terminal list and a single main pane. It’s ideal when you want quick terminal switching with minimal UI overhead rather than managing many splits or tabs.

### Relative Sizing (Responsive)

```lua
require('acterm').setup({
  sidebar = {
    width = 0.2,   -- 20% of screen width
  },
  main = {
    width = 0.6,   -- 60% of screen width
    height = 0.6,  -- 60% of screen height
  },
  gap = 0,
  seamless_borders = true,
})
```

### Larger UI for Big Screens

```lua
require('acterm').setup({
  sidebar = {
    width = 30,
  },
  main = {
    width = 120,
    height = 40,
  },
})
```

### Custom Status Icons

```lua
require('acterm').setup({
  status_icons = {
    running = '[RUN]',
    idle = '[IDLE]',
  },
})
```

### Minimal Style

```lua
require('acterm').setup({
  border = 'none',
  winblend = 0,
  seamless_borders = false,
})
```

## How It Works

The plugin creates two floating windows:
1. **Left pane (sidebar)**: Shows a list of all active terminals with status indicators
2. **Right pane (main)**: Displays the currently selected terminal

Terminals are regular Neovim terminal buffers that persist even when the UI is closed. You can have multiple terminals running different processes and switch between them easily.

The terminal status is automatically detected using Neovim's job control, showing whether a terminal has an active process or is idle.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - see LICENSE file for details.

## Credits

Inspired by [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) and other great terminal management plugins.
