# Bayzite

**A macOS-style Linux, built on [Bazzite](https://bazzite.gg).**

Bayzite is Bazzite (the gaming-focused Fedora Atomic distro) with a complete Mac makeover
baked in: menu bar on top, centred frosted-glass dock at the bottom, traffic-light window
buttons on the left, Mac-like themes, icons and cursors, Spotlight-style search on
<kbd>Super</kbd>+<kbd>Space</kbd>, genie minimise animation, and original wallpapers.

Nothing needs setting up after install. You install it, create your account in the
installer, and it boots straight into the Mac look. You still get everything Bazzite has:
Steam, Proton, the gaming kernel, HDR, drivers, automatic updates and rollbacks.

---

## Pick your edition

| Your computer's graphics | Want it closest to a Mac? (**recommended**) | Prefer KDE Plasma? |
|---|---|---|
| AMD or Intel | `bayzite-gnome` | `bayzite-kde` |
| NVIDIA (GTX 16-series, RTX 20-series or newer) | `bayzite-gnome-nvidia` | `bayzite-kde-nvidia` |

*Not sure what graphics you have?* On Windows, right-click the Start button → **Device
Manager** → **Display adapters**.

*Older NVIDIA card (GTX 900/1000)?* See [docs/ADVANCED.md](docs/ADVANCED.md#older-nvidia-cards).

---

## How to get the ISO (one-time setup, ~15 minutes of clicking + ~1–2 hours of waiting)

GitHub builds the ISOs for you on its computers, for free. You never need Linux to do this.

### 1. Make a free GitHub account
Go to <https://github.com/signup> and create an account. Verify your email.

### 2. Create a repository
1. Click the **+** (top right) → **New repository**.
2. **Repository name:** `bayzite` (any name works).
3. Choose **Public** (important: public repos get free build minutes and free storage).
4. Leave everything else unticked and click **Create repository**.

### 3. Upload this project
1. Unzip `bayzite.zip` on your PC. Open the `bayzite` folder so you can see
   `Containerfile`, `README.md`, and the folders `.github`, `build_files`, `disk_config`,
   `docs`, `system_files` and `tools`.
2. On your new repository page, click the link **uploading an existing file**.
3. Select **everything inside** the `bayzite` folder (Ctrl+A) and drag it onto the
   upload page, then click **Commit changes**.
4. GitHub's upload page skips anything whose name starts with a dot, so the build
   recipes in `.github/workflows` need adding by hand: click **Add file → Create new file**,
   type `.github/workflows/build.yml` as the name, paste in the contents of that file from
   the zip, and click **Commit changes**. Do the same for `.github/workflows/build-iso.yml`.

> **Easier alternative:** install [GitHub Desktop](https://desktop.github.com/), choose
> **File → Add local repository**, pick the unzipped `bayzite` folder, publish it to your
> account, and untick "Keep this code private". That uploads everything in one go.

### 4. Let it build
1. Open the **Actions** tab of your repository. If GitHub asks, click
   **I understand my workflows, go ahead and enable them**.
2. **Build Bayzite images** starts by itself (if it doesn't, click it → **Run workflow**).
   It builds all four editions in parallel and takes about **30–60 minutes**.
3. When it finishes with green ticks, **Build Bayzite ISOs** starts automatically and
   takes another **30–60 minutes**.

### 5. Make your images public (so installed PCs can get updates)
1. Click your profile picture → **Your profile** → **Packages** tab.
2. For each `bayzite-…` package: open it → **Package settings** (right side) →
   **Change visibility** → **Public** → type the name to confirm.

### 6. Download your ISO
1. **Actions** tab → click the latest **Build Bayzite ISOs** run.
2. Scroll to **Artifacts** and click the edition you want, e.g. `bayzite-gnome-iso`.
3. You get a `.zip` (about 6–9 GB). Unzip it to get `bayzite-gnome-YYYYMMDD.iso`.

ISOs stay downloadable for 30 days. To make fresh ones any time:
**Actions → Build Bayzite ISOs → Run workflow**.

---

## Installing

1. **Make a bootable USB (16 GB or bigger)** with one of:
   [Fedora Media Writer](https://fedoraproject.org/workstation/download) (choose
   "Select .iso file"), [balenaEtcher](https://etcher.balena.io/), or
   [Rufus](https://rufus.ie/) (pick **DD Image mode** when asked).
2. **Secure Boot:** the easiest path is to turn **Secure Boot off** in your BIOS/UEFI
   settings before installing. (If you leave it on, the first reboot shows a blue
   *MOK management* screen: choose **Enroll MOK → Continue → Yes** and type
   `universalblue`.)
3. Boot from the USB (usually <kbd>F12</kbd>, <kbd>F11</kbd>, <kbd>F8</kbd> or <kbd>Esc</kbd> at power-on).
4. In the installer: pick your language, **Installation Destination** (the disk to use —
   it will be erased unless you choose otherwise), **User Creation** (tick *Make this user
   administrator*), then **Begin Installation**.
5. Reboot, log in, done.

On the very first login Bazzite quietly installs a few apps (Firefox and friends) in the
background, so a couple of dock icons may appear a few minutes later.

---

## What makes it feel like a Mac

| | GNOME edition | KDE edition |
|---|---|---|
| Top menu bar with logo menu (Shut Down, Restart, Settings…) | ✅ | ✅ |
| App menus in the top bar (global menu) | — (GNOME apps use in-window menus) | ✅ |
| Centred dock with running-app dots and Trash | ✅ Dash to Dock | ✅ Floating Plasma dock |
| Frosted-glass blur | ✅ Blur my Shell | ✅ Kvantum + WhiteSur |
| Close/minimise/maximise on the left | ✅ | ✅ |
| Genie minimise animation | ✅ | ✅ Magic Lamp |
| Mac-style theme, icons, cursors | ✅ WhiteSur | ✅ WhiteSur |
| Mac-style login screen | ✅ | ✅ wallpaper |
| Clock on the right with day and date | ✅ | ✅ |
| Natural scrolling + tap-to-click on touchpads | ✅ | Plasma defaults |
| Boots to the desktop, not an app overview | ✅ | ✅ |
| Light & dark wallpaper that follows the theme | ✅ | ✅ |

### Mac-style keyboard shortcuts
The Windows/Super key acts as ⌘ Command.

| Shortcut | Does |
|---|---|
| <kbd>Super</kbd>+<kbd>Space</kbd> | Search / open apps (like Spotlight) |
| <kbd>Super</kbd>+<kbd>Tab</kbd> | Switch apps |
| <kbd>Super</kbd>+<kbd>Q</kbd> | Close window (GNOME) |
| <kbd>Super</kbd>+<kbd>H</kbd> | Hide/minimise window (GNOME) |
| <kbd>Shift</kbd>+<kbd>Super</kbd>+<kbd>3</kbd> | Screenshot of the whole screen (GNOME) |
| <kbd>Shift</kbd>+<kbd>Super</kbd>+<kbd>4</kbd> / <kbd>5</kbd> | Screenshot tool (GNOME) |
| <kbd>Ctrl</kbd>+<kbd>Super</kbd>+<kbd>F</kbd> | Full screen (GNOME) |

Everything is only a default: users can change any of it in **Settings**.

### What it isn't
It doesn't run macOS apps, and it isn't macOS. Apple's fonts, logos and wallpapers are
proprietary, so Bayzite uses open look-alikes instead: the **Inter** font, the open-source
**WhiteSur** theme family, and its own original wallpapers and logo.

---

## Updates
Installed PCs update themselves like any Bazzite system. Your repository also rebuilds
every day at 07:20 UTC so it always sits on top of the newest Bazzite. Updates land on the
next reboot, and you can pick the previous version from the boot menu if anything goes wrong.

---

## What's in this repository

```
Containerfile                 recipe: start from Bazzite, run build_files/build.sh
build_files/
  build.sh                    main build script
  install-whitesur-common.sh  Mac theme, icons, cursors (both desktops)
  setup-gnome.sh              dock, top bar, login screen for GNOME
  setup-kde.sh                menu bar + dock layout, Kvantum for KDE
  versions.env                pinned theme versions
system_files/
  shared/                     wallpapers, logo, small helpers (both editions)
  gnome/                      GNOME defaults (dconf)
  kde/                        Plasma defaults, global theme, wallpaper package
disk_config/iso.toml          installer settings
.github/workflows/
  build.yml                   builds and publishes the 4 OS images
  build-iso.yml               turns them into installer ISOs
tools/make_wallpapers.py      regenerates the wallpapers
docs/ADVANCED.md              customising, signing, testing, troubleshooting
```

## Credits & licences
- [Bazzite](https://github.com/ublue-os/bazzite) and [Universal Blue](https://universal-blue.org/) — the base OS and the image template this project follows (Apache-2.0).
- [WhiteSur GTK/KDE/icons/cursors](https://github.com/vinceliuice) by Vince Liuice (GPL-3.0), downloaded at build time.
- [Dash to Dock](https://github.com/micheleg/dash-to-dock), [Just Perfection](https://gitlab.gnome.org/jrahmatzadeh/just-perfection), [Blur my Shell](https://github.com/aunetx/blur-my-shell), [Inter](https://rsms.me/inter/).
- Bayzite's own files: Apache-2.0 (see `LICENSE`). Bayzite is not affiliated with Apple or Universal Blue.
