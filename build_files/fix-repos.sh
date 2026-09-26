#!/usr/bin/bash
# Make the .repo files agree with what dnf5 actually uses.
#
# Bazzite turns some repos off with `dnf5 config-manager setopt`, which only
# writes an override file. The ISO builder (bootc-image-builder) reads the
# plain .repo files, sees those repos as enabled, and fails (for example on
# terra-mesa's missing GPG key). Here we write enabled=0 straight into the
# .repo files for every repo dnf5 reports as disabled, and also for any
# enabled repo whose file:// GPG key is missing (dnf can't use those anyway).
set -euo pipefail

python3 - <<'PY'
import glob, os, re, subprocess

out = subprocess.run(["dnf5", "repo", "list", "--disabled"],
                     capture_output=True, text=True).stdout
releasever = subprocess.run(["rpm", "-E", "%fedora"], capture_output=True, text=True).stdout.strip()
basearch = os.uname().machine

def expand(s):
    # repo files use $releasever / $basearch inside key paths
    return (s.replace("$releasever", releasever).replace("${releasever}", releasever)
             .replace("$basearch", basearch).replace("${basearch}", basearch))

disabled = set()
for line in out.splitlines()[1:]:
    parts = line.split()
    if parts:
        disabled.add(parts[0])

for path in glob.glob("/etc/yum.repos.d/*.repo"):
    with open(path) as f:
        lines = f.read().splitlines()
    # collect sections: id -> (start, end)
    sections, cur = {}, None
    for i, line in enumerate(lines):
        m = re.match(r"^\s*\[([^\]]+)\]\s*$", line)
        if m:
            cur = m.group(1)
            sections[cur] = [i, len(lines)]
            if len(sections) > 1:
                prev = list(sections)[-2]
                sections[prev][1] = i
    changed = False
    for sid, (start, end) in sorted(sections.items(), key=lambda kv: -kv[1][0]):
        body = lines[start + 1:end]
        opts = {}
        for l in body:
            m = re.match(r"^\s*([A-Za-z_]+)\s*=\s*(.*)$", l)
            if m:
                opts[m.group(1).lower()] = m.group(2).strip()
        keys = re.split(r"[\s,]+", opts.get("gpgkey", ""))
        missing_key = any(
            k.startswith("file://") and "$" not in expand(k) and not os.path.exists(expand(k)[7:])
            for k in keys if k)
        enabled = opts.get("enabled", "1").lower() in ("1", "true", "yes")
        if enabled and (sid in disabled or missing_key):
            reason = "disabled in dnf5" if sid in disabled else "missing GPG key"
            print(f"{os.path.basename(path)}: [{sid}] -> enabled=0 ({reason})")
            new_body = [l for l in body if not re.match(r"^\s*enabled\s*=", l)]
            new_body.insert(0, "enabled=0")
            lines[start + 1:end] = new_body
            changed = True
    if changed:
        with open(path, "w") as f:
            f.write("\n".join(lines) + "\n")
PY
