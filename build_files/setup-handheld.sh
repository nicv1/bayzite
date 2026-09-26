#!/usr/bin/bash
# Handheld editions (built on Bazzite's deck images, e.g. for the ROG Ally).
# Usage: setup-handheld.sh <gnome|kde> [base kwin InputMethod]
set -euxo pipefail

DESKTOP="$1"
BASE_IM="${2:-}"

# --- Boot straight into the Mac-style desktop --------------------------------
# Bazzite's auto-login picks the desktop session when this file exists;
# Steam Game Mode stays one tap away ("Return to Gaming Mode" / logo menu).
mkdir -p /etc/bazzite
touch /etc/bazzite/desktop_autologin

# --- Pop-up on-screen keyboard -------------------------------------------------
if [[ "${DESKTOP}" == "kde" ]]; then
  KB=""
  for f in "${BASE_IM}" \
           /usr/share/applications/org.kde.plasma.keyboard.desktop \
           /usr/share/applications/com.github.maliit.keyboard.desktop; do
    if [[ -n "$f" && -f "$f" ]]; then KB="$f"; break; fi
  done
  if [[ -z "${KB}" ]]; then
    dnf5 -y install --skip-unavailable plasma-keyboard
    [[ -f /usr/share/applications/org.kde.plasma.keyboard.desktop ]] \
      && KB=/usr/share/applications/org.kde.plasma.keyboard.desktop
  fi
  if [[ -z "${KB}" ]]; then
    dnf5 -y install maliit-keyboard
    KB=/usr/share/applications/com.github.maliit.keyboard.desktop
  fi
  test -f "${KB}"
  kwriteconfig6 --file /etc/xdg/kwinrc --group Wayland --key InputMethod "${KB}"
  kwriteconfig6 --file /etc/xdg/kwinrc --group Wayland --key VirtualKeyboardEnabled true
  echo "Plasma on-screen keyboard: ${KB}"
  cat /etc/xdg/kwinrc
else
  # GNOME's built-in keyboard: show it for every text field, not only after a
  # touch (the Ally's controller acts as a mouse on the desktop).
  mkdir -p /etc/dconf/db/distro.d
  cat > /etc/dconf/db/distro.d/60-bayzite-handheld <<'CONF'
[org/gnome/desktop/a11y/applications]
screen-keyboard-enabled=true

[org/gnome/shell/extensions/Logo-menu]
show-gamemode=true
CONF
fi
