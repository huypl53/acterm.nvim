local M = {}
local state = require("acterm.state")
local config = require("acterm.config")
local sidebar = require("acterm.sidebar")

-- Track current focused window (true = sidebar, false = main)
local _sidebar_focused = false
local _sidebar_timer = nil

local function render_sidebar(sidebar_win)
  if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
    vim.api.nvim_win_call(sidebar_win, function()
      sidebar.render()
      vim.cmd("redraw")
    end)
  else
    sidebar.render()
    vim.cmd("redraw")
  end
end

local function calculate_positions()
  local cfg = config.get()
  local sidebar_width = config.parse_size(cfg.sidebar.width, vim.o.columns)
  local main_width = config.parse_size(cfg.main.width, vim.o.columns)
  local main_height = config.parse_size(cfg.main.height, vim.o.lines)
  local ui_width = sidebar_width + cfg.gap + main_width
  local ui_height = main_height

  -- Add 2 for border padding on each side
  local container_width = ui_width + 2
  local container_height = ui_height + 2

  local row = math.floor((vim.o.lines - container_height) / 2)
  local col = math.floor((vim.o.columns - container_width) / 2)

  return {
    container = {
      row = row,
      col = col,
      width = container_width,
      height = container_height,
    },
    sidebar = {
      row = row + 1,
      col = col + 1,
      width = sidebar_width,
      height = ui_height,
    },
    main = {
      row = row + 1,
      col = col + 1 + sidebar_width + cfg.gap,
      width = main_width,
      height = ui_height,
    },
  }
end

function M.open()
  if state.is_ui_open() then
    return
  end

  local cfg = config.get()
  local positions = calculate_positions()

  -- Create container window with border (no content, just for border)
  local container_buf = vim.api.nvim_create_buf(false, true)
  local container_win = vim.api.nvim_open_win(container_buf, true, {
    relative = "editor",
    width = positions.container.width,
    height = positions.container.height,
    row = positions.container.row,
    col = positions.container.col,
    style = "minimal",
    border = cfg.border,
  })
  vim.wo[container_win].winblend = cfg.winblend
  vim.wo[container_win].winhl = "Normal:AcTermNormal,FloatBorder:AcTermBorder"

  -- Create sidebar buffer and window (no border, inside container)
  local sidebar_buf = state.get_buffers()
  if not sidebar_buf or not vim.api.nvim_buf_is_valid(sidebar_buf) then
    sidebar_buf = sidebar.create_buffer()
  end

  local sidebar_win = vim.api.nvim_open_win(sidebar_buf, false, {
    relative = "editor",
    width = positions.sidebar.width,
    height = positions.sidebar.height,
    row = positions.sidebar.row,
    col = positions.sidebar.col,
    style = "minimal",
    border = "none",
  })
  vim.wo[sidebar_win].winblend = cfg.winblend
  vim.wo[sidebar_win].cursorline = true
  vim.wo[sidebar_win].cursorcolumn = false
  vim.wo[sidebar_win].winhl = "Normal:AcTermNormal,CursorLine:AcTermCursorLine"

  -- Get or create terminal
  local terminals = state.get_terminals()
  local main_buf

  if #terminals == 0 and cfg.auto_create then
    local terminal = require("acterm.terminal").create_terminal()
    state.add_terminal(terminal)
    -- Explicitly set current_index and get buf from state
    state.set_current_index(1)
    main_buf = state.get_terminal(1).buf
  elseif state.get_current_index() > 0 then
    main_buf = state.get_terminal(state.get_current_index()).buf
  else
    main_buf = vim.api.nvim_create_buf(false, true)
  end

  -- Create main terminal window (no border, inside container)
  local main_win = vim.api.nvim_open_win(main_buf, true, {
    relative = "editor",
    width = positions.main.width,
    height = positions.main.height,
    row = positions.main.row,
    col = positions.main.col,
    style = "minimal",
    border = "none",
  })
  vim.wo[main_win].winblend = cfg.winblend
  vim.wo[main_win].winhl = "Normal:AcTermNormal"

  -- Set up exit keybinding for main window (normal mode only)
  vim.api.nvim_buf_set_keymap(main_buf, "n", cfg.exit_key, "<cmd>lua require('acterm').close()<CR>", {
    noremap = true,
    silent = true,
  })

  state.set_buffers(sidebar_buf, main_buf)
  state.set_windows(sidebar_win, main_win, container_win)
  state.set_ui_open(true)
  _sidebar_focused = false

  -- Setup sidebar keybinds and render contents
  sidebar.setup_keybinds()
  render_sidebar(sidebar_win)

  local refresh_group = vim.api.nvim_create_augroup("AcTermSidebarRefresh", { clear = true })
  vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
    group = refresh_group,
    buffer = sidebar_buf,
    callback = function()
      if state.is_ui_open() then
        render_sidebar(sidebar_win)
      end
    end,
  })

  local activity_cfg = config.get().activity or {}
  local refresh_ms = activity_cfg.poll_ms or 200
  if _sidebar_timer then
    _sidebar_timer:stop()
    _sidebar_timer:close()
    _sidebar_timer = nil
  end
  _sidebar_timer = vim.uv.new_timer()
  _sidebar_timer:start(refresh_ms, refresh_ms, vim.schedule_wrap(function()
    if not state.is_ui_open() then
      return
    end
    render_sidebar(sidebar_win)
  end))

  -- Focus main window last (default)
  vim.api.nvim_set_current_win(main_win)
end

function M.close()
  local sidebar_win, main_win, container_win = state.get_windows()

  if container_win and vim.api.nvim_win_is_valid(container_win) then
    vim.api.nvim_win_close(container_win, true)
  end

  if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
    vim.api.nvim_win_close(sidebar_win, true)
  end

  if main_win and vim.api.nvim_win_is_valid(main_win) then
    vim.api.nvim_win_close(main_win, true)
  end

  state.set_ui_open(false)
  _sidebar_focused = false
  if _sidebar_timer then
    _sidebar_timer:stop()
    _sidebar_timer:close()
    _sidebar_timer = nil
  end
end

function M.toggle()
  if state.is_ui_open() then
    M.close()
  else
    M.open()
  end
end

function M.update()
  if not state.is_ui_open() then
    return
  end

  local _, main_win = state.get_windows()
  local current_index = state.get_current_index()
  local terminals = state.get_terminals()

  if current_index > 0 and terminals[current_index] then
    local term_buf = terminals[current_index].buf
    vim.api.nvim_win_set_buf(main_win, term_buf)
  end

  local sidebar_win = state.get_windows()
  render_sidebar(sidebar_win)
end

function M.refresh_sidebar()
  if not state.is_ui_open() then
    return
  end
  local sidebar_win = state.get_windows()
  render_sidebar(sidebar_win)
end

function M.focus_sidebar()
  local sidebar_win, main_win = state.get_windows()
  if not sidebar_win or not main_win then
    return
  end

  if not vim.api.nvim_win_is_valid(sidebar_win) or not vim.api.nvim_win_is_valid(main_win) then
    return
  end

  -- Toggle between sidebar and main window
  if _sidebar_focused then
    vim.api.nvim_set_current_win(main_win)
    _sidebar_focused = false
  else
    vim.api.nvim_set_current_win(sidebar_win)
    _sidebar_focused = true
    render_sidebar(sidebar_win)
  end
end

-- Helper function to set focus state (used by sidebar Enter key)
function M._set_sidebar_focused(focused)
  _sidebar_focused = focused
end

return M
