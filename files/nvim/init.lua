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

-- Log
Log = {}

function Log.log_table(table) 
  for key, value in pairs(table) do
    print(key, ":", value)
  end
end

-- Events
VimEventsHelper = {}

function VimEventsHelper.get_sub_script(group, event, func)
  return string.format([[
    augroup %s 
      autocmd! %s
      autocmd %s * lua %s 
    augroup END
  ]], group, event, event, func)
end

function VimEventsHelper.get_unsub_script(group, event)
  return string.format([[
    augroup %s 
      autocmd! %s 
    augroup END
  ]], group, event)
end

function VimEventsHelper.sub(group, event, func)
  local script = VimEventsHelper.get_sub_script(group, event, func)
  vim.api.nvim_exec(script, false)
end

function VimEventsHelper.unsub(group, event)
  local script = VimEventsHelper.get_unsub_script(group, event) 
  vim.api.nvim_exec(script, false)
end

function VimEventsHelper.format_group_name(str)
  return string.gsub(str, "[%p%c]", "_")  
end

-- VimEvents
VimEvents = {}
_VimEventsRegistry = {}

function VimEvents.pub(group, event)
  local registry = _VimEventsRegistry

  if registry[group] and registry[group][event] then 
    local cb_list = registry[group][event]
   
    Log.log_table(cb_list)
    for i = 1, #cb_list do
      cb_list[i]() 
    end
  end 
end

function VimEvents.sub(group, event, cb)
  local registry = _VimEventsRegistry

  if not registry[group] or not registry[group][event] then
    registry[group] = {}
    registry[group][event] = {}
  end

  table.insert(registry[group][event], cb)

  local func = string.format(
    [[VimEvents.pub("%s", "%s")]], 
    group, event
  )

  VimEventsHelper.sub(group, event, func) 
end

function VimEvents.unsub(group, event)
  local registry = _VimEventsRegistry
  
  VimEventsHelper.unsub(group, event)
  
  if registry[group] then
    registry[group][event] = nil 
  end
end

-- VimEvent
VimEvent = {}

function VimEvent:new(event_name)
  local state = {
    event = event_name 
  }
  setmetatable(state, self)
  self.__index = self

  return state
end

function VimEvent:_pub(group)
  VimEvents.pub(group, self.event)
end

function VimEvent:sub(name, cb)
  local group = VimEventsHelper.format_group_name(name)
  VimEvents.sub(group, self.event, cb)
end

function VimEvent:unsub(name) 
  local group = VimEventsHelper.format_group_name(name)
  VimEvents.unsub(group, self.event)
end

-- FileSaveEvent
FileSaveEvent = VimEvent:new("BufWritePost") 

-- ExitEvent
ExitEvent = VimEvent:new("VimLeavePre")

-- Commander
Commander = {}

function Commander.run_in_bg(commands, run_handler, end_handler)
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


function Commander.run(...)
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

function Commander.stop(id)
  fn.jobstop(id)
end

-- TexHelper
TexHelper = {}

function TexHelper.get_mk_cmp_dir_cmd(output)
  return 'mkdir -p ' .. output
end

function TexHelper.get_cmp_cmd(file, output)
  return 'pdflatex -output-directory=' .. output .. ' ' .. file 
end

function TexHelper.get_view_cmd(pdf)
  return 'zathura' .. ' ' .. pdf
end

function TexHelper.get_clean_cmd(output)
  return 'rm -r ' .. output
end

function TexHelper.get_ctx()
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

-- Tex
Tex = {}

function Tex.compile()
  local ctx = TexHelper.get_ctx()

  local mk_cmp_dir = TexHelper.get_mk_cmp_dir_cmd(ctx.cmp_dir) 
  local cmp = TexHelper.get_cmp_cmd(ctx.tex_file, ctx.cmp_dir)
  
  Commander.run(mk_cmp_dir, cmp)	
end

function Tex.view()
  local ctx = TexHelper.get_ctx()
  
  local view = TexHelper.get_view_cmd(ctx.pdf_path)

  Commander.run_in_bg({view})
end

function Tex.clean()
  local ctx = TexHelper.get_ctx()
  local clean = TexHelper.get_clean_cmd(ctx.cmp_dir)
  Commander.run(clean)
end

-- TexObserver
TexObserver = {}

function TexObserver:new()
  local state = { }
  setmetatable(state, self)
  self.__index = self 
  return state
end

function TexObserver:is_on(key)
  local ctx = TexHelper.get_ctx()
  return self[ctx.fpath] and self[ctx.fpath][key]
end

function TexObserver:enable_compile_on_save()
  local ctx = TexHelper.get_ctx()
 
  if not self:is_on("compile_on_save") then
    FileSaveEvent:sub(ctx.fpath, function() Tex.compile() end)
    self[ctx.fpath] = { compile_on_save = true }
  end
end

function TexObserver:disable_compile_on_save()
  local ctx = TexHelper.get_ctx()

  if self:is_on("compile_on_save") then
    FileSaveEvent:unsub(ctx.fpath)
    self[ctx.fpath].compile_on_save = nil 
  end
end

function TexObserver:enable_clean_on_exit()
  local ctx = TexHelper.get_ctx()
  
  if not self:is_on("clean_on_exit") then
    ExitEvent:sub(ctx.fpath, function() Tex.clean() end) 
    self[ctx.fpath] = { clean_on_exit = true }
  end
end

function TexObserver:disable_clean_on_exit()
  local ctx = TexHelper.get_ctx()
  
  if self:is_on("clean_on_exit") then
    ExitEvent:unsub(ctx.fpath) 
    self[ctx.fpath].clean_on_exit = nil 
  end
end


-- TexSessions
TexSessions = {}

function TexSessions:new(observer)
  local state = { 
    observer = observer,
    sessions = {} 
  }
  setmetatable(state, self)
  self.__index = self 
  return state
end

function TexSessions:compile_view_clean()

  local ctx = TexHelper.get_ctx()

  Tex.compile()	

  if not self.sessions[ctx.fpath] then
    local view_cmd = TexHelper.get_view_cmd(ctx.pdf_path)

    local run_handler = function(_cmd_id, id)
      self.sessions[ctx.fpath] = {
	view_id = id 
      } 
    end

    local end_handler = function()
      Tex.clean()
      self.sessions[ctx.fpath] = nil
    end
    
    Commander.run_in_bg({view_cmd}, run_handler, end_handler)
  end
end

function TexSessions:stop_view()
  local ctx = TexHelper.get_ctx()
  
  if self.sessions[ctx.fpath] then
    view_id = self.sessions[ctx.fpath].view_id 
    Commander.stop(view_id)
    self.sessions[ctx.fpath] = nil
  end
end

function TexSessions:flow()
  self.observer:enable_clean_on_exit()
  self.observer:enable_compile_on_save()
  self:compile_view_clean()
end

tex_observer = TexObserver:new()
tex_sessions = TexSessions:new(tex_observer)

vim.cmd('command! -nargs=0 TexCompile :lua Tex.compile()')
vim.cmd('command! -nargs=0 TexView :lua Tex.view()')
vim.cmd('command! -nargs=0 TexClean :lua Tex.clean()')

vim.cmd('command! -nargs=0 TexEnableCompileOnSave :lua tex_observer:enable_compile_on_save()')
vim.cmd('command! -nargs=0 TexDisableCompileOnSave :lua tex_observer:disable_compile_on_save()')
vim.cmd('command! -nargs=0 TexEnableCleanOnExit :lua tex_observer:enable_clean_on_exit()')
vim.cmd('command! -nargs=0 TexDisableCleanOnExit :lua tex_observer:disable_clean_on_exit()')

vim.cmd('command! -nargs=0 Tex :lua tex_sessions:compile_view_clean()')
vim.cmd('command! -nargs=0 TexFlow :lua tex_sessions:flow()')
