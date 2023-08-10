{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "tpopp";
  home.homeDirectory = "/home/tpopp";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # zsh as bash replacement
  programs.zsh = {
    enable = true;

    # zsh extension package manager
    oh-my-zsh = {
      enable = true;
      plugins = [
        "aliases"              # Alias searcher useful to find plugin goodies
        "branch"               # Display current git branch
        "copyfile"             # Puts contents of file into clipboard
        "docker"               # `docker` completion and aliases
        "docker-compose"       # `docker-compose` completion and aliases
        "gitfast"              # `git` completion
        "git-extras"           # Completions for `git-extras`
        "gh"                   # GitHub CLI completion
        "jump"                 # `mark` and `jump` to directories
        "ssh-agent"            # Automatically start `ssh-agent`
        "safe-paste"           # Prevent automatic execution when copy-pasting
        "tmux"                 # `tmux` aliases
        "vi-mode"              # vi > emacs(?)
        "zsh-interactive-cd"   # Interative cd file choosing
        "zsh-navigation-tools" # Many fancy tools
      ];
    };

    # Automatic tmux session when opening terminal application or connecting
    # with ssh.
    sessionVariables = {
      ZSH_TMUX_AUTOSTART = "true";
      ZSH_TMUX_AUTOCONNECT = "true";
    };
  };

  # tmux maintains shell state across accesses like screen
  programs.tmux = {
    enable = true;
    shortcut = "a";    # <Ctrl+a> to start tmux command
    newSession = true; # Spawns when attach would fail
    keyMode = "vi";    # vi > emacs(?)
  };


  # git tracks file changes and history over time
  programs.git = {
    enable = true;
    userName = "Tres Popp";
    userEmail = "git@tpopp.com";
    aliases = {
      cleanup = "!git fetch -p && git branch -vv | aws '/: gone]/{print $1}' | xargs --no-run-if-empty --interactive -n1 git branch -D";
    };
  };

  systemd.user.startServices = "sd-switch";

  home.persistence."/nix/persist/home/tpopp" = {
    allowOther = true;
    directories = [
      "Downloads"
      "nix"
      ".ssh"

      # Coding
      "src"

      # For dotfile/nix management
      ".git"

      # Enlightenment window manager
      ".e"
      ".elementary"
      ".cache/efreet"

      # Google chrome
      ".config/google-chrome"
      ".cache/google-chrome"

      ".config/github-copilot/"

      # Keep ccache around between reboots
      ".ccache"

      # Keep flatpak installed apps around between reboots
      ".cache/flatpak"
      ".local/share/flatpak"
    ];
    files = [
      ".zsh_history"
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    google-chrome # Required because Google sync only works there
    fzf           # fuzzy finder, required by 'zsh-interactive-cd'

    # Filesystem tools
    fd            # `find` alternative
    exa           # `ls` alternative
    tldr          # Simplified `man` with examples
    ouch          # Simplified compress/decompress
    ripgrep       # Fast recursive grep
    bottom        # htop alternative

    # Hardware related tools
    lm_sensors    # To see temperatures

    # The following are packages for development that should just be in
    # development flakes
    python3       # `python` programming language
    git-extras    # Various additional git subcommands
    nil           # lsp for nix expressions
    llvmPackages_15.clang         # compiler
    clangStdenv
    llvmPackages_15.lldb
    llvmPackages_15.lld
    clang-tools
    llvmPackages_15.llvm
    # llvm.clang    # clangd
    # llvm.libcxx   # stdlib
    cmake
    bear
    ninja
    ccache
    python3Packages.numpy
    nixpkgs-fmt
    pyright
    nodejs
    vscode 
    distrobox
  ];

  # Text editor based on original `vi` and better than emacs(?)
  programs.neovim = {
    enable = true;
    defaultEditor = true; # Prefer neovim over nano/etc
    viAlias = true;      # Using vi might be a pureposeful choice
    vimAlias = true;      # nvim can replace vim
    vimdiffAlias = true;  # nvim -d for vimdiff
    withPython3 = true; # for Python 3 plugins
    withNodeJs = true; # for github copilot

    plugins = with pkgs.vimPlugins; [
      vim-nix # Nix highlighting
      nvim-cmp
      cmp-omni
      cmp_luasnip
      luasnip
      nvim-lspconfig
      cmp-nvim-lsp
      # vimspector # debugger
      nvim-treesitter.withAllGrammars
      indentLine # show indentation

      telescope-nvim # Fuzzy Finder
      vim-lua # required by fuzzy finder

      vim-gitgutter

      nvim-autopairs
      easymotion
      vim-commentary
      vim-multiple-cursors
      copilot-lua
      copilot-cmp

      cmp-cmdline
      cmp-path
      cmp-buffer
    ];

    extraConfig = ''
      function! GitStatus()
        let [a,m,r] = GitGutterGetHunkSummary()
        return printf('+%d ~%d -%d', a, m, r)
      endfunction
      set statusline+=%{GitStatus()}
      set foldtext=gitgutter#fold#foldtext()
      let mapleader = ","
      map <silent> <leader><cr> :noh<cr>
      map <leader>cd :cd %:p:h<cr>:pwd<cr>
      vnoremap <silent> * :call VisualSelection('f')<CR>
      vnoremap <silent> # :call VisualSelection('b')<CR>
      set number relativenumber
      set nu rnu

    '';

    extraLuaConfig = ''
      -- telescope-vim setup
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

      -- Set up nvim-cmp.
      local cmp = require'cmp'
      local luasnip = require('luasnip')

      -- nvim-cmp setup
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body) -- For `luasnip` users.
          end,
        },
        window = {
          -- completion = cmp.config.window.bordered(),
          -- documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'copilot' },
        }, {
          { name = 'buffer' },
        })
      })

      -- Set configuration for specific filetype.
      cmp.setup.filetype('gitcommit', {
        sources = cmp.config.sources({
          { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
        }, {
          { name = 'buffer' },
        })
      })

      -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })

      -- Set up lspconfig.
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- cmp-omni setup
      -- require'cmp'.setup {
        -- sources = {
          -- { name = 'omni' }
        -- }
      -- }

      -- nvim-lspconfig
      -- Mappings.
      -- See `:help vim.diagnostic.*` for documentation on any of the below functions
      local opts = { noremap=true, silent=true }
      vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
      vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

      -- Use an on_attach function to only map the following keys
      -- after the language server attaches to the current buffer
      local on_attach = function(client, bufnr)
        -- Enable completion triggered by <c-x><c-o>
        vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

        -- Mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local bufopts = { noremap=true, silent=true, buffer=bufnr }
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
        vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
        vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
        vim.keymap.set('n', '<space>wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, bufopts)
        vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
        vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
        vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
        vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
      end



      -- nvim-treesitter setup
      require'nvim-treesitter.configs'.setup {
        -- A list of parser names, or "all" (the four listed parsers should always be installed)
        -- ensure_installed = { "c", "python", "lua", "vim", "help" },

        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,

        -- Automatically install missing parsers when entering buffer
        -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
        auto_install = false,

        -- List of parsers to ignore installing (for "all")
        ignore_install = { "javascript" },

        ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
        -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

        highlight = {
          enable = true,

          -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
          -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
          -- the name of the parser)
          -- list of language that will be disabled
          disable = { },
          -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
          disable = function(lang, buf)
              local max_filesize = 100 * 1024 -- 100 KB
              local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
              if ok and stats and stats.size > max_filesize then
                  return true
              end
          end,

          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          additional_vim_regex_highlighting = false,
        },
      }


      -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
      require'lspconfig'.clangd.setup {
        capabilities = capabilities,
        on_attach = on_attach,
        flags = lsp_flags,
      }

      require'lspconfig'.pyright.setup{
        capabilities = capabilities,
        on_attach = on_attach,
        flags = lsp_flags,
      }

      require ('lspconfig').nil_ls.setup {
        autostart = true,
        on_attach = on_attach,
        flags = lsp_flags,
        capabilities = capabilities,
        cmd = { 'nil' },
        settings = {
          ['nil'] = {
            formatting = {
              command = { "nixpkgs-fmt" },
            },
          },
        },
      }

    -- nvim-autopairs setup
    require("nvim-autopairs").setup {}
    local handlers = require('nvim-autopairs.completion.handlers')
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      cmp.event:on(
        'confirm_done',
        cmp_autopairs.on_confirm_done()
      )

    require("copilot").setup({
      suggestion = {
        auto_trigger = true,
      },
      panel = {
        auto_refresh = true,
      },
      filetypes = {
        ["."] = true
      },
      suggestion = { enabled = false },
      panel = { enabled = false },
    })

   require("copilot_cmp").setup()
    '';

  };

}
