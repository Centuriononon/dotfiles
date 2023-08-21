-- Import
require("settings")
require("plugins")

-- Aliases
local o = vim.o
local fn = vim.fn
local g = vim.g

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
function log_table(table) 
  for key, value in pairs(table) do
    print(key, ":", value) 
  end
end

-- Custom Texer
Tex = {}

function Tex:_run_commands_in_bg(commands, run_handler, end_handler)
  local cmd_id = 1
  
  local function run_cmd(cb)
    print("Running command in bg:", commands[cmd_id])
    return fn.jobstart(commands[cmd_id], {on_exit = cb})
  end

  local function exit_handler(job_id)
    cmd_id = cmd_id + 1 
    local is_end = cmd_id > #commands

    if is_end then
      print("It is end, cmd_id:", cmd_id, "commands:")
      log_table(commands)

      if end_handler then end_handler() end
    else
      print("It is not end, cmd_id:", cmd_id, "commands:")
      log_table(commands)
      
      job_id = run_cmd(exit_handler)
    end
  end

  local function run_commands()
    print("Running command in bg:", commands[cmd_id])
    if run_handler then run_handler(cmd_id, job_id) end
    return fn.jobstart(commands[cmd_id], {on_exit = exit_handler})
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

  print("Executing command:", row)
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

function Tex:get_executor()
  local sessions = {} 

  return function(run) 
    -- Contextual vars 
    local fname = fn.expand('%:r')
    local tex_file = fname .. '.tex'
    local fpath = fn.fnameescape(vim.fn.expand('%:p'))
    local curr_dir = fn.expand('%:p:h')
    local cmp_dir = curr_dir .. '/' .. 'compiled_' .. fname
    local pdf_path = cmp_dir .. '/' .. fname .. '.pdf'

    -- Commands
    local mk_cmp_dir = Tex:_get_make_compile_dir_command(cmp_dir) 
    local cmp = Tex:_get_compile_command(tex_file, cmp_dir)
    local view = Tex:_get_view_command(pdf_path)
    local clean = Tex:_get_clean_command(cmp_dir)
   
    if run == 'compile' then
      Tex:_run_commands(mk_cmp_dir, cmp)	
    elseif run == 'view' then
      Tex:_run_commands_in_bg({view})
    elseif run == 'clean' then
      Tex:_run_commands(clean)
    elseif run == 'flow' then
      Tex:_run_commands(mk_cmp_dir, cmp)	
      local is_new_session = sessions[fpath] == nil
      
      if is_new_session then
	print("It is new session")

	local run_handler = function()
	  print("Session is initiated, viewer started")

	  sessions[fpath] = true 
	end

	local end_handler = function()
	  print("Session is removed, viewer ended")
	  Tex:_run_commands(clean) 
	  sessions[fpath] = nil
	end

	Tex:_run_commands_in_bg({view}, run_handler, end_handler)
      end
    end
  end
end

tex = Tex:get_executor()

vim.cmd('command! -nargs=0 Tex :lua tex("flow")')
vim.cmd('command! -nargs=0 TexCompile :lua tex("compile")')
vim.cmd('command! -nargs=0 TexView :lua tex("view")')
vim.cmd('command! -nargs=0 TexClean :lua tex("clean")')
