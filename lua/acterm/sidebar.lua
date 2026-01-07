local M = {}
local state = require("acterm.state")
local config = require("acterm.config")
local terminal = require("acterm.terminal")

local ns_id = vim.api.nvim_create_namespace("acterm")

local function get_sidebar_content()
  local terminals = state.get_terminals()
  local current_index = state.get_current_index()
  local cfg = config.get()
  local lines = {}

  if #terminals == 0 then
    return { "No terminals", "Press 'n' to create one" }
  end

  terminal.update_all_statuses()

  for i, term in ipairs(terminals) do
    local prefix = " "
    if i == current_index then
      prefix = "> "
    end

    local icon = term.status == "running" and cfg.status_icons.running or cfg.status_icons.idle
    local display_name = term.custom_name or term.title
    table.insert(lines, string.format("%s%s %d. %s", prefix, icon, i, display_name))
  end

  return lines
end

function M.create_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  return buf
end

function M.render()
  local sidebar_buf = state.get_buffers()
  if not sidebar_buf then
    return
  end

  local lines = get_sidebar_content()
  local cfg = config.get()

  -- Suppress W10 warning for readonly file
  local eventignore = vim.o.eventignore
  vim.o.eventignore = "FileType"

  local was_readonly = vim.bo[sidebar_buf].readonly
  vim.bo[sidebar_buf].readonly = false
  vim.bo[sidebar_buf].modifiable = true
  vim.api.nvim_buf_set_lines(sidebar_buf, 0, -1, false, lines)
  vim.bo[sidebar_buf].modifiable = false
  vim.bo[sidebar_buf].readonly = was_readonly

  vim.o.eventignore = eventignore

  -- Clear previous highlights
  vim.api.nvim_buf_clear_namespace(sidebar_buf, ns_id, 0, -1)

  -- Set up syntax highlights for status icons
  vim.api.nvim_buf_add_highlight(sidebar_buf, ns_id, "AcTermIcon", 0, 0, -1)

  -- Highlight current terminal line
  local current_index = state.get_current_index()
  if current_index > 0 then
    vim.api.nvim_buf_add_highlight(sidebar_buf, ns_id, "Visual", current_index - 1, 0, -1)

    -- Calculate icon position (after prefix "> " or " ")
    local prefix_len = 2
    for i, term in ipairs(state.get_terminals()) do
      local icon = term.status == "running" and cfg.status_icons.running or cfg.status_icons.idle
      local icon_len = vim.fn.strdisplaywidth(icon)
      local line_idx = i - 1

      -- Highlight the status icon with different colors based on status
      if term.status == "running" then
        vim.api.nvim_buf_add_highlight(sidebar_buf, ns_id, "AcTermRunning", line_idx, prefix_len, prefix_len + icon_len)
      else
        vim.api.nvim_buf_add_highlight(sidebar_buf, ns_id, "AcTermIdle", line_idx, prefix_len, prefix_len + icon_len)
      end
    end
  end

  -- Move cursor to current line (but keep it visually hidden)
  if current_index > 0 then
    local sidebar_win = state.get_windows()
    if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
      vim.api.nvim_win_set_cursor(sidebar_win, { current_index, 0 })
    end
  end
end

function M.setup_keybinds()
  local sidebar_buf = state.get_buffers()
  if not sidebar_buf then
    return
  end

  local opts = { noremap = true, silent = true, buffer = sidebar_buf }

  -- Navigation
  vim.keymap.set("n", "j", "<cmd>lua require'acterm'.next_terminal()<CR>", opts)
  vim.keymap.set("n", "k", "<cmd>lua require'acterm'.prev_terminal()<CR>", opts)
  vim.keymap.set("n", "<down>", "<cmd>lua require'acterm'.next_terminal()<CR>", opts)
  vim.keymap.set("n", "<up>", "<cmd>lua require'acterm'.prev_terminal()<CR>", opts)

  -- Select terminal by number
  for i = 1, 9 do
    vim.keymap.set("n", tostring(i), string.format("<cmd>lua require'acterm'.goto_terminal(%d)<CR>", i), opts)
  end

  -- Create new terminal
  vim.keymap.set("n", "n", "<cmd>lua require'acterm'.new_terminal()<CR>", opts)

  -- Rename terminal
  vim.keymap.set("n", "r", function()
    local name = vim.fn.input("Rename terminal: ")
    if name and name ~= "" then
      require("acterm").rename_terminal(name)
    end
  end, opts)

  -- Switch to main window (Enter)
  vim.keymap.set("n", "<CR>", function()
    local ui = require("acterm.ui")
    local _, main_win = state.get_windows()
    if main_win and vim.api.nvim_win_is_valid(main_win) then
      vim.api.nvim_set_current_win(main_win)
      -- Update the focus tracking
      ui._set_sidebar_focused(false)
    end
  end, opts)

  -- Close UI
  local cfg = config.get()
  vim.keymap.set("n", cfg.exit_key, "<cmd>lua require'acterm'.close()<CR>", opts)
  vim.keymap.set("n", "<esc>", "<cmd>lua require'acterm'.close()<CR>", opts)
end

return M
