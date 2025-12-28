-- =========================
-- CONFIGURATION FLAGS
-- =========================
local config = {
  theme = "vscode", -- Options: "vscode", "tokyonight", "catppuccin", "gruvbox"
  silent_mode = false, -- Set true to disable startup messages
  auto_format_xml = true, -- Auto-format XML on save
}

-- =========================
-- PERFORMANCE OPTIMIZATIONS
-- =========================
vim.opt.lazyredraw = true
vim.opt.synmaxcol = 240
vim.opt.re = 0

local disabled_built_ins = {
  "netrw", "netrwPlugin", "netrwSettings", "netrwFileHandlers",
  "gzip", "zip", "zipPlugin", "tar", "tarPlugin",
  "getscript", "getscriptPlugin", "vimball", "vimballPlugin",
  "2html_plugin", "logipat", "rrhelper", "spellfile_plugin", "matchit"
}

for _, plugin in pairs(disabled_built_ins) do
  vim.g["loaded_" .. plugin] = 1
end

-- =========================
-- BASIC SETTINGS
-- =========================
local o = vim.opt
o.number = true
o.relativenumber = true
o.mouse = "a"
o.clipboard = "unnamedplus"
o.termguicolors = true
o.tabstop = 4
o.timeoutlen = 500
o.ttimeoutlen = 10
o.shiftwidth = 4
o.expandtab = true
o.autoindent = true
o.smartindent = true
o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.hlsearch = true
o.hidden = true
o.undofile = true
o.undodir = vim.fn.stdpath("data") .. "/undo"
o.swapfile = false
o.backup = false
o.updatetime = 300
o.signcolumn = "yes"
o.scrolloff = 8
o.sidescrolloff = 8
o.cursorline = true
o.splitright = true
o.splitbelow = true
o.wrap = false
o.laststatus = 3

vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.g.python3_host_prog = vim.fn.exepath("python")
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- =========================
-- LAZY.NVIM SETUP
-- =========================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =========================
-- PLUGINS
-- =========================
require("lazy").setup({
  -- VS Code theme
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,
    enabled = config.theme == "vscode",
    config = function()
      require('vscode').setup({ transparent = false, italic_comments = true })
      vim.cmd('colorscheme vscode')
      if not config.silent_mode then
        vim.notify("Theme loaded: vscode", vim.log.levels.INFO)
      end
    end,
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = { width = 35 },
        filters = { dotfiles = false },
        git = { enable = true },
        renderer = {
          icons = { show = { git = true, folder = true, file = true } }
        }
      })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require('telescope').setup({
        defaults = {
          file_ignore_patterns = { 
            "node_modules", ".git/", "*.pyc", "__pycache__",
            "*.egg-info", ".venv", "venv", "*.o", "*.so"
          },
        },
      })
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require('lualine').setup({
        options = { 
          theme = 'vscode',
          component_separators = { left = '|', right = '|'},
          section_separators = { left = '', right = ''},
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {'branch', 'diff', 'diagnostics'},
          lualine_c = {'filename'},
          lualine_x = {'encoding', 'fileformat', 'filetype'},
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
      })
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local status_ok, ts_configs = pcall(require, "nvim-treesitter.configs")
      if not status_ok then
        vim.notify("Treesitter not ready - restart after install", vim.log.levels.WARN)
        return
      end
      
      ts_configs.setup({
        ensure_installed = { "python", "xml", "javascript", "html", "css", "json", "yaml", "lua" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("mason").setup({ ui = { border = "rounded" } })
      
      require("mason-lspconfig").setup({
        ensure_installed = { "pyright", "lemminx" },
        automatic_installation = true,
      })

      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      
      -- Check if servers are available
      local function setup_lsp_safe(server_name, config_table)
        local ok, _ = pcall(function()
          vim.lsp.config[server_name] = config_table
          vim.lsp.enable(server_name)
        end)
        if not ok then
          vim.notify("LSP " .. server_name .. " failed to start", vim.log.levels.ERROR)
        end
      end

      -- Python LSP
      setup_lsp_safe("pyright", {
        cmd = { "pyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py", "requirements.txt", ".git" },
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "off",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
              extraPaths = { "./addons", "./odoo/addons" },
            }
          }
        },
      })

      -- XML LSP
      setup_lsp_safe("lemminx", {
        cmd = { "lemminx" },
        filetypes = { "xml", "xsd", "xsl", "xslt", "svg" },
        root_markers = { ".git" },
        capabilities = capabilities,
        settings = {
          xml = {
            validation = { enabled = true, noGrammar = "ignore" },
            completion = { autoCloseTags = true },
          }
        },
      })

      -- LSP keymaps
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf, silent = true }
          local km = vim.keymap.set
          
          km("n", "gd", vim.lsp.buf.definition, opts)
          km("n", "K", vim.lsp.buf.hover, opts)
          km("n", "<leader>rn", vim.lsp.buf.rename, opts)
          km("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          km("n", "gr", vim.lsp.buf.references, opts)
          km("n", "<C-k>", vim.lsp.buf.signature_help, opts)
          km("n", "gl", vim.diagnostic.open_float, opts)
          km("n", "[d", vim.diagnostic.goto_prev, opts)
          km("n", "]d", vim.diagnostic.goto_next, opts)
        end,
      })
    end,
  },

  -- Autocomplete
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "luasnip", priority = 750 },
          { name = "buffer", priority = 500 },
          { name = "path", priority = 250 },
        }),
        formatting = {
          format = function(entry, item)
            item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snip]",
              buffer = "[Buf]",
              path = "[Path]",
            })[entry.source.name]
            return item
          end,
        },
      })
    end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local autopairs = require("nvim-autopairs")
      autopairs.setup({})
      
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },

  -- Comment
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = '│' },
          change = { text = '│' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        }
      })
    end,
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    main = "ibl",
    config = function()
      require("ibl").setup({
        indent = { char = "│" },
        scope = { enabled = false },
      })
    end,
  },

  -- Which-key
  {
    "folke/which-key.nvim",
    config = function()
      local wk = require("which-key")
      wk.setup({ icons = { mappings = false } })
      
      -- Register groups
      wk.add({
        { "<leader>f", group = "Find" },
        { "<leader>o", group = "Odoo" },
        { "<leader>t", group = "Toggle" },
        { "<leader>c", group = "Code" },
      })
    end,
  },

  -- Terminal
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({
        open_mapping = [[<C-`>]],
        direction = "float",
        float_opts = { border = "curved", winblend = 0 },
        size = function(term)
          if term.direction == "horizontal" then
            return 15
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.4
          end
        end,
      })
    end,
  },

  -- Bufferline
  {
    "akinsho/bufferline.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          offsets = {
            { filetype = "NvimTree", text = "File Explorer", text_align = "center" }
          },
          diagnostics = "nvim_lsp",
          separator_style = "thin",
        }
      })
    end,
  },
})

-- =========================
-- KEYMAPS
-- =========================
local km = vim.keymap.set
local opts = { silent = true, noremap = true }

-- File operations
km("n", "<C-s>", ":w<CR>", vim.tbl_extend("force", opts, { desc = "Save" }))
km("i", "<C-s>", "<Esc>:w<CR>a", opts)
km("n", "<C-w>", ":bd<CR>", vim.tbl_extend("force", opts, { desc = "Close buffer" }))
km("n", "<C-q>", ":qa<CR>", opts)
km("n", "<Esc>", ":nohlsearch<CR>", opts)

-- File explorer
km("n", "<C-b>", ":NvimTreeToggle<CR>", vim.tbl_extend("force", opts, { desc = "Toggle explorer" }))
km("n", "<leader>e", ":NvimTreeFocus<CR>", vim.tbl_extend("force", opts, { desc = "Focus explorer" }))

-- Telescope
km("n", "<C-p>", ":Telescope find_files<CR>", vim.tbl_extend("force", opts, { desc = "Find files" }))
km("n", "<C-S-f>", ":Telescope live_grep<CR>", vim.tbl_extend("force", opts, { desc = "Search in files" }))
km("n", "<leader>fb", ":Telescope buffers<CR>", vim.tbl_extend("force", opts, { desc = "Buffers" }))
km("n", "<leader>fh", ":Telescope help_tags<CR>", vim.tbl_extend("force", opts, { desc = "Help" }))
km("n", "<leader>fg", ":Telescope git_files<CR>", vim.tbl_extend("force", opts, { desc = "Git files" }))

-- Buffer navigation
km("n", "<C-Tab>", ":BufferLineCycleNext<CR>", opts)
km("n", "<C-S-Tab>", ":BufferLineCyclePrev<CR>", opts)
km("n", "<leader>1", ":BufferLineGoToBuffer 1<CR>", opts)
km("n", "<leader>2", ":BufferLineGoToBuffer 2<CR>", opts)
km("n", "<leader>3", ":BufferLineGoToBuffer 3<CR>", opts)
km("n", "<leader>4", ":BufferLineGoToBuffer 4<CR>", opts)
km("n", "<leader>5", ":BufferLineGoToBuffer 5<CR>", opts)

-- Split navigation
km("n", "<C-h>", "<C-w>h", opts)
km("n", "<C-j>", "<C-w>j", opts)
km("n", "<C-k>", "<C-w>k", opts)
km("n", "<C-l>", "<C-w>l", opts)

-- Move lines
km("n", "<A-Down>", ":m .+1<CR>==", opts)
km("n", "<A-Up>", ":m .-2<CR>==", opts)
km("v", "<A-Down>", ":m '>+1<CR>gv=gv", opts)
km("v", "<A-Up>", ":m '<-2<CR>gv=gv", opts)

-- Comment
km("n", "<C-_>", function() require("Comment.api").toggle.linewise.current() end, opts)
km("v", "<C-_>", "<Esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", opts)

-- Duplicate line
km("n", "<S-A-Down>", "yyp", opts)
km("n", "<S-A-Up>", "yyP", opts)

-- Select all
km("n", "<C-a>", "ggVG", opts)

-- Undo/Redo
km("n", "<C-z>", "u", opts)
km("n", "<C-y>", "<C-r>", opts)

-- Terminal
km("n", "<C-`>", ":ToggleTerm<CR>", opts)
km("t", "<C-`>", "<C-\\><C-n>:ToggleTerm<CR>", opts)
km("t", "<Esc>", "<C-\\><C-n>", opts)

-- Toggle diagnostics
km("n", "<leader>td", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  vim.notify("Diagnostics " .. (vim.diagnostic.is_enabled() and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle diagnostics" })

-- =========================
-- ODOO FEATURES
-- =========================
local function setup_odoo_environment()
  local bufname = vim.fn.expand("%:p")
  
  if bufname:match("/addons/") or bufname:match("\\addons\\") then
    local odoo_root = vim.fn.finddir(".git", ".;")
    if odoo_root ~= "" then
      odoo_root = vim.fn.fnamemodify(odoo_root, ":h")
      vim.env.PYTHONPATH = (vim.env.PYTHONPATH or "") .. ":" .. odoo_root
      vim.env.ODOO_ROOT = odoo_root
      if not config.silent_mode then
        vim.notify("Odoo project: " .. odoo_root, vim.log.levels.INFO)
      end
    end
  end
end

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = {"*/addons/*/*.py", "*/addons/*/*.xml"},
  callback = setup_odoo_environment,
})

-- Python files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.expandtab = true
    
    local buf_km = vim.keymap.set
    buf_km("n", "<leader>oi", "i from odoo import models, fields, api<Esc>", 
      { buffer = true, desc = "Odoo imports" })
    buf_km("n", "<leader>om", "iclass <C-r>=expand('%:t:r')<CR>(models.Model):<CR>_name = ''<Esc>hi", 
      { buffer = true, desc = "Odoo model" })
    buf_km("n", "<leader>of", "i= fields.<Esc>", 
      { buffer = true, desc = "Odoo field" })
  end,
})

-- XML files with auto-format
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "xml", "html" },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.expandtab = true
    
    vim.cmd([[syntax match odooDirective /t-\w\+/]])
    vim.cmd([[highlight link odooDirective Keyword]])
    
    local buf_km = vim.keymap.set
    buf_km("n", "<leader>or", "i<record id=\"\" model=\"\"><CR></record><Esc>", 
      { buffer = true, desc = "Odoo record" })
    buf_km("n", "<leader>ov", "i<field name=\"arch\" type=\"xml\"><CR></field><Esc>", 
      { buffer = true, desc = "Odoo view arch" })
    
    -- Auto-format XML on save
    if config.auto_format_xml then
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = 0,
        callback = function()
          vim.lsp.buf.format({ async = false })
        end,
      })
    end
  end,
})

-- CSV files
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = "*.csv",
  callback = function()
    vim.opt_local.wrap = false
    vim.opt_local.scrollbind = false
  end,
})

-- =========================
-- DIAGNOSTICS
-- =========================
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.HINT] = " ",
      [vim.diagnostic.severity.INFO] = " ",
    }
  }
})

-- =========================
-- HEALTH CHECK
-- =========================
vim.api.nvim_create_user_command("CheckOdooEnv", function()
  local checks = {
    { "Python", vim.fn.executable("python") == 1 },
    { "Pyright", vim.fn.executable("pyright-langserver") == 1 },
    { "Lemminx", vim.fn.executable("lemminx") == 1 },
    { "Git", vim.fn.executable("git") == 1 },
    { "Odoo Root", vim.env.ODOO_ROOT ~= nil },
  }
  
  vim.notify("=== Odoo Environment Check ===", vim.log.levels.INFO)
  for _, check in ipairs(checks) do
    local status = check[2] and "✓" or "✗"
    local level = check[2] and vim.log.levels.INFO or vim.log.levels.WARN
    vim.notify(status .. " " .. check[1], level)
  end
end, {})

-- =========================
-- AUTO-RELOAD CONFIG
-- =========================
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = vim.fn.stdpath("config") .. "/init.lua",
  callback = function()
    vim.cmd("source <afile>")
    vim.notify("Config reloaded!", vim.log.levels.INFO)
  end,
})

-- =========================
-- STARTUP MESSAGE
-- =========================
if not config.silent_mode then
  vim.notify("Neovim ready for Odoo | <Space> for commands | :CheckOdooEnv", vim.log.levels.INFO)
end