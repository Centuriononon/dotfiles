require("nvim-treesitter.configs").setup({
  ensure_installed = { 
    "typescript", 
    "lua", 
    "javascript", 
    "elixir", 
		"heex",
    "bash", 
    "make", 
    "markdown", 
    "dockerfile",
		"latex"
  },
	ensure_installed = {
		"typescript", 
		"javascript", 
		"elixir", 
		"heex"
	},
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true
  }
})
