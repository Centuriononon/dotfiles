-- Import
require("settings")
require("plugins")

-- Aliases
local o = vim.o
local fn = vim.fn
local g = vim.g
local api = vim.api

-- j+k to switch to visual mode
vim.api.nvim_set_keymap('i', 'jk', '<Esc>', { noremap = true })

-- Keep relative directory context 
vim.cmd('set autochdir')

-- Tab size
o.shiftwidth = 2
o.softtabstop = 2

-- Line numbers
vim.cmd('set number')

-- Yank copies to clipboard
o.clipboard = 'unnamedplus'
-- Vimtex
vim.g.vimtex_quickfix_enabled = 1
vim.g.vimtex_syntax_enabled = 1
vim.g.tex_flavor = "latex"
vim.g.vimtex_compiler_method = "latexmk"
vim.g.vimtex_compiler_latexmk = {
  build_dir = 'build'
}
vim.g.vimtex_view_method = "zathura"
vim.g.latex_view_general_viewer = "zathura"

-- Helpers


-- Log
Log = {}

function Log:log_table(table) 
  for key, value in pairs(table) do
    print(key, ":", value) 
  end
end

-- FileSave 
FileSave = {}

function FileSave:register(group, fn)
  vim.api.nvim_exec(
    "augroup " .. group .. " " 
    .. "autocmd! " 
    .. "autocmd BufWritePost * lua " .. fn .. " "
    .. "augroup END", 
    false
  )
end

function FileSave:deregister(group) 
  vim.api.nvim_exec(
    [[augroup ]] .. group .. [[ autocmd! augroup END]], 
    false
  ) 
end

-- Custom Texer
Tex = {}

function Tex:_run_commands_in_bg(commands, run_handler, end_handler)
  local cmd_id = 1
  
  local function run_cmd(cb)
    return fn.jobstart(commands[cmd_id], {on_exit = cb})
  end

  local function exit_handler(job_id)
    cmd_id = cmd_id + 1 
    local is_end = cmd_id > #commands

    if is_end then
      log_table(commands)

      if end_handler then end_handler() end
    else
      log_table(commands)
      
      job_id = run_cmd(exit_handler)
    end
  end

  local function run_commands()
    job_id = fn.jobstart(commands[cmd_id], {on_exit = exit_handler})
    if run_handler then run_handler(cmd_id, job_id) end

    return job_id
  end
  
  return run_commands() 
end

function Tex:_run_commands(...)
  commands = {...} 

  if #commands == 0 then
    error("Expected 1 command at least.")  
  end

  row = commands[1] 
  
  for i = 2, #commands do
    row = row .. ' && ' .. commands[i] 
  end

  return fn.system(row)
end

function Tex:_get_make_compile_dir_command(output)
  return 'mkdir -p ' .. output
end

function Tex:_get_compile_command(file, output)
  return 'pdflatex -output-directory=' .. output .. ' ' .. file 
end

function Tex:_get_view_command(pdf)
  return 'zathura' .. ' ' .. pdf
end

function Tex:_get_clean_command(output)
  return 'rm -r ' .. output
end

function Tex:new()
  local state = {
    sessions = {}
  }
  setmetatable(state, self)
  self.__index = self

  return state
end

function Tex:_get_context()
    local fname = fn.expand('%:r')
    local tex_file = fname .. '.tex'
    local fpath = fn.fnameescape(vim.fn.expand('%:p'))
    local curr_dir = fn.expand('%:p:h')
    local cmp_dir = curr_dir .. '/' .. 'compiled_' .. fname
    local pdf_path = cmp_dir .. '/' .. fname .. '.pdf'

    return {
      fname = fname,
      tex_file = tex_file,
      fpath = fpath,
      curr_dir = curr_dir,
      cmp_dir = cmp_dir,
      pdf_path = pdf_path
    }
end

function Tex:compile()
  local ctx = Tex:_get_context()

  local mk_cmp_dir = Tex:_get_make_compile_dir_command(ctx.cmp_dir) 
  local cmp = Tex:_get_compile_command(ctx.tex_file, ctx.cmp_dir)
  
  Tex:_run_commands(mk_cmp_dir, cmp)	
end

function Tex:view()
  local ctx = Tex:_get_context()
  
  local view = Tex:_get_view_command(ctx.pdf_path)

  Tex:_run_commands_in_bg({view})
end

function Tex:clean()
  local ctx = Tex:_get_context()

  local clean = Tex:_get_clean_command(ctx.cmp_dir)
  
  Tex:_run_commands(clean)
end

function Tex:flow()
  local ctx = Tex:_get_context()

  Tex:compile()	
  
  local is_new = self.sessions[ctx.fpath] == nil
  
  if is_new then
    local view = Tex:_get_view_command(ctx.pdf_path)

    local run_handler = function(_cmd_id, job_id)
      self.sessions[ctx.fpath] = {
	view_job_id = job_id 
      } 
    end

    local end_handler = function()
      Tex:clean()
      self.sessions[fpath] = nil
    end
    
    Tex:_run_commands_in_bg({view}, run_handler, end_handler)
  end
end

function Tex:stop_flow()
  local ctx = Tex:_get_context()
  
  if self.sessions[ctx.fpath] then
    view_job_id = self.sessions[ctx.fpath].view_job_id 

    fn.jobstop(view_job_id)

    self.sessions[ctx.fpath] = nil
  end

  Tex:clean() 
end

tex = Tex:new()

vim.cmd('command! -nargs=0 TexFlow :lua tex:flow()')
vim.cmd('command! -nargs=0 TexStop :lua tex:stop_flow()')
vim.cmd('command! -nargs=0 TexCompile :lua tex:compile()')
vim.cmd('command! -nargs=0 TexView :lua tex:view()')
vim.cmd('command! -nargs=0 TexClean :lua tex:clean()')
