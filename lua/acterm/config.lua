local M = {}

local defaults = {
  sidebar = {
    width = 25,
  },
  main = {
    width = 80,
    height = 30,
  },
  gap = 0,
  layout = "horizontal",
  auto_create = true,
  wrap_around = true,
  border = "rounded",
  seamless_borders = true,
  winblend = 10,
  activity = {
    enabled = true,
    poll_ms = 200,
    idle_ms = 1000,
    debounce_ms = 100,  -- Wait for output to pause before refreshing sidebar
  },
  scrollback = 1000,  -- Maximum lines of terminal history to keep (reduces RAM usage)
  status_icons = {
    running = "",
    idle = "",
  },
  border_color = "FloatBorder",  -- Highlight group for border color
  keys = {
    toggle = "<leader>tt",
    new = "<leader>tn",
    next = "<leader>tj",
    prev = "<leader>tk",
    focus_sidebar = "<leader>ts",
    toggle_sidebar = "<leader>tp",
    rename = "r",
  },
  exit_key = "q",
  custom_commands = {},
}

local config = vim.deepcopy(defaults)

function M.setup(user_config)
  user_config = user_config or {}

  -- Deep merge user config with defaults
  config = vim.tbl_deep_extend("force", defaults, user_config)

  -- Handle nested tables that might need special merging
  if user_config.sidebar then
    config.sidebar = vim.tbl_extend("force", defaults.sidebar, user_config.sidebar)
  end
  if user_config.main then
    config.main = vim.tbl_extend("force", defaults.main, user_config.main)
  end
  if user_config.keys then
    config.keys = vim.tbl_extend("force", defaults.keys, user_config.keys)
  end
  if user_config.activity then
    config.activity = vim.tbl_extend("force", defaults.activity, user_config.activity)
  end
end

function M.get()
  return config
end

function M.parse_size(size, max_size)
  if size < 1 then
    return math.floor(size * max_size)
  end
  return size
end

return M
