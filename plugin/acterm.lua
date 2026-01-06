-- Lazy load the plugin - only load when commands are used
if vim.g.loaded_acterm_ui then
  return
end
vim.g.loaded_acterm_ui = true

-- Set up highlight groups
local function setup_highlights()
  -- Use NormalFloat which colorschemes define specifically for floating windows
  vim.api.nvim_set_hl(0, "AcTermNormal", { link = "NormalFloat", default = true })
  vim.api.nvim_set_hl(0, "AcTermBorder", { link = "FloatBorder", default = true })
  vim.api.nvim_set_hl(0, "AcTermCursorLine", { link = "CursorLine", default = true })
  vim.api.nvim_set_hl(0, "AcTermRunning", { link = "DiagnosticOk", default = true })
  vim.api.nvim_set_hl(0, "AcTermIdle", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "AcTermIcon", { link = "Special", default = true })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = setup_highlights,
})

setup_highlights()

local function lazy_load()
  return require("acterm")
end

-- Create commands
vim.api.nvim_create_user_command("AcTermUI", function()
  lazy_load().toggle()
end, { desc = "Toggle the multi-terminal UI" })

vim.api.nvim_create_user_command("AcTermOpen", function()
  lazy_load().open()
end, { desc = "Open the multi-terminal UI" })

vim.api.nvim_create_user_command("AcTermClose", function()
  lazy_load().close()
end, { desc = "Close the multi-terminal UI" })

vim.api.nvim_create_user_command("AcTermNew", function(opts)
  local cwd = opts.args and vim.fn.expand(opts.args) or nil
  lazy_load().new_terminal(cwd)
end, { nargs = "?", desc = "Create a new terminal", complete = "dir" })

vim.api.nvim_create_user_command("AcTermNext", function()
  lazy_load().next_terminal()
end, { desc = "Switch to next terminal" })

vim.api.nvim_create_user_command("AcTermPrev", function()
  lazy_load().prev_terminal()
end, { desc = "Switch to previous terminal" })

vim.api.nvim_create_user_command("AcTermGoto", function(opts)
  local index = tonumber(opts.args)
  if index then
    lazy_load().goto_terminal(index)
  end
end, { nargs = 1, desc = "Go to terminal by index" })

vim.api.nvim_create_user_command("AcTermFocusSidebar", function()
  lazy_load().focus_sidebar()
end, { desc = "Focus the sidebar" })

vim.api.nvim_create_user_command("AcTermToggleSidebar", function()
  lazy_load().toggle_sidebar()
end, { desc = "Toggle sidebar visibility" })

vim.api.nvim_create_user_command("AcTermRename", function(opts)
  lazy_load().rename_terminal(opts.args)
end, { nargs = 1, desc = "Rename current terminal" })
