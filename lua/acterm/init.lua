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
  local term_opts = { noremap = true, silent = true }

  local function map_terminal_mode(lhs, fn)
    vim.keymap.set("t", lhs, function()
      local esc = vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true)
      vim.api.nvim_feedkeys(esc, "n", false)
      fn()
      vim.schedule(function()
        if vim.bo.buftype == "terminal" then
          vim.cmd("startinsert")
        end
      end)
    end, term_opts)
  end

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
    map_terminal_mode(cfg.keys.next, function()
      M.next_terminal()
    end)
  end

  if cfg.keys.prev then
    vim.keymap.set("n", cfg.keys.prev, function()
      M.prev_terminal()
    end, opts)
    map_terminal_mode(cfg.keys.prev, function()
      M.prev_terminal()
    end)
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

function M.stress_open_close(cycles, delay_ms, terms_per_cycle, lines_per_term, close_terms)
  cycles = tonumber(cycles) or 100
  delay_ms = tonumber(delay_ms) or 50
  local terms_per_cycle = tonumber(terms_per_cycle) or 3
  local lines_per_term = tonumber(lines_per_term) or 200
  local close_terms = close_terms == true or tostring(close_terms) == "1"

  local function send_output(term, cycle, term_index)
    if not term or not term.job_id then
      return
    end

    if lines_per_term <= 0 then
      return
    end

    local message = string.format("acterm stress cycle=%d term=%d", cycle, term_index)
    local escaped = message:gsub("'", "'\\''")
    local cmd = string.format("for i in $(seq 1 %d); do echo '%s'; done\n", lines_per_term, escaped)
    pcall(vim.api.nvim_chan_send, term.job_id, cmd)
  end

  local cycle = 0
  local phase = 0
  local timer = vim.uv.new_timer()
  timer:start(0, delay_ms, function()
    vim.schedule(function()
      if phase == 0 then
        cycle = cycle + 1
        M.open()

        local created = {}
        for i = 1, terms_per_cycle do
          local term = terminal.create_terminal()
          state.add_terminal(term)
          terminal.focus_terminal(state.get_terminal_count())
          created[#created + 1] = term
        end
        ui.update()

        for i, term in ipairs(created) do
          send_output(term, cycle, i)
        end

        if close_terms then
          for _, term in ipairs(created) do
            if vim.api.nvim_buf_is_valid(term.buf) then
              vim.api.nvim_buf_delete(term.buf, { force = true })
            end
          end
        end

        phase = 1
      else
        M.close()
        phase = 0
        if cycle >= cycles then
          timer:stop()
          timer:close()
        end
      end
    end)
  end)
end

return M
