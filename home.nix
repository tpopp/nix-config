{ config, pkgs, lib, inputs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "tpopp";
  home.homeDirectory = "/home/tpopp";

  home.stateVersion = "22.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # zsh as bash replacement
  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "aliases"
        "branch"
        "copyfile"
        "docker"
        "docker-compose"
        "gitfast"
        "git-extras"
        "gh"
        "jump"
        "ssh-agent"
        "safe-paste"
        "tmux"
        "vi-mode"
        "zsh-interactive-cd"
        "zsh-navigation-tools"
      ];
    };

    sessionVariables = {
      ZSH_TMUX_AUTOSTART = "true";
      ZSH_TMUX_AUTOCONNECT = "true";
    };
  };

  # tmux configuration
  programs.tmux = {
    enable = true;
    shortcut = "a";
    newSession = true;
    keyMode = "vi";
  };

  # git configuration
  programs.git = {
    enable = true;
    settings.user = {
      name = "Tres Popp";
      email = "git@tpopp.com";
    };
    settings.alias = {
      cleanup = "!git fetch -p && git branch -vv | aws '/: gone]/{print $1}' | xargs --no-run-if-empty --interactive -n1 git branch -D";
    };
  };

  systemd.user.startServices = "sd-switch";

  home.persistence."/nix/persist" = {
    hideMounts = true;
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

      # Google chrome / Chromium
      ".config/github-copilot/"

      # Keep ccache around between reboots
      ".ccache"
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
    chromium
    fzf

    # Filesystem tools
    fd
    eza
    tldr
    ouch
    ripgrep
    bottom

    # Hardware related tools
    lm_sensors

    # Development tools
    python3
    git-extras
    nil
    clang
    clangStdenv
    lldb
    lld
    clang-tools
    llvm
    cmake
    bear
    ninja
    ccache
    nixpkgs-fmt
    pyright
    nodejs
    distrobox
  ];

  # Text editor configuration (Neovim)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withPython3 = true;
    withNodeJs = true;
    withRuby = false;

    plugins = with pkgs.vimPlugins; [
      vim-nix
      nvim-cmp
      cmp-omni
      cmp_luasnip
      luasnip
      nvim-lspconfig
      cmp-nvim-lsp
      nvim-treesitter.withAllGrammars
      indentLine

      telescope-nvim
      vim-lua

      vim-gitgutter

      nvim-autopairs
      vim-easymotion
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

    initLua = ''
      -- telescope-vim setup
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

      -- Set up nvim-cmp.
      local cmp = require'cmp'
      local luasnip = require('luasnip')

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'copilot' },
        }, {
          { name = 'buffer' },
        })
      })

      cmp.setup.filetype('gitcommit', {
        sources = cmp.config.sources({
          { name = 'cmp_git' },
        }, {
          { name = 'buffer' },
        })
      })

      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })

      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })

      local capabilities = require('cmp_nvim_lsp').defaultCapabilities()

      local opts = { noremap=true, silent=true }
      vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
      vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

      local on_attach = function(client, bufnr)
        vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

        local bufopts = { noremap=true, silent=true, buffer=bufnr }
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
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

      require'nvim-treesitter.configs'.setup {
        sync_install = false,
        auto_install = false,
        ignore_install = { "javascript" },
        highlight = {
          enable = true,
          disable = function(lang, buf)
              local max_filesize = 100 * 1024
              local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
              if ok and stats and stats.size > max_filesize then
                  return true
              end
          end,
          additional_vim_regex_highlighting = false,
        },
      }

      require'lspconfig'.clangd.setup {
        capabilities = capabilities,
        on_attach = on_attach,
      }

      require'lspconfig'.pyright.setup{
        capabilities = capabilities,
        on_attach = on_attach,
      }

      require('lspconfig').nil_ls.setup {
        autostart = true,
        on_attach = on_attach,
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

      require("nvim-autopairs").setup {}
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      cmp.event:on(
        'confirm_done',
        cmp_autopairs.on_confirm_done()
      )

      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
        filetypes = {
          ["."] = true
        },
      })

      require("copilot_cmp").setup()
    '';
  };
}
