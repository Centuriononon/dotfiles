require("nvim-treesitter.configs").setup({
  ensure_installed = { 
    "typescript", 
    "lua", 
    "javascript", 
    "elixir", 
    "bash", 
    "make", 
    "markdown", 
    "dockerfile",
    "latex"
  },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true
  }
})
