#!/bin/bash

set -euo pipefail
#set -x

dir="/tmp/null"
rm -rf "$dir"
mkdir "$dir"
cd "$dir"

# Add all arguments as the initial core packages
printf '%s\n' "$@" > keep
# Packages required for a shell environment
cat >>keep <<EOF
bash
coreutils
EOF

# Disallow list to block certain packages and their dependencies
cat >disallow <<EOF
alsa-lib
cups-libs
gawk
python3
p11-kit
EOF

sort -u keep -o keep

echo "==> Installing packages into chroot" >&2

set -x

# Check if findutils and diffutils are installed, install if not.
if ! rpm -q findutils &>/dev/null; then
 echo "findutils not found. Attempting to install."
 if zypper install -y findutils; then
  echo "findutils installed successfully."
 else
  echo "Error installing findutils. Exiting."
  exit 1
 fi
fi

if ! rpm -q diffutils &>/dev/null; then
 echo "diffutils not found. Attempting to install."
 if zypper install -y diffutils; then
  echo "diffutils installed successfully."
 else
  echo "Error installing diffutils. Exiting."
  exit 1
 fi
fi

rootfs="$(realpath rootfs)"
mkdir -p "$rootfs"

# Refresh repositories before installing to chroot
zypper --installroot "$rootfs" -n refresh

<keep xargs zypper --installroot "$rootfs" -n --gpg-auto-import-keys in --no-recommends
zypper --installroot "$rootfs" clean -a
rm -rf "$rootfs"/var/cache/zypp/* "$rootfs"/var/log/zypp/*
{ set +x; } 2>/dev/null

echo "==> Building dependency tree" >&2

# 1. Get requirement names (not quite the same as package names)
# 2. Filter out any install-time requirements
# 3. Query which packages are being used to satisfy the requirements
# 4. Keep just their package names
# 5. Remove packages that are on the disallow list
# 6. Store result as an allowlist
<keep xargs rpm -r "$rootfs" -q --requires | sort -Vu | cut -d ' ' -f1 \
  | grep -v -e '^rpmlib(' \
  | xargs -d $'\n' rpm -r "$rootfs" -q --whatprovides \
  | grep -v -e '^no package provides' \
  | sed -r 's/^(.*)-.*-.*$/\1/' \
  | grep -vxF -f disallow \
  > new || true

mv keep old
cat old new > keep
sort -u keep -o keep

rpm -r "$rootfs" -qa | sed -r 's/^(.*)-.*-.*$/\1/' | sort -u > all
grep -vxF -f keep all > remove

echo "==> $(wc -l remove | cut -d ' ' -f1) packages to erase:" >&2
cat remove
echo "==> $(wc -l keep | cut -d ' ' -f1) packages to keep:" >&2
cat keep
echo "" >&2

# echo "==> Erasing packages" >&2
# set -x
# <remove xargs rpm -r "$rootfs" --erase --allmatches
# { set +x; } 2>/dev/null

echo "" >&2
echo "==> Packages erased ok!" >&2
