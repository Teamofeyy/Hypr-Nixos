{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wl-clipboard
  ];

  programs.tmux = {
    enable = true;

    baseIndex = 1;
    mouse = true;
    prefix = "C-a";
    escapeTime = 0;
    keyMode = "vi";

    # If your Home Manager version supports this:
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      tmux-which-key
      {
        plugin = gruvbox;
        extraConfig = ''
          set -g @tmux-gruvbox 'dark'
          set -g @tmux-gruvbox-statusbar-alpha 'true'
        '';
      }
    ];

    extraConfig = ''
      # Unbind defaults
      unbind r
      unbind x
      unbind '%'
      unbind '"'
      unbind '-'

      # Correct terminal setup
      set -g default-terminal "tmux-256color"

      # Truecolor support.
      # Newer tmux prefers terminal-features; Tc/RGB are direct-color capabilities.
      set -as terminal-features ",*:RGB"
      set -as terminal-overrides ",*:Tc"

      # Let tmux interact with the terminal clipboard when possible
      set -g set-clipboard on
      set -g copy-command "wl-copy"

      set-option -g xterm-keys on
      set-option -g status-position top
      setw -g pane-base-index 1

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux config reloaded"

      # Window/Session navigation
      bind -n C-Tab select-window -n
      bind-key S new-session
      bind K confirm kill-session
      bind-key 'n' new-window -c "#{pane_current_path}"

      # Splits
      bind-key '-' split-window -v -c "#{pane_current_path}"
      bind-key '|' split-window -h -c "#{pane_current_path}"

      # Pane navigation
      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R

      # Alt/Meta pane navigation
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R

      # Kill pane
      bind-key q kill-pane
      bind-key Q kill-pane

      # Copy mode navigation
      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R

      # Copy selected text to Wayland clipboard
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"
      bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "wl-copy"
    '';
  };
}