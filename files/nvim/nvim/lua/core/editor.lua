-- Tab size
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.softtabstop = 2

-- Line numbers
vim.cmd("set number")

-- Yank copies to clipboard
vim.o.clipboard = "unnamedplus"

-- Set buffer-local options for the current buffer (e.g., for Markdown files)
vim.api.nvim_exec([[
	autocmd FileType markdown setlocal shiftwidth=2 tabstop=2 softtabstop=2
]], false)
