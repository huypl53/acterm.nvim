local M = {}

local state = {}
local debounce_timers = {}

local function close_timer(timer)
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
end

local function now_ms()
  return vim.uv.now()
end

-- Clear debounce timer for a buffer
local function clear_timer(buf)
  if debounce_timers[buf] then
    close_timer(debounce_timers[buf])
    debounce_timers[buf] = nil
  end
end

function M.start(buf, on_change, debounce_ms)
  buf = buf or vim.api.nvim_get_current_buf()
  debounce_ms = debounce_ms or 100  -- Default 100ms debounce

  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  if vim.bo[buf].buftype ~= "terminal" then
    return
  end

  local st = {
    last_change_ms = now_ms(),
    on_change = on_change,
    debounce_ms = debounce_ms,
  }
  state[buf] = st

  local attached = vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      st.last_change_ms = now_ms()
      -- Clear existing timer and schedule new one (debounce)
      clear_timer(buf)

      local timer = vim.loop.new_timer()
      debounce_timers[buf] = timer
      timer:start(debounce_ms, 0, function()
        vim.schedule(function()
          -- Only call if this timer is still the current one (not superseded)
          if debounce_timers[buf] == timer and state[buf] and st.on_change then
            st.on_change(buf)
          end
          if debounce_timers[buf] == timer then
            debounce_timers[buf] = nil
            close_timer(timer)
          end
        end)
      end)
    end,
    on_detach = function()
      clear_timer(buf)
      state[buf] = nil
    end,
  })

  if not attached then
    return
  end

  vim.api.nvim_create_autocmd({ "BufWipeout", "TermClose" }, {
    buffer = buf,
    once = true,
    callback = function()
      clear_timer(buf)
      state[buf] = nil
    end,
  })
end

function M.is_idle(buf, idle_ms)
  buf = buf or vim.api.nvim_get_current_buf()
  idle_ms = idle_ms or 1000
  local st = state[buf]
  if not st then
    return nil, "not tracking this buffer"
  end
  local dt = now_ms() - st.last_change_ms
  return dt >= idle_ms, dt
end

return M
