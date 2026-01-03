local M = {}
local state = require("acterm.state")
local config = require("acterm.config")
local activity = require("acterm.activity")

function M.create_terminal(cwd)
  cwd = cwd or vim.fn.getcwd()
  local cfg = config.get()

  local buf = vim.api.nvim_create_buf(false, true)

  local job_id
  vim.api.nvim_buf_call(buf, function()
    job_id = vim.fn.termopen(vim.o.shell, {
      cwd = cwd,
      on_exit = function(_, exit_code, _)
        if exit_code ~= 0 then
          return
        end
      end,
    })
    vim.bo.bufhidden = "hide"
  end)

  if cfg.activity and cfg.activity.enabled then
    activity.start(buf, function()
      if state.is_ui_open() then
        local ok, ui = pcall(require, "acterm.ui")
        if ok and ui.refresh_sidebar then
          ui.refresh_sidebar()
        end
      end
    end)
  end

  return {
    buf = buf,
    job_id = job_id,
    title = vim.fn.fnamemodify(cwd, ":t"),
    cwd = cwd,
    custom_name = nil,
    status = "running",
    last_activity = vim.loop.now(),
  }
end

function M.check_terminal_status(term)
  if not term or not term.job_id then
    return "idle"
  end

  local cfg = config.get()
  if cfg.activity and cfg.activity.enabled then
    local ok = activity.is_idle(term.buf, cfg.activity.idle_ms)
    if ok ~= nil then
      return ok and "idle" or "running"
    end
  end

  local result = vim.fn.jobwait({ term.job_id }, 0)
  if result[1] == -1 then
    return "running"
  end
  return "idle"
end

function M.update_all_statuses()
  local terminals = state.get_terminals()
  for i, term in ipairs(terminals) do
    local status = M.check_terminal_status(term)
    state.set_terminal_status(i, status)
  end
end

function M.close_terminal(index)
  local terminals = state.get_terminals()
  local term = terminals[index]
  if term then
    vim.api.nvim_buf_delete(term.buf, { force = true })
    state.remove_terminal(index)
  end
end

function M.focus_terminal(index)
  local terminals = state.get_terminals()
  if index > 0 and index <= #terminals then
    state.set_current_index(index)
  end
end

function M.cycle_terminal(direction)
  local count = state.get_terminal_count()
  if count == 0 then
    return
  end

  local current = state.get_current_index()
  local cfg = config.get()

  if direction == "next" then
    if current >= count then
      if cfg.wrap_around then
        state.set_current_index(1)
      end
    else
      state.set_current_index(current + 1)
    end
  elseif direction == "prev" then
    if current <= 1 then
      if cfg.wrap_around then
        state.set_current_index(count)
      end
    else
      state.set_current_index(current - 1)
    end
  end
end

function M.rename_terminal(index, new_name)
  state.set_terminal_name(index, new_name)
end

function M.create_custom_terminal(command, cwd)
  cwd = cwd or vim.fn.getcwd()
  local cmd_display = command:match("[^%s]+")  -- Get first word for display title
  local cfg = config.get()

  local buf = vim.api.nvim_create_buf(false, true)
  local job_id

  vim.api.nvim_buf_call(buf, function()
    job_id = vim.fn.termopen(command, {
      cwd = cwd,
      on_exit = function(_, exit_code, _)
        if exit_code ~= 0 then
          return
        end
      end,
    })
    vim.bo.bufhidden = "hide"
  end)

  if cfg.activity and cfg.activity.enabled then
    activity.start(buf, function()
      if state.is_ui_open() then
        local ok, ui = pcall(require, "acterm.ui")
        if ok and ui.refresh_sidebar then
          ui.refresh_sidebar()
        end
      end
    end)
  end

  return {
    buf = buf,
    job_id = job_id,
    title = cmd_display,
    cwd = cwd,
    custom_name = nil,
    status = "running",
    last_activity = vim.loop.now(),
  }
end

return M
