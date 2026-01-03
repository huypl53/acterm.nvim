local M = {}

local state = {}

local function now_ms()
  return vim.uv.now()
end

function M.start(buf, on_change)
  buf = buf or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  if vim.bo[buf].buftype ~= "terminal" then
    return
  end

  local st = {
    last_change_ms = now_ms(),
    pending = false,
    on_change = on_change,
  }
  state[buf] = st

  local attached = vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      st.last_change_ms = now_ms()
      if st.on_change and not st.pending then
        st.pending = true
        vim.schedule(function()
          st.pending = false
          if state[buf] and st.on_change then
            st.on_change(buf)
          end
        end)
      end
    end,
    on_detach = function()
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
