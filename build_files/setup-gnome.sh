#!/usr/bin/bash
# GNOME edition: dock, top bar tweaks, libadwaita styling and login screen.
# Usage: setup-gnome.sh <work-dir>
set -euxo pipefail

WORK="$1"
EXT=/usr/share/gnome-shell/extensions

# --- Extensions not already in Bazzite ------------------------------------------
#   Dash to Dock    -> the macOS dock
#   Just Perfection -> clock on the right, boot to desktop, hide "Activities"
dnf5 -y install \
  gnome-shell-extension-dash-to-dock \
  gnome-shell-extension-just-perfection

for uuid in dash-to-dock@micxgx.gmail.com just-perfection-desktop@just-perfection \
            logomenu@aryan_k blur-my-shell@aunetx user-theme@gnome-shell-extensions.gcampax.github.com; do
  if [[ ! -f "${EXT}/${uuid}/metadata.json" ]]; then
    echo "ERROR: required GNOME extension ${uuid} is missing" >&2
    exit 1
  fi
done

# Some Fedora extension packages keep their schema inside the extension folder;
# make sure every one of them is compiled.
for d in "${EXT}"/*/schemas; do
  compgen -G "${d}/*.gschema.xml" >/dev/null && glib-compile-schemas "${d}" || true
done

# --- Libadwaita (GTK4 apps) get the WhiteSur look for every new user -------------
# The WhiteSur installer refuses to do this as root, so run it as 'nobody'.
LIBADW_HOME="${WORK}/libadw-home"
rm -rf "${WORK}/gtk-user"
cp -a "${WORK}/gtk" "${WORK}/gtk-user"
mkdir -p "${LIBADW_HOME}"
chown -R 65534:65534 "${WORK}/gtk-user" "${LIBADW_HOME}"
( cd "${WORK}/gtk-user" && setpriv --reuid=65534 --regid=65534 --clear-groups \
    env HOME="${LIBADW_HOME}" USER=nobody SUDO_USER=nobody PATH="${PATH}" \
    ./install.sh -l -c dark -o normal </dev/null )

SKEL_GTK4=/etc/skel/.config/gtk-4.0
mkdir -p "${SKEL_GTK4}"
cp -r "${LIBADW_HOME}/.config/gtk-4.0/"{gtk-Dark.css,gtk-Light.css,assets,windows-assets} "${SKEL_GTK4}/"
ln -sf gtk-Dark.css "${SKEL_GTK4}/gtk.css"
ln -sf gtk-Dark.css "${SKEL_GTK4}/gtk-dark.css"
chown -R root:root /etc/skel/.config
test -s "${SKEL_GTK4}/gtk-Dark.css"

# --- Login screen (GDM) --------------------------------------------------------------
# WhiteSur rebuilds GNOME Shell's default theme resource so the login screen
# matches. Bazzite may use GDM or SDDM for GNOME; only do this when GDM is present,
# and roll back automatically if the result doesn't look right.
GR=/usr/share/gnome-shell/gnome-shell-theme.gresource
if [[ -f "${GR}" ]] && { command -v gdm >/dev/null || [[ -x /usr/sbin/gdm ]]; }; then
  cp -a "${GR}" "${WORK}/gresource.orig"
  if ( cd "${WORK}/gtk" && ./tweaks.sh --silent-mode -g -i simple ) \
     && gresource list "${GR}" | grep -q '/org/gnome/shell/theme/gnome-shell-dark.css'; then
    echo "GDM theme applied"
  else
    echo "WARNING: GDM theming failed; restoring the stock login screen" >&2
    cp -af "${WORK}/gresource.orig" "${GR}"
  fi
  rm -f "${GR}.bak"
fi

# Our defaults live in the "distro" dconf database (same place Bazzite uses);
# make sure the user profile reads it.
mkdir -p /etc/dconf/profile
if [[ ! -f /etc/dconf/profile/user ]]; then
  printf 'user-db:user\nsystem-db:local\nsystem-db:site\nsystem-db:distro\n' > /etc/dconf/profile/user
elif ! grep -q '^system-db:distro' /etc/dconf/profile/user; then
  echo 'system-db:distro' >> /etc/dconf/profile/user
fi

# GDM uses its own dconf profile; make sure it reads our gdm.d settings.
if [[ ! -f /etc/dconf/profile/gdm ]]; then
  mkdir -p /etc/dconf/profile
  printf 'user-db:user\nsystem-db:gdm\nfile-db:/usr/share/gdm/greeter-dconf-defaults\n' > /etc/dconf/profile/gdm
fi

