#!/usr/bin/env python3
"""Make a touch/handheld installer: pre-create the user so the installer
needs no typing, and turn on auto-login so first boot needs none either.
Reads TOUCH_USER / TOUCH_PASSWORD from the environment and edits the
rendered iso.toml (the kickstart lives in a TOML basic string)."""
import os, re, sys

path = sys.argv[1]
user = os.environ["TOUCH_USER"].strip()
password = os.environ.get("TOUCH_PASSWORD", "").strip() or "bayzite"
if not re.fullmatch(r"[a-z_][a-z0-9_-]{0,31}", user) or user in ("root", "bin", "daemon"):
    sys.exit(f"touch_user '{user}' is not a valid Linux user name (lowercase letters, digits, - and _)")
if not re.fullmatch(r"[A-Za-z0-9._@%+=:,-]{4,64}", password):
    sys.exit("touch_password: use 4-64 letters/digits/._@%+=:,- (no spaces or quotes)")

pre = f"""# Touch installer: account made here, so no keyboard is needed.
user --name={user} --password={password} --plaintext --groups=wheel --gecos={user}
rootpw --lock
"""
post = f"""
# Touch installer: sign in automatically (change the password later in Settings).
if [ -e /usr/sbin/gdm ] || [ -e /usr/bin/gdm ]; then
  mkdir -p /etc/gdm
  touch /etc/gdm/custom.conf
  grep -q '^[[]daemon[]]' /etc/gdm/custom.conf || echo '[daemon]' >> /etc/gdm/custom.conf
  sed -i '/^AutomaticLogin/d' /etc/gdm/custom.conf
  sed -i '/^[[]daemon[]]/a AutomaticLoginEnable=True' /etc/gdm/custom.conf
  sed -i '/^AutomaticLoginEnable=True/a AutomaticLogin={user}' /etc/gdm/custom.conf
fi
# Handheld images: Bazzite's own auto-login service handles SDDM.
[ -x /usr/libexec/bazzite-autologin ] || for d in /etc/sddm.conf.d /etc/plasmalogin.conf.d; do
  mkdir -p "$d"
  printf '[Autologin]\\nUser={user}\\nSession=plasma\\nRelogin=false\\n' > "$d/90-bayzite-autologin.conf"
done
"""

def toml_escape(t):
    return t.replace("\\", "\\\\").replace('"', '\\"')

s = open(path).read()
assert s.count("%post\n") >= 1 and "%end" in s, "kickstart %post block not found"
s = s.replace("%post\n", toml_escape(pre) + "%post\n", 1)
i = s.index("%end")
s = s[:i] + toml_escape(post) + s[i:]
open(path, "w").write(s)

import tomllib
ks = tomllib.load(open(path, "rb"))["customizations"]["installer"]["kickstart"]["contents"]
assert f"user --name={user} " in ks and f"AutomaticLogin={user}" in ks
print("touch kickstart ready for user", user)
