#!/bin/bash
# Copyright Aless Microsystems 2025.

set -euo pipefail
#set -o xtrace
# Setup working directory
dir="/tmp/null"
rm -rf "$dir"
mkdir -p "$dir"
cd "$dir"

# Save initial arguments as core packages
printf '%s\n' "$@" > keep

# Essential base packages
cat >> keep <<EOF
bash
coreutils
EOF

# Packages to explicitly exclude
cat >disallow <<EOF
alsa-lib
cups-libs
gawk
python3
python3-pip
python3-setuptools
python3-wheel
info
EOF

sort -u keep -o keep

echo "==> Installing packages into chroot" >&2

# Ensure findutils and diffutils are available on host
for pkg in findutils diffutils; do
  if ! rpm -q "$pkg" &>/dev/null; then
    echo "$pkg not found. Attempting to install."
    if ! zypper install -y "$pkg"; then
      echo "Error installing $pkg. Exiting."
      exit 1
    fi
  fi
done

# Prepare chroot rootfs
rootfs="$(realpath rootfs)"
mkdir -p "$rootfs"

# Refresh repositories and install base packages
zypper --installroot "$rootfs" -n --gpg-auto-import-keys refresh
xargs -a keep zypper --installroot "$rootfs" -n --gpg-auto-import-keys in --no-recommends
zypper --installroot "$rootfs" clean -a
rm -rf "$rootfs"/var/cache/zypp/* "$rootfs"/var/log/zypp/*

echo "==> Building dependency tree" >&2
# Loop until we have the full dependency tree (no new packages found)
touch old
while ! cmp -s keep old
do
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
        | grep -vxF -f disallow  \
        > new || true

    # Safely replace the keep list, appending the new names
    mv keep old
    cat old new > keep
    # Sort and deduplicate so cmp will eventually return true
    sort -u keep -o keep
done
# Determine all packages that need to be removed
rpm -r "$rootfs" -qa | sed -r 's/^(.*)-.*-.*$/\1/' | sort -u > all
# Set complement (all - keep)
echo "All packages: "
cat all
echo "Keep Packages "
cat keep
if ! grep -vxF -f keep all > remove; then
  if [[ $? -eq 2 ]]; then
    echo "grep encountered an actual error" >&2
    exit 1
  fi
fi
echo "==> $(wc -l remove | cut -d ' ' -f1) packages to erase:" >&2
cat remove
echo "==> $(wc -l keep | cut -d ' ' -f1) packages to keep:" >&2
cat keep
echo "" >&2

echo "==> Erasing packages" >&2
# Delete all packages that aren't needed for the core packages
if [[ -s remove ]]; then
  set -x
  <remove xargs rpm -r "$rootfs" --erase --nodeps --verbose --allmatches
  { set +x; } 2>/dev/null
else
  echo "==> No packages to erase." >&2
fi
echo "" >&2
echo "==> Packages erased ok!" >&2
