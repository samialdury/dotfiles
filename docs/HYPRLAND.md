# Hyprland Notes

Personal Hyprland input and touchpad snippet. This repo does not currently link a Hyprland config; keep this as reference material for Omarchy/Hyprland machines.

```conf
# Control your input devices
# See https://wiki.hypr.land/Configuring/Variables/#input
input {
  # Use multiple keyboard layouts and switch between them with Left Alt + Right Alt
  kb_layout = cz # us,dk,eu
  kb_variant = qwerty
  kb_options = caps:escape # ,compose:caps,grp:alts_toggle

  # Change speed of keyboard repeat
  repeat_rate = 40
  repeat_delay = 300

  # Start with numlock on by default
  numlock_by_default = true

  # Increase sensitivity for mouse/trackpad (default: 0)
  # sensitivity = 0.35

  touchpad {
    # Use natural (inverse) scrolling
    natural_scroll = true

    # Use two-finger clicks for right-click instead of lower-right corner
    clickfinger_behavior = true

    # Control the speed of your scrolling
    scroll_factor = 0.4
  }
}

# Scroll nicely in the terminal
windowrule = scrolltouchpad 1.5, class:(Alacritty|kitty)
windowrule = scrolltouchpad 0.2, class:com.mitchellh.ghostty

# Enable touchpad gestures for changing workspaces
# See https://wiki.hyprland.org/Configuring/Gestures/
# gesture = 3, horizontal, workspace
```
