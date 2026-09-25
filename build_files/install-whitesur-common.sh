#!/usr/bin/bash
# Installs the macOS-style WhiteSur GTK theme, icons and cursors system-wide.
# Usage: install-whitesur-common.sh <work-dir>
set -euxo pipefail

WORK="$1"
BG=/usr/share/backgrounds/bayzite

# The GNOME Shell part of WhiteSur ships its own login-screen backgrounds.
# Swap in Bayzite's original (blurred) wallpaper before building anything.
for f in "${WORK}"/gtk/src/assets/gnome-shell/backgrounds/background-*.png; do
  cp -f "${BG}/bayzite-dusk-blur.png" "$f"
done

# --- GTK 2/3/4 + GNOME Shell theme -> /usr/share/themes -----------------------
#   -o normal     translucent (not "solid") variant
#   -N stable     Finder-like Nautilus sidebar
#   --round       rounded corners on maximised windows, like macOS
#   --shell -i simple   neutral top-left icon (no Apple logo)
( cd "${WORK}/gtk" && ./install.sh --silent-mode \
    -d /usr/share/themes -o normal -N stable --round --shell -i simple )
test -f /usr/share/themes/WhiteSur-Dark/gtk-3.0/gtk.css
test -f /usr/share/themes/WhiteSur-Light/gtk-3.0/gtk.css

# --- Icons -> /usr/share/icons ------------------------------------------------
#   -p  replaces the Apple logo in the icon theme with a neutral one
( cd "${WORK}/icons" && ./install.sh -d /usr/share/icons -p )
test -f /usr/share/icons/WhiteSur-dark/index.theme

# --- Cursors -> /usr/share/icons/WhiteSur-cursors ------------------------------
( cd "${WORK}/cursors" && ./install.sh )
test -f /usr/share/icons/WhiteSur-cursors/index.theme

# System-wide default cursor for apps/toolkits that read the "default" theme
mkdir -p /usr/share/icons/default
cat > /usr/share/icons/default/index.theme <<'EOF'
[Icon Theme]
Name=Default
Comment=Default cursor theme (Bayzite)
Inherits=WhiteSur-cursors
EOF
