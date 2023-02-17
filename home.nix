
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

  # Text editor based on original `vi` and better than emacs(?)
  programs.neovim = {
    enable = true;
    defaultEditor = true; # Prefer neovim over nano/etc
    viAlias = false;      # Using vi might be a pureposeful choice
    vimAlias = true;      # nvim can replace vim
    vimdiffAlias = true;  # nvim -d for vimdiff
    # withPython3 = true; # for Python 3 plugins
    coc.enable = true;    # Coc code completion

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
  ];
}
