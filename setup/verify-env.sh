#!/usr/bin/env bash
# Checks the dk64-ps5 WSL distro: toolchain, packages and the lockdown.
set -uo pipefail

echo "--- tools"
for t in clang clang++ clang-18 clang-21 ld.lld-18 ld.lld-21 mips-linux-gnu-ld cmake ninja meson glslangValidator git python3; do
    printf '%-18s ' "$t"
    if command -v "$t" >/dev/null; then "$t" --version 2>&1 | head -1; else echo MISSING; fi
done

echo "--- python modules"
python3 -c 'import mako, yaml, packaging, ply, PIL; print("mako yaml packaging ply PIL ok")'

echo "--- template packages"
pkgs=$(sed -n '/^packages=(/,/^)/p' /mnt/dk64/setup/wsl-packages.sh | grep -v '[()]')
missing=0
for p in $pkgs; do dpkg -s "$p" >/dev/null 2>&1 || { echo "missing: $p"; missing=1; }; done
[ $missing -eq 0 ] && echo "all $(echo $pkgs | wc -w) installed"

echo "--- lockdown"
[ -e /mnt/c/Windows ] && echo "C: mounted (bad)" || echo "C: not mounted"
ls /proc/sys/fs/binfmt_misc/ 2>/dev/null | grep -qi wsl && echo "Windows interop registered (bad)" || echo "Windows interop off"
echo "user: $(whoami)"

echo "--- disk"
df -h / | tail -1
