-- Aliases
local o     = vim.o
local fn    = vim.fn

-- Helpers
function getFPath() 
  return fn.fnameescape(vim.fn.expand('%:p'))
end

function getFName()
  return fn.expand('%:r')
end

function getDir()
  return fn.expand('%:p:h')
end

-- j+k to switch to visual mode
vim.api.nvim_set_keymap('i', 'jk', '<Esc>', { noremap = true })

-- Keep relative directory context 
vim.cmd('set noautochdir')

-- Tab size
o.shiftwidth = 2
o.softtabstop = 2

-- Line numbers
vim.cmd('set number')

-- This is used to view compiled .tex files 
Tex = {}

function Tex:_getCtx()
  fName = getFName()
  fPath = getFPath()
  curDir = getDir()
  buildDir = curDir .. '/' .. 'compiled_' .. fName

  return {
    fPath = fPath,
    fName = fName,
    curDir = curDir,
    buildDir = buildDir 
  }   
end

function Tex:_getCmpCmd()
  local ctx = Tex:_getCtx()

  mkDir = 'mkdir -p ' .. ctx.buildDir 
  cmpToDir = 'pdflatex -output-directory=' .. ctx.buildDir .. ' ' .. ctx.fName

  return mkDir .. ' && ' .. cmpToDir
end

function Tex:_getViewCmd()
  local ctx = Tex:_getCtx()
  local pdfPath = ctx.buildDir .. '/' .. ctx.fName .. '.pdf'
  
  return 'zathura ' .. pdfPath
end

function Tex:_getCleanCmd()
  local ctx = Tex:_getCtx()
  return 'rm -r ' .. ctx.buildDir
end

function Tex:Run(cmd)
  local cmp = Tex:_getCmpCmd()
  local view = Tex:_getViewCmd()
  local clean = Tex:_getCleanCmd()
  local THEN = ' && '

  if cmd == 'cmp' then
    fn.system(cmp)
  elseif cmd == 'view' then
    fn.system(view)
  elseif cmd == 'clean' then
    fn.system(clean)
  elseif cmd == nil then
    fn.system(cmp .. THEN .. view .. THEN .. clean)
  end
end

vim.cmd('command! -nargs=0 Tex :lua Tex:Run()')
vim.cmd('command! -nargs=0 TexCmp :lua Tex:Run("cmp")')
vim.cmd('command! -nargs=0 TexView :lua Tex:Run("view")')
vim.cmd('command! -nargs=0 TexClean :lua Tex:Run("clean")')
