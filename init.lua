-- Set options
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.syntax = 'on'
vim.opt.showmatch = true
vim.opt.filetype = 'on' -- Enable filetype detection

-- Set leader key (before mappings)
vim.g.mapleader = ','

-- Initialize lazy.nvim plugin manager
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin setup with lazy.nvim
require('lazy').setup({
  -- General plugins
  { 'tpope/vim-sensible' },
  { 'junegunn/fzf', build = ':call fzf#install()', event = 'VimEnter' },
  { 'tpope/vim-surround' },
  { 'tpope/vim-commentary' },

  {
    'folke/which-key.nvim',
    config = function()
      require('which-key').setup {}
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup {
        ensure_installed = { 'c', 'cpp', 'ocaml', 'haskell', 'rust' }, -- Languages you use
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true
        },
      }
    end,
  },

  {
    'morhetz/gruvbox',
    config = function()
      vim.cmd('colorscheme gruvbox')
      vim.opt.background = 'dark' -- Use dark variant
    end,
  },
  -- File explorer (replacing NERDTree)
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = { 'NvimTreeToggle', 'NvimTreeOpen' },
    config = function()
      require('nvim-tree').setup {
        view = {
          side = 'left',
          width = 30,
        },
        renderer = {
          icons = {
            show = {
              git = true,
              folder = true,
              file = true,
            },
          },
        },
      }
    end,
  },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        haskell = { "ormolu" },
        rust = { "rustfmt" }, -- Fixed: replaced '.' with ','
      },
      format_on_save = false,
    },
  },
  -- Auto-pairs (replacing manual inoremap mappings)
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup {
        check_ts = true, -- Integrate with treesitter (if installed)
        disable_filetype = { 'TelescopePrompt', 'vim' },
      }
    end,
  },

  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'hrsh7th/nvim-cmp', event = 'InsertEnter' },
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'L3MON4D3/LuaSnip', event = 'InsertEnter' },
      { 'saadparwaiz1/cmp_luasnip' },
      { 'ray-x/lsp_signature.nvim', event = 'InsertEnter' },
    },
    config = function()
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local on_attach = function(client, bufnr)
        vim.keymap.set('n', '<Leader>p', vim.lsp.buf.signature_help, {
          buffer = bufnr,
          noremap = true,
          silent = true,
          desc = 'Show function signature',
        })
        require('lsp_signature').on_attach({
          bind = true,
          handler_opts = { border = 'rounded' },
          floating_window = true,
          floating_window_above_cur_line = false,
          floating_window_off_x = 10,
          floating_window_off_y = -2,
          fix_pos = false,
          zindex = 100,
          always_trigger = true,
          hint_enable = false,
          auto_close_after = nil,
        }, bufnr)
      end
      if vim.fn.executable('clangd') == 1 then
        lspconfig.clangd.setup {
          capabilities = capabilities,
          filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
          on_attach = on_attach,
        }
      end
      if vim.fn.executable('ocamllsp') == 1 then
        lspconfig.ocamllsp.setup {
          capabilities = capabilities,
          filetypes = { 'ocaml', 'reason' },
          on_attach = on_attach,
        }
      end
      if vim.fn.executable('haskell-language-server-wrapper') == 1 then
        lspconfig.hls.setup {
          capabilities = capabilities,
          filetypes = { 'haskell', 'lhaskell' },
          on_attach = on_attach,
          settings = {
            haskell = {
              formattingProvider = 'ormolu',
            },
          },
        }
      end
      if vim.fn.executable('rust-analyzer') == 1 then
        lspconfig.rust_analyzer.setup {
          capabilities = capabilities,
          filetypes = { 'rust' },
          on_attach = on_attach,
          settings = {
            ['rust-analyzer'] = {
              check = {
                command = 'clippy', -- Use clippy for checks on save
              },
              checkOnSave = true,
              diagnostics = {
                enable = true,
              },
              cargo = {
                allFeatures = true, -- Build with all features enabled
              },
            },
          },
        }
      end
    end,
  },
  {
    'hrsh7th/nvim-cmp',
    config = function()
      local cmp = require('cmp')
      cmp.setup {
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<C-p>'] = cmp.mapping(function(fallback)
            if vim.lsp.buf.signature_help() then
              return
            end
            fallback()
          end, { 'i', 'c' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
        }),
        lsp = {
          signature = {
            enabled = true,
            auto_open = {
              enabled = true,
              trigger = true,
            },
          },
        },
      }
    end,
  },
  { 'rust-lang/rust.vim' },
})

-- Filetype-specific settings
vim.api.nvim_create_autocmd({'FileType', 'BufWinEnter' }, {
  pattern = { 'c', 'cpp', 'asm', 's', 'hs' },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
    vim.opt_local.autoindent = true
    vim.opt_local.cindent = true
  end,
})

vim.api.nvim_create_autocmd({'FileType', 'BufWinEnter' }, {
  pattern = 'lua',
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
    vim.opt_local.autoindent = true
    vim.opt_local.smartindent = true -- Better for Lua than cindent
    vim.opt_local.cindent = false -- Disable cindent for Lua
  end,
})

vim.api.nvim_create_autocmd({'FileType', 'BufWinEnter' }, {
  pattern = 'rust', -- Fixed: missing comma after 'pattern'
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
    vim.opt_local.autoindent = true
    vim.opt_local.cindent = true
  end,
})

-- Terminal mappings
vim.keymap.set('t', '<Esc>', '<C-\\><C-N>', { noremap = true, silent = true })

-- Custom command for 12-row terminal
vim.api.nvim_create_user_command('Term12', 'below 12new | term', {})

-- Keybinding for terminal
vim.keymap.set('n', '<Leader>t', ':Term12<CR>', { noremap = true, silent = true})

-- Keybinding for nvim-tree
vim.keymap.set('n', '<Leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true })

-- OPAM configuration
local opam_share_dir = vim.fn.system('opam var share'):gsub('[\r\n]*$', '')
local opam_configuration = {}

opam_configuration['ocp-indent'] = function()
  vim.opt.rtp:prepend(opam_share_dir .. '/ocp-indent/vim')
end

opam_configuration['ocp-index'] = function()
  vim.opt.rtp:append(opam_share_dir .. '/ocp-index/vim')
end

opam_configuration['merlin'] = function()
  local dir = opam_share_dir .. '/merlin/vim'
  vim.opt.rtp:append(dir)
end

local opam_packages = { 'ocp-indent', 'ocp-index', 'merlin' }
local opam_available_tools = {}
for _, tool in ipairs(opam_packages) do
  if vim.fn.isdirectory(opam_share_dir .. '/' .. tool) == 1 then
    table.insert(opam_available_tools, tool)
    opam_configuration[tool]()
  end
end

-- Fallback for ocp-indent if not in opam_available_tools
if not vim.tbl_contains(opam_available_tools, 'ocp-indent') then
  vim.cmd.source('/home/bob/.opam/default/share/ocp-indent/vim/indent/ocaml.vim')
end

-- Enable filetype plugins and indent
vim.cmd('filetype plugin indent on')

-- Function to compile and run C/C++ files
local function compile_and_run()
  local filetype = vim.bo.filetype
  if filetype ~= "c" and filetype ~= "cpp" then
    vim.notify('Error: RunFile only supports C/C++ files', vim.log.levels.ERROR)
    return
  end
  -- Always save the buffer silently
  vim.cmd('silent write')
  local filename = vim.fn.expand('%:p')
  local basename = vim.fn.expand('%:t:r')
  local dir = vim.fn.expand('%:p:h')
  local compiler = (filetype == "cpp") and 'g++' or 'gcc'
  local std = (filetype == "cpp") and 'c++17' or 'c11'
  local cmd = string.format(
    'cd %s && %s -Wall -std=%s %s -o %s && chmod +x %s && ./%s; exec $SHELL',
    vim.fn.shellescape(dir),
    compiler,
    std,
    vim.fn.shellescape(filename),
    vim.fn.shellescape(basename),
    vim.fn.shellescape(basename),
    basename
  )
  vim.notify('Running: ' .. cmd, vim.log.levels.INFO)
  vim.cmd('below 12new')
  vim.fn.termopen(cmd)
  vim.cmd('startinsert')
end

-- Create user command
vim.api.nvim_create_user_command('RunFile', compile_and_run, {})

-- Map to <Leader>r
vim.keymap.set('n', '<Leader>r', ':RunFile<CR>', { noremap = true, silent = true })

-- Function to compile C/C++ files
local function compile_c()
  local filetype = vim.bo.filetype
  if filetype ~= "c" and filetype ~= "cpp" then
    vim.notify('Error: CompileC only supports C/C++ files', vim.log.levels.ERROR)
    return
  end
  -- Always save the buffer silently
  vim.cmd('silent write')
  local filename = vim.fn.expand('%:p')
  local basename = vim.fn.expand('%:t:r')
  local dir = vim.fn.expand('%:p:h')
  local compiler = (filetype == "cpp") and 'g++' or 'gcc'
  local std = (filetype == "cpp") and 'c++17' or 'c11'
  local cmd = string.format(
    'cd %s && %s -Wall -std=%s %s -o %s',
    vim.fn.shellescape(dir),
    compiler,
    std,
    vim.fn.shellescape(filename),
    vim.fn.shellescape(basename)
  )
  vim.notify('Compiling: ' .. cmd, vim.log.levels.INFO)
  vim.cmd('below 12new') -- Open 12-row terminal
  vim.fn.termopen(cmd)
  vim.cmd('startinsert')
end

-- Create user command
vim.api.nvim_create_user_command('CompileC', compile_c, {})

-- Map to <Leader>b
vim.keymap.set('n', '<Leader>b', ':CompileC<CR>', { noremap = true, silent = true, desc = 'Compile C/C++ file' })

-- Function to compile C/C++ files
local function compile_debug_c()
  local filetype = vim.bo.filetype
  if filetype ~= "c" and filetype ~= "cpp" then
    vim.notify('Error: DebugC only supports C/C++ files', vim.log.levels.ERROR)
    return
  end
  -- Always save the buffer silently
  vim.cmd('silent write')
  local filename = vim.fn.expand('%:p')
  local basename = vim.fn.expand('%:t:r')
  local dir = vim.fn.expand('%:p:h')
  local compiler = (filetype == "cpp") and 'g++' or 'gcc'
  local std = (filetype == "cpp") and 'c++17' or 'c11'
  local cmd = string.format(
    'cd %s && %s -g -Wall -std=%s %s -o %s',
    vim.fn.shellescape(dir),
    compiler,
    std,
    vim.fn.shellescape(filename),
    vim.fn.shellescape(basename)
  )
  vim.notify('Compiling w/ debug: ' .. cmd, vim.log.levels.INFO)
  vim.cmd('below 12new') -- Open 12-row terminal
  vim.fn.termopen(cmd)
  vim.cmd('startinsert')
end

-- Create user command
vim.api.nvim_create_user_command('DebugC', compile_debug_c, {})

-- Map to <Leader>b
vim.keymap.set('n', '<Leader>d', ':DebugC<CR>', { noremap = true, silent = true, desc = 'Compile and Debug C/C++ file' })



-- Open a file and close the current buffer
vim.api.nvim_create_user_command('EditAndClose', function(opts)
  if opts.args == '' then
    vim.notify('Error: File path required', vim.log.levels.ERROR)
    return
  end
  local current_buf = vim.api.nvim_get_current_buf()
  vim.cmd('edit ' .. vim.fn.fnameescape(opts.args))
  if vim.api.nvim_buf_is_valid(current_buf) and vim.fn.buflisted(current_buf) == 1 then
    vim.cmd('bdelete ' .. current_buf)
  end
end, { nargs = 1, complete = 'file' })

-- Mapping
vim.keymap.set('n', '<Leader>o', ':EditAndClose ', { noremap = true, silent = false, desc = 'Open file and close current buffer' })

-- Command to reformat Lua files
vim.api.nvim_create_user_command('FormatLua', function()
  if vim.bo.filetype ~= 'lua' then
    vim.notify('Error: FormatLua only supports Lua files', vim.log.levels.ERROR)
    return
  end
  vim.opt_local.tabstop = 2
  vim.opt_local.shiftwidth = 2
  vim.opt_local.expandtab = true
  vim.opt_local.autoindent = true
  vim.opt_local.smartindent = true
  vim.opt_local.cindent = false
  vim.cmd('%retab!')
  vim.cmd('%s/\\s\\+$//e')
  vim.cmd('%s/^\\(\\s*\\)\\zs\\s\\{2,\\}/  /g')
  vim.cmd('normal! ggVG=')
  vim.cmd('write')
  vim.notify('Lua file reformatted with 2-space indentation', vim.log.levels.INFO)
end, { desc = 'Reformat Lua file with 2-space indentation' })

-- Optional mapping
vim.keymap.set('n', '<Leader>fl', ':FormatLua<CR>', { noremap = true, silent = true, desc = 'Format Lua file' })

-- Function to compile and run Rust files
local function compile_and_run_rust()
  local filetype = vim.bo.filetype
  if filetype ~= "rust" then
    vim.notify('Error: RunRust only supports Rust files', vim.log.levels.ERROR)
    return
  end
  -- Always save the buffer silently
  vim.cmd('silent write')
  local filename = vim.fn.expand('%:p')
  local dir = vim.fn.expand('%:p:h')
  local cmd = string.format(
    'cd %s && cargo build --release && cargo run --release; exec $SHELL',
    vim.fn.shellescape(dir)
  )
  vim.notify('Running: ' .. cmd, vim.log.levels.INFO)
  vim.cmd('below 12new')
  vim.fn.termopen(cmd)
  vim.cmd('startinsert')
end

-- Create user command for Rust
vim.api.nvim_create_user_command('RunRust', compile_and_run_rust, {})

-- Map to <Leader>r for Rust files
vim.keymap.set('n', '<Leader>r', function()
  if vim.bo.filetype == 'rust' then
    vim.cmd('RunRust')
  else
    vim.cmd('RunFile') -- Fallback to C/C++ for non-Rust files
  end
end, { noremap = true, silent = true, desc = 'Run file (Rust or C/C++)' })

-- Function to compile Rust files
local function compile_rust()
  local filetype = vim.bo.filetype
  if filetype ~= "rust" then
    vim.notify('Error: CompileRust only supports Rust files', vim.log.levels.ERROR)
    return
  end
  -- Always save the buffer silently
  vim.cmd('silent write')
  local dir = vim.fn.expand('%:p:h')
  local cmd = string.format(
    'cd %s && cargo build',
    vim.fn.shellescape(dir)
  )
  vim.notify('Compiling: ' .. cmd, vim.log.levels.INFO)
  vim.cmd('below 12new')
  vim.fn.termopen(cmd)
  vim.cmd('startinsert')
end

-- Create user command for Rust compilation
vim.api.nvim_create_user_command('CompileRust', compile_rust, {})

-- Map to <Leader>b for Rust files
vim.keymap.set('n', '<Leader>b', function()
  if vim.bo.filetype == 'rust' then
    vim.cmd('CompileRust')
  else
    vim.cmd('CompileC') -- Fallback to C/C++ for non-Rust files
  end
end, { noremap = true, silent = true, desc = 'Compile file (Rust or C/C++)' })
