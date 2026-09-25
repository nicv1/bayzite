#!/usr/bin/bash
# Bayzite image build — runs once inside the container build.
# Everything here is baked into the OS image (and therefore the ISO),
# so a fresh install boots straight into the Mac-style desktop.
set -euxo pipefail

CTX=/ctx
# shellcheck source=build_files/versions.env
source "${CTX}/versions.env"

# ---------------------------------------------------------------------------
# Which desktop is this image? (GNOME = Bazzite "silverblue", KDE = "kinoite")
# ---------------------------------------------------------------------------
DESKTOP="${DESKTOP:-auto}"
if [[ "${DESKTOP}" == "auto" ]]; then
  if [[ -x /usr/bin/gnome-shell ]]; then DESKTOP=gnome; else DESKTOP=kde; fi
fi
if [[ "${DESKTOP}" == "gnome" && ! -x /usr/bin/gnome-shell ]]; then
  echo "ERROR: DESKTOP=gnome but this base image has no gnome-shell" >&2; exit 1
fi
if [[ "${DESKTOP}" == "kde" && ! -x /usr/bin/plasmashell ]]; then
  echo "ERROR: DESKTOP=kde but this base image has no plasmashell" >&2; exit 1
fi
echo "Building Bayzite for desktop: ${DESKTOP}"

# The WhiteSur installers expect a normal login environment.
export HOME=/root USER=root SUDO_USER=root
mkdir -p "$(readlink -f /root)"
WORK=/tmp/bayzite-build
mkdir -p "${WORK}"

# ---------------------------------------------------------------------------
# Files shipped in this repo
# ---------------------------------------------------------------------------
cp -a "${CTX}/system_files/shared/." /
cp -a "${CTX}/system_files/${DESKTOP}/." /
# (file permissions can get lost when the repo is uploaded through a browser)
chmod 0755 /usr/libexec/bayzite-flatpak-theme
chmod -R u=rwX,go=rX /usr/share/backgrounds/bayzite /usr/share/bayzite /etc/skel/.config 2>/dev/null || true
systemctl enable bayzite-flatpak-theme.service

# ---------------------------------------------------------------------------
# Packages
# ---------------------------------------------------------------------------
# Fonts: Inter is the closest open font to Apple's San Francisco.
dnf5 -y install --skip-unavailable \
  rsms-inter-fonts \
  jetbrains-mono-fonts-all

# Build-only tools for compiling the themes (removed again at the end,
# unless the base image already had them).
BUILD_DEPS=()
for p in sassc glib2-devel; do
  rpm -q "$p" >/dev/null 2>&1 || BUILD_DEPS+=("$p")
done
if (( ${#BUILD_DEPS[@]} )); then dnf5 -y install "${BUILD_DEPS[@]}"; fi

# ---------------------------------------------------------------------------
# Fetch the pinned WhiteSur theme sources from GitHub
# ---------------------------------------------------------------------------
fetch() { # fetch <repo> <ref> <dest>
  local repo="$1" ref="$2" dest="$3"
  mkdir -p "${dest}"
  if ! curl -fsSL --retry 5 --retry-delay 5 \
      "https://github.com/vinceliuice/${repo}/archive/${ref}.tar.gz" \
      | tar -xz -C "${dest}" --strip-components=1; then
    echo "Tarball download failed for ${repo}; trying git instead"
    rm -rf "${dest}" && mkdir -p "${dest}"
    git -C "${dest}" init -q
    git -C "${dest}" fetch -q --depth 1 "https://github.com/vinceliuice/${repo}.git" "${ref}"
    git -C "${dest}" checkout -q FETCH_HEAD
  fi
  test -f "${dest}/install.sh"
}
fetch WhiteSur-gtk-theme  "${WHITESUR_GTK_REF}"     "${WORK}/gtk"
fetch WhiteSur-icon-theme "${WHITESUR_ICONS_REF}"   "${WORK}/icons"
fetch WhiteSur-cursors    "${WHITESUR_CURSORS_REF}" "${WORK}/cursors"

# ---------------------------------------------------------------------------
# Shared theming (both desktops)
# ---------------------------------------------------------------------------
bash "${CTX}/install-whitesur-common.sh" "${WORK}"

# ---------------------------------------------------------------------------
# Desktop-specific setup
# ---------------------------------------------------------------------------
if [[ "${DESKTOP}" == "gnome" ]]; then
  bash "${CTX}/setup-gnome.sh" "${WORK}"
else
  fetch WhiteSur-kde "${WHITESUR_KDE_REF}" "${WORK}/kde"
  bash "${CTX}/setup-kde.sh" "${WORK}"
fi

# ---------------------------------------------------------------------------
# Branding (keeps Bazzite's internal IDs so its update tools keep working)
# ---------------------------------------------------------------------------
sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Bayzite"/' /usr/lib/os-release
sed -i 's/^LOGO=.*/LOGO=bayzite-logo/' /usr/lib/os-release
grep -q '^LOGO=' /usr/lib/os-release || echo 'LOGO=bayzite-logo' >> /usr/lib/os-release

# ---------------------------------------------------------------------------
# Refresh caches and clean up
# ---------------------------------------------------------------------------
for d in /usr/share/icons/*/; do
  [[ -f "${d}index.theme" ]] && gtk-update-icon-cache -f -q "${d}" || true
done
fc-cache -f || true
if command -v dconf >/dev/null; then dconf update; fi
glib-compile-schemas /usr/share/glib-2.0/schemas

if (( ${#BUILD_DEPS[@]} )); then dnf5 -y remove "${BUILD_DEPS[@]}" || true; fi
dnf5 clean all
rm -rf "${WORK}" /root/.local /root/.config /root/.cache /root/.themes /root/.icons

# Keep the ISO builder from tripping over repos that Bazzite switched off.
bash "${CTX}/fix-repos.sh"

echo "Bayzite ${DESKTOP} build finished."
