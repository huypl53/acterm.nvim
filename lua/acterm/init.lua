local M = {}

local config = require("acterm.config")
local state = require("acterm.state")
local terminal = require("acterm.terminal")
local ui = require("acterm.ui")

function M.setup(user_config)
  config.setup(user_config)
  M._setup_keybinds()
end

function M._setup_keybinds()
  local cfg = config.get()
  local opts = { noremap = true, silent = true }

  if cfg.keys.toggle then
    vim.keymap.set("n", cfg.keys.toggle, function()
      M.toggle()
    end, opts)
  end

  if cfg.keys.new then
    vim.keymap.set("n", cfg.keys.new, function()
      M.new_terminal()
    end, opts)
  end

  if cfg.keys.next then
    vim.keymap.set("n", cfg.keys.next, function()
      M.next_terminal()
    end, opts)
  end

  if cfg.keys.prev then
    vim.keymap.set("n", cfg.keys.prev, function()
      M.prev_terminal()
    end, opts)
  end

  if cfg.keys.focus_sidebar then
    vim.keymap.set("n", cfg.keys.focus_sidebar, function()
      M.focus_sidebar()
    end, opts)
  end

  if cfg.keys.toggle_sidebar then
    vim.keymap.set("n", cfg.keys.toggle_sidebar, function()
      M.toggle_sidebar()
    end, opts)
  end

  -- Setup keybindings for custom commands
  for name, cmd_config in pairs(cfg.custom_commands) do
    if cmd_config.key then
      vim.keymap.set("n", cmd_config.key, function()
        M.open_custom_command(name)
      end, { noremap = true, silent = true, desc = "AcTerm: " .. name })
    end
  end
end

function M.toggle()
  ui.toggle()
end

function M.open()
  ui.open()
end

function M.close()
  ui.close()
end

function M.new_terminal(cwd)
  local term = terminal.create_terminal(cwd)
  state.add_terminal(term)
  terminal.focus_terminal(state.get_terminal_count())
  ui.update()
end

function M.next_terminal()
  terminal.cycle_terminal("next")
  ui.update()
end

function M.prev_terminal()
  terminal.cycle_terminal("prev")
  ui.update()
end

function M.goto_terminal(index)
  local terminals = state.get_terminals()
  if index >= 1 and index <= #terminals then
    terminal.focus_terminal(index)
    ui.update()
  end
end

function M.focus_sidebar()
  ui.focus_sidebar()
end

function M.toggle_sidebar()
  ui.toggle_sidebar()
end

function M.rename_terminal(name)
  local current_index = state.get_current_index()
  if current_index > 0 then
    terminal.rename_terminal(current_index, name)
    ui.update()
  end
end

function M.open_custom_command(name)
  local cfg = config.get()
  local custom_cmd = cfg.custom_commands[name]

  if not custom_cmd then
    vim.notify("No custom command found: " .. name, vim.log.levels.ERROR)
    return
  end

  local term = terminal.create_custom_terminal(custom_cmd.cmd)
  state.add_terminal(term)
  terminal.focus_terminal(state.get_terminal_count())

  if not state.is_ui_open() then
    ui.open()
  else
    ui.update()
  end
end

return M
