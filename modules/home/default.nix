{ lib, pkgs, ... }:
{
  imports = [
    ./terminals/tmux.nix
    ./terminals/ghostty.nix
    ./editors/nixvim.nix
    ./editors/micro.nix
    ./editors/nano.nix
    ./cli/bat.nix
    ./cli/btop.nix
    ./cli/bottom.nix
    ./cli/eza.nix
    ./cli/fzf.nix
    ./cli/git.nix
    ./cli/htop.nix
    ./cli/tealdeer.nix
    ./cli/starship.nix
    ./cli/echovault.nix
    ./yazi
    ./overview.nix
    #experimenting with getting dark to work
    # If set here it will break KoolDots theming
    # ./gtk.nix 
  ];

  home.sessionVariables = {
    TERMINAL = "ghostty";
    TERM_PROGRAM = "ghostty";
  };

  xdg.configFile."hypr/kooldots-keyboard.conf".text = ''
    input {
      kb_layout = us,ru
      kb_options = grp:alt_shift_toggle
    }
  '';

  home.activation.kooldotsKeyboard = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    conf="$HOME/.config/hypr/hyprland.conf"
    line="source = $HOME/.config/hypr/kooldots-keyboard.conf"
    if [ -f "$conf" ] && [ ! -L "$conf" ] && ! ${pkgs.gnugrep}/bin/grep -Fxq "$line" "$conf"; then
      printf '\n%s\n' "$line" >> "$conf"
    fi

    system_conf="$HOME/.config/hypr/configs/SystemSettings.conf"
    if [ -f "$system_conf" ]; then
      ${pkgs.gnused}/bin/sed -i 's/kb_layout[[:space:]]*=[[:space:]]*.*/kb_layout = us,ru/' "$system_conf"
      ${pkgs.gnused}/bin/sed -i 's/kb_options[[:space:]]*=[[:space:]]*.*/kb_options = grp:alt_shift_toggle/' "$system_conf"
    fi

    system_lua="$HOME/.config/hypr/configs/system_settings.lua"
    ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/hypr/configs"
    ${pkgs.coreutils}/bin/cat > "$system_lua" <<'EOF'
hl.config({
  input = {
    kb_layout = "us,ru",
    kb_variant = "",
    kb_options = "grp:alt_shift_toggle",
  },
})
EOF

    system_startup_lua="$HOME/.config/hypr/configs/system_startup.lua"
    ${pkgs.coreutils}/bin/cat > "$system_startup_lua" <<'EOF'
local configHome = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
dofile(configHome .. "/hypr/lua/startup.lua")
EOF

    lua="$HOME/.config/hypr/hyprland.lua"
    if [ -f "$lua" ]; then
      ${pkgs.gnused}/bin/sed -i 's/kb_layout[[:space:]]*=[[:space:]]*"[^"]*"/kb_layout  = "us,ru"/' "$lua"
      ${pkgs.gnused}/bin/sed -i 's/kb_options[[:space:]]*=[[:space:]]*"[^"]*"/kb_options = "grp:alt_shift_toggle"/' "$lua"
    fi

    settings_lua="$HOME/.config/hypr/lua/settings.lua"
    if [ -f "$settings_lua" ]; then
      ${pkgs.gnused}/bin/sed -i 's/kb_layout[[:space:]]*=[[:space:]]*"[^"]*"/kb_layout = "us,ru"/' "$settings_lua"
      ${pkgs.gnused}/bin/sed -i 's/kb_options[[:space:]]*=[[:space:]]*"[^"]*"/kb_options = "grp:alt_shift_toggle"/' "$settings_lua"
    fi

    user_keybinds_conf="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
    if [ -f "$user_keybinds_conf" ] && ! ${pkgs.gnugrep}/bin/grep -Fq 'Screenshot selected area' "$user_keybinds_conf"; then
      printf '\n# Screenshot selected area without Print key\nbindd = $mainMod ALT, S, Screenshot selected area, exec, $scriptsDir/ScreenShot.sh --area\n' >> "$user_keybinds_conf"
    fi

    user_keybinds_lua="$HOME/.config/hypr/UserConfigs/user_keybinds.lua"
    if [ -f "$user_keybinds_lua" ] && ! ${pkgs.gnugrep}/bin/grep -Fq 'Screenshot selected area' "$user_keybinds_lua"; then
      printf '\n-- Screenshot selected area without Print key\nbind("SUPER ALT", "S", exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --area"), { description = "Screenshot selected area" })\n' >> "$user_keybinds_lua"
    fi

    weather_dir="$HOME/.config/waybar-weather"
    ${pkgs.coreutils}/bin/mkdir -p "$weather_dir"
    printf 'Rostov-on-Don,Russia\n' > "$weather_dir/cityname.txt"
    printf '47.2357,39.7015\n' > "$weather_dir/geolocation.txt"

    weather_config="$weather_dir/config.toml"
    if [ -f "$weather_config" ]; then
      ${pkgs.gnused}/bin/sed -i \
        -e 's|^[#[:space:]]*units = .*|units = "metric"|' \
        -e 's|^[#[:space:]]*locale = .*|locale = "ru-RU"|' \
        -e 's|^[#[:space:]]*geolocation_file = .*|geolocation_file = "'$HOME'/.config/waybar-weather/geolocation.txt"|' \
        -e 's|^[#[:space:]]*cityname_file = .*|cityname_file = "'$HOME'/.config/waybar-weather/cityname.txt"|' \
        "$weather_config"
    fi

    weather_py="$HOME/.config/hypr/UserScripts/Weather.py"
    if [ -f "$weather_py" ]; then
      ${pkgs.gnused}/bin/sed -i \
        -e 's|^ENV_LAT = os.getenv("WEATHER_LAT".*|ENV_LAT = os.getenv("WEATHER_LAT", "47.2357")|' \
        -e 's|^ENV_LON = os.getenv("WEATHER_LON".*|ENV_LON = os.getenv("WEATHER_LON", "39.7015")|' \
        -e 's|^ENV_PLACE = os.getenv("WEATHER_PLACE".*|ENV_PLACE = os.getenv("WEATHER_PLACE", "Rostov-on-Don, Russia")|' \
        "$weather_py"
    fi

    weather_sh="$HOME/.config/hypr/UserScripts/Weather.sh"
    if [ -f "$weather_sh" ] && ! ${pkgs.gnugrep}/bin/grep -Fq 'Rostov-on-Don' "$weather_sh"; then
      ${pkgs.gnused}/bin/sed -i '/^[[:space:]]*local city[[:space:]]*$/a\\\n    echo "Rostov-on-Don"\n    return 0' "$weather_sh"
    fi

    battery_script="$HOME/.config/hypr/scripts/Battery.sh"
    if [ -f "$battery_script" ]; then
      ${pkgs.gnused}/bin/sed -i '1s|^#!/usr/bin/env bash$|#!${pkgs.bash}/bin/bash|' "$battery_script"
    fi

    user_animations_lua="$HOME/.config/hypr/UserConfigs/user_animations.lua"
    if [ -f "$user_animations_lua" ]; then
      ${pkgs.gnused}/bin/sed -i 's/leaf = "borderangle", enabled = true, speed = 180/leaf = "borderangle", enabled = true, speed = 100/' "$user_animations_lua"
    fi

    user_defaults_conf="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"
    if [ -f "$user_defaults_conf" ]; then
      ${pkgs.gnused}/bin/sed -i 's|^\$term[[:space:]]*=.*|$term = ghostty # Terminal|' "$user_defaults_conf"
    fi

    lua_defaults="$HOME/.config/hypr/lua/user_defaults.lua"
    if [ -f "$lua_defaults" ]; then
      ${pkgs.gnused}/bin/sed -i 's|KOOLDOTS_DEFAULTS\.term = "kitty"|KOOLDOTS_DEFAULTS.term = "ghostty"|' "$lua_defaults"
    fi

    user_lua_defaults="$HOME/.config/hypr/UserConfigs/user_defaults.lua"
    if [ -f "$user_lua_defaults" ] && ! ${pkgs.gnugrep}/bin/grep -Fq 'KOOLDOTS_DEFAULTS.term = "ghostty"' "$user_lua_defaults"; then
      printf '\nKOOLDOTS_DEFAULTS.term = "ghostty"\n' >> "$user_lua_defaults"
    fi

    rofi_terminal="$HOME/.config/rofi/00-terminal.rasi"
    if [ -f "$rofi_terminal" ]; then
      ${pkgs.gnused}/bin/sed -i 's|terminal:[[:space:]]*"[^"]*"|terminal: "ghostty"|' "$rofi_terminal"
    fi

    ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/xfce4"
    printf 'TerminalEmulator=ghostty\n' > "$HOME/.config/xfce4/helpers.rc"
  '';
}
