#!/usr/bin/env bash
# One-time setup of the dk64-ps5 WSL distro. Run as root, then restart the distro
# (wsl --terminate dk64-ps5). It creates the build user, stops Windows drives being
# mounted except this project folder, and stops Linux launching Windows programs.
#   setup/wsl-lockdown.sh 'C:\path\to\the project folder'
set -euo pipefail
project=${1:?usage: wsl-lockdown.sh <the project folder as a Windows path>}

user=sam
id "$user" >/dev/null 2>&1 || useradd --create-home --uid 1000 --shell /bin/bash "$user"

cat > /etc/wsl.conf <<'EOF'
[boot]
systemd=true

[automount]
# Windows drives are not mounted. Only the project folder is, through /etc/fstab.
enabled=false
mountFsTab=true

[interop]
# Linux cannot launch Windows programs, and the Windows PATH is not added.
enabled=false
appendWindowsPath=false

[user]
default=sam
EOF

# The project folder at /mnt/dk64. fstab octal escapes: \134 is a backslash, \040 a space.
mkdir -p /mnt/dk64
sed -i '\# /mnt/dk64 #d' /etc/fstab
escaped=${project//\\/\\134}
escaped=${escaped// /\\040}
echo "$escaped /mnt/dk64 drvfs rw,noatime,metadata,uid=1000,gid=1000,umask=022 0 0" >> /etc/fstab

echo "lockdown written; restart the distro to apply"
