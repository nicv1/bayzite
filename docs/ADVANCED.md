# Bayzite: advanced notes

## Already running Bazzite? Switch without reinstalling
Open a terminal and run (replace `YOURNAME` and pick your edition):

```bash
sudo bootc switch ghcr.io/YOURNAME/bayzite-gnome:latest
systemctl reboot
```

Existing accounts keep their own settings, so run these once to adopt the Bayzite look:

```bash
# GNOME: drop your per-user overrides so the new defaults apply
dconf reset -f /org/gnome/
mkdir -p ~/.config/gtk-4.0 && cp -r /etc/skel/.config/gtk-4.0/. ~/.config/gtk-4.0/

# KDE: apply the global theme, including its layout
plasma-apply-lookandfeel --apply org.bayzite.desktop --resetLayout
```

To go back: `sudo bootc switch ghcr.io/ublue-os/bazzite-gnome:stable` (or your old image).

## Older NVIDIA cards
The NVIDIA editions use Bazzite's `-nvidia-open` drivers, which need a GTX 16-series or
newer card. For GTX 900/1000 cards, edit `.github/workflows/build.yml` and change
`bazzite-gnome-nvidia-open` → `bazzite-gnome-nvidia` and `bazzite-nvidia-open` →
`bazzite-nvidia`, then commit.

## Change the dock apps
- **GNOME:** `system_files/gnome/etc/dconf/db/distro.d/50-bayzite-mac` → `favorite-apps=[...]`
  (use the app's `.desktop` file name, e.g. `org.gnome.Calculator.desktop`).
- **KDE:** `system_files/kde/usr/share/plasma/look-and-feel/org.bayzite.desktop/contents/layouts/org.kde.plasma.desktop-layout.js` → the `launchers` list.

## Light mode by default
- **GNOME:** in `50-bayzite-mac` set `color-scheme='default'`, `gtk-theme='WhiteSur-Light'`,
  `icon-theme='WhiteSur-light'`, and `name='WhiteSur-Light'` under `user-theme`.
- **KDE:** in `org.bayzite.desktop/contents/defaults` use `WhiteSur` (colour scheme), `WhiteSur`
  (plasma theme), `WhiteSur` (icons), `__aurorae__svg__WhiteSur` and `widgetStyle=kvantum`.

## New wallpapers
Replace the files in `system_files/shared/usr/share/backgrounds/bayzite/` (keep the names), or
tweak the colours in `tools/make_wallpapers.py` and run `python3 tools/make_wallpapers.py`.

## Rename the distro
Search-and-replace `bayzite` in `.github/workflows/*.yml` (image names) and `Bayzite` in
`build_files/build.sh` (`PRETTY_NAME`). Existing installs follow the old image name until you
`bootc switch` them.

## Newer theme versions
Theme sources are pinned in `build_files/versions.env`. Put a newer commit SHA from the
[WhiteSur repositories](https://github.com/vinceliuice) there and commit.

## Sign your images (optional)
Signing lets installed systems verify updates came from you.
1. Install [cosign](https://docs.sigstore.dev/cosign/system_config/installation/) and run
   `COSIGN_PASSWORD="" cosign generate-key-pair` inside the repo folder.
2. Repository **Settings → Secrets and variables → Actions → New repository secret**:
   name `SIGNING_SECRET`, value = contents of `cosign.key`. **Never commit `cosign.key`.**
3. Commit `cosign.pub`. The build signs images automatically once the secret exists.

## Build locally (Linux with podman)
```bash
podman build --build-arg BASE_IMAGE=ghcr.io/ublue-os/bazzite-gnome:stable \
             --build-arg DESKTOP=gnome -t bayzite-gnome:latest .
```

## Try an ISO in a virtual machine first
Use virt-manager/GNOME Boxes (Linux) or VirtualBox/VMware (Windows). Give it **UEFI**
firmware, 4+ CPU cores, 8 GB RAM, a 64 GB disk, and turn on 3D acceleration if offered.

## Troubleshooting
| Problem | Fix |
|---|---|
| A build job is red | Open it, read the last lines. Network hiccups happen: click **Re-run failed jobs**. |
| "No space left on device" in a build | Re-run; GitHub runners vary. If it keeps happening, build fewer editions at once (run the ISO workflow per edition). |
| ISO workflow never started | It only runs after a successful image build from a push/manual run. Start it by hand: **Actions → Build Bayzite ISOs → Run workflow**. |
| ISO build says it can't pull the image | Make the `bayzite-…` packages public (README step 5) and run again. |
| Installed PC doesn't update | Packages must be public. Check with `bootc status`. |
| Black screen on NVIDIA | You installed an AMD/Intel ISO, or have an older card; see *Older NVIDIA cards*. |
| Boot fails with a Secure Boot error | Turn Secure Boot off, or enroll the key: `ujust enroll-secure-boot-key`, password `universalblue`. |
