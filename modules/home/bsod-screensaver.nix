{
  lib,
  pkgs,
  ...
}: let
  bsodImage = ../../assets/bsod-windows10-1920x1080.png;
  bsodScreensaver = pkgs.writeShellApplication {
    name = "bsod-screensaver";
    runtimeInputs = [
      pkgs.hyprlock
      pkgs.procps
    ];
    text = ''
      config="''${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock-bsod.conf"

      if pgrep -u "$UID" -x hyprlock >/dev/null 2>&1; then
        exit 0
      fi

      exec hyprlock --quiet --no-fade-in --immediate-render --config "$config"
    '';
  };
in {
  home.packages = [
    bsodScreensaver
  ];

  xdg.configFile."hypr/hyprlock-bsod.conf".text = ''
    general {
        disable_loading_bar = true
        hide_cursor = true
        no_fade_in = true
        immediate_render = true
    }

    background {
        monitor =
        path = ${bsodImage}
        color = rgb(0078d7)
        blur_size = 0
        blur_passes = 0
        noise = 0
        contrast = 1
        brightness = 1
        vibrancy = 0
        vibrancy_darkness = 0
    }

    input-field {
        monitor =
        size = 1, 1
        outline_thickness = 0
        dots_size = 0
        dots_spacing = 0
        dots_center = true
        outer_color = rgba(00000000)
        inner_color = rgba(00000000)
        font_color = rgba(00000000)
        placeholder_text =
        hide_input = true
        fade_on_empty = false
        position = -10000, -10000
        halign = left
        valign = top
    }
  '';

  home.activation.bsodScreensaver = lib.hm.dag.entryAfter ["writeBoundary"] ''
        hypridle_conf="$HOME/.config/hypr/hypridle.conf"
        ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/hypr"

        if [ -f "$hypridle_conf" ]; then
          ${pkgs.gnused}/bin/sed -i \
            's|^[[:space:]]*lock_cmd = .*|    lock_cmd = ${bsodScreensaver}/bin/bsod-screensaver|' \
            "$hypridle_conf"
        else
          ${pkgs.coreutils}/bin/cat > "$hypridle_conf" <<'EOF'
    general {
        lock_cmd = ${bsodScreensaver}/bin/bsod-screensaver
        before_sleep_cmd = loginctl lock-session
        after_sleep_cmd = hyprctl dispatch dpms on
        ignore_dbus_inhibit = false
    }

    listener {
        timeout = 540
        on-timeout = notify-send "You are idle!"
    }

    listener {
        timeout = 600
        on-timeout = loginctl lock-session
    }

    listener {
        timeout = 720
        on-timeout = hyprctl dispatch dpms off
        on-resume = hyprctl dispatch dpms on
    }
    EOF
        fi

    user_keybinds_conf="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
    if [ -f "$user_keybinds_conf" ]; then
      ${pkgs.gnused}/bin/sed -i \
        's|^bindd = \$mainMod CTRL, [^,]*, BSOD screensaver, exec, .*|bindd = $mainMod CTRL, L, BSOD screensaver, exec, ${bsodScreensaver}/bin/bsod-screensaver|' \
        "$user_keybinds_conf"
      if ! ${pkgs.gnugrep}/bin/grep -Fq 'bindd = $mainMod CTRL, L, BSOD screensaver' "$user_keybinds_conf"; then
        printf '\n# BSOD screensaver\nbindd = $mainMod CTRL, L, BSOD screensaver, exec, ${bsodScreensaver}/bin/bsod-screensaver\n' >> "$user_keybinds_conf"
      fi
    fi

    user_keybinds_lua="$HOME/.config/hypr/UserConfigs/user_keybinds.lua"
    if [ -f "$user_keybinds_lua" ]; then
      ${pkgs.gnused}/bin/sed -i \
        's|^bind("SUPER CTRL", "[^"]*", exec_cmd(".*/bin/bsod-screensaver"), { description = "BSOD screensaver" })|bind("SUPER CTRL", "L", exec_cmd("${bsodScreensaver}/bin/bsod-screensaver"), { description = "BSOD screensaver" })|' \
        "$user_keybinds_lua"
      if ! ${pkgs.gnugrep}/bin/grep -Fq 'bind("SUPER CTRL", "L", exec_cmd' "$user_keybinds_lua"; then
        printf '\n-- BSOD screensaver\nbind("SUPER CTRL", "L", exec_cmd("${bsodScreensaver}/bin/bsod-screensaver"), { description = "BSOD screensaver" })\n' >> "$user_keybinds_lua"
      fi
    fi
  '';
}
