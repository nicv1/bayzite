#!/usr/bin/bash
# KDE Plasma edition: WhiteSur Plasma theme, menu bar + dock layout, Kvantum.
# Usage: setup-kde.sh <work-dir>
set -euxo pipefail

WORK="$1"
BG=/usr/share/backgrounds/bayzite
LNF=/usr/share/plasma/look-and-feel
MINE="${LNF}/org.bayzite.desktop"

# Kvantum gives Qt apps the translucent macOS-style widgets.
dnf5 -y install kvantum

# --- WhiteSur for Plasma (installs to /usr/share when run as root) --------------
( cd "${WORK}/kde" && bash ./install.sh )
test -d "${LNF}/com.github.vinceliuice.WhiteSur-dark"
test -d /usr/share/aurorae/themes/WhiteSur-dark
test -d /usr/share/plasma/desktoptheme/WhiteSur-dark
test -f /usr/share/Kvantum/WhiteSur/WhiteSurDark.kvconfig

# Strip Apple artwork that ships with the theme; Bayzite uses its own.
rm -rf /usr/share/wallpapers/WhiteSur /usr/share/wallpapers/WhiteSur-dark /usr/share/wallpapers/WhiteSur-light
rm -f /usr/share/plasma/desktoptheme/WhiteSur*/icons/start.svg
for pkg in "${LNF}"/com.github.vinceliuice.WhiteSur*; do
  [[ -d "${pkg}/contents/splash/images" ]] || continue
  cp -f /usr/share/icons/hicolor/scalable/apps/bayzite-logo.svg "${pkg}/contents/splash/images/logo.svg"
  cp -f "${BG}/bayzite-dusk-blur.png" "${pkg}/contents/splash/images/background.png"
done

# --- Bayzite global theme = WhiteSur-dark + our layout/defaults/branding ---------
# Our own files (metadata, defaults, layout, logo) were copied from system_files
# already; fill in the rest (logout screen, splash) without overwriting them.
cp -rn "${LNF}/com.github.vinceliuice.WhiteSur-dark/contents/." "${MINE}/contents/"
mkdir -p "${MINE}/contents/previews"
python3 - "${BG}" "${MINE}/contents" <<'PY' || cp -f "${BG}/bayzite-dusk-blur.png" "${MINE}/contents/previews/preview.png"
import sys
from PIL import Image
bg, out = sys.argv[1], sys.argv[2]
im = Image.open(f"{bg}/bayzite-dusk.jpg").convert("RGB")
im.resize((1920, 1080)).save(f"{out}/previews/fullscreenpreview.jpg", quality=88)
im.resize((600, 338)).save(f"{out}/previews/preview.png")
im.resize((600, 338)).save(f"{out}/previews/splash.png")
im.resize((1920, 1080)).save(f"{out}/splash/images/background.png")
PY
test -f "${MINE}/contents/layouts/org.kde.plasma.desktop-layout.js"
test -f "${MINE}/contents/splash/Splash.qml"

# --- Wallpaper package that switches with light/dark mode ------------------------
WP=/usr/share/wallpapers/Bayzite/contents
mkdir -p "${WP}/images" "${WP}/images_dark"
ln -sf "${BG}/bayzite-dawn.jpg" "${WP}/images/3840x2160.jpg"
ln -sf "${BG}/bayzite-dusk.jpg" "${WP}/images_dark/3840x2160.jpg"
ln -sf "${BG}/bayzite-dusk.jpg" "${WP}/screenshot.jpg"

# --- Make Bayzite the default for every new user --------------------------------
# /etc/xdg/kdeglobals (from system_files) already sets it; Fedora also keeps
# defaults in a kde-profile folder, so set it there too in case that wins.
KDEPROFILE=/usr/share/kde-settings/kde-profile/default/xdg
if [[ -d "${KDEPROFILE}" ]] && command -v kwriteconfig6 >/dev/null; then
  kwriteconfig6 --file "${KDEPROFILE}/kdeglobals" --group KDE --key LookAndFeelPackage org.bayzite.desktop
fi

# --- Login screen wallpaper (Plasma Login Manager or SDDM) -----------------------
if [[ -f /usr/lib/plasmalogin/defaults.conf ]]; then
  sed -i "s|^Image=.*|Image=file://${BG}/bayzite-dusk.jpg|; s|^PreviewImage=.*|PreviewImage=file://${BG}/bayzite-dusk.jpg|" \
    /usr/lib/plasmalogin/defaults.conf
fi
if [[ -f /usr/share/sddm/themes/breeze/theme.conf ]]; then
  printf '[General]\nbackground=%s/bayzite-dusk.jpg\n' "${BG}" > /usr/share/sddm/themes/breeze/theme.conf.user
fi
