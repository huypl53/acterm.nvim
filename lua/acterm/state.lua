local M = {}

local state = {
  terminals = {},
  current_index = 0,
  sidebar_win = nil,
  main_win = nil,
  sidebar_buf = nil,
  main_buf = nil,
  is_open = false,
}

function M.add_terminal(terminal)
  table.insert(state.terminals, terminal)
  if state.current_index == 0 then
    state.current_index = 1
  end
end

function M.remove_terminal(index)
  if index > 0 and index <= #state.terminals then
    table.remove(state.terminals, index)
    if state.current_index > #state.terminals then
      state.current_index = math.max(0, #state.terminals)
    end
  end
end

function M.get_current_index()
  return state.current_index
end

function M.set_current_index(index)
  if index >= 0 and index <= #state.terminals then
    state.current_index = index
  end
end

function M.get_terminals()
  return state.terminals
end

function M.get_terminal(index)
  return state.terminals[index]
end

function M.get_terminal_count()
  return #state.terminals
end

function M.get_windows()
  return state.sidebar_win, state.main_win, state.container_win
end

function M.set_windows(sidebar_win, main_win, container_win)
  state.sidebar_win = sidebar_win
  state.main_win = main_win
  state.container_win = container_win
end

function M.get_buffers()
  return state.sidebar_buf, state.main_buf
end

function M.set_buffers(sidebar_buf, main_buf)
  state.sidebar_buf = sidebar_buf
  state.main_buf = main_buf
end

function M.is_ui_open()
  return state.is_open
end

function M.set_ui_open(is_open)
  state.is_open = is_open
end

function M.reset()
  state.terminals = {}
  state.current_index = 0
  state.sidebar_win = nil
  state.main_win = nil
  state.container_win = nil
  state.sidebar_buf = nil
  state.main_buf = nil
  state.is_open = false
end

function M.set_terminal_name(index, name)
  if index > 0 and index <= #state.terminals then
    state.terminals[index].custom_name = name
  end
end

function M.get_terminal_name(index)
  if index > 0 and index <= #state.terminals then
    return state.terminals[index].custom_name
  end
  return nil
end

function M.set_terminal_status(index, status)
  if index > 0 and index <= #state.terminals then
    state.terminals[index].status = status
  end
end

function M.get_terminal_status(index)
  if index > 0 and index <= #state.terminals then
    return state.terminals[index].status
  end
  return "idle"
end

return M
