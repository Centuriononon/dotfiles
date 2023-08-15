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
function RunTex()
  local fPath = getFPath()
  local fName = getFName()
  local dir = getDir()
  local buildDir = dir .. '/' .. 'compiled_' .. fName
  local pdfPath = buildDir .. '/' .. fName .. '.pdf'

  function mkBuildDirCmd() 
    return 'mkdir -p ' .. buildDir 
  end

  function cmpToBuildDirCmd()
    return 'pdflatex -output-directory=' .. buildDir .. ' ' .. fName 
  end

  function viewBuiltPdfCmd()
    return 'zathura ' .. pdfPath
  end

  function rmBuildDirCmd() 
    return 'rm -r ' .. buildDir 
  end

  local THEN = ' && ' 
  
  fn.system(
    mkBuildDirCmd() .. THEN .. 
    cmpToBuildDirCmd() .. THEN ..
    viewBuiltPdfCmd() .. THEN ..
    rmBuildDirCmd() 
  )
end

vim.cmd('command! -nargs=0 RunTex :lua RunTex()')
