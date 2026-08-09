#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# build.sh - sync the UX2000 overlay into an OpenWrt tree and build it.
#
# Run this from INSIDE a checked-out OpenWrt 25.12 source tree:
#   cd /path/to/openwrt
#   /path/to/openwrt-ux2000/build.sh
#
# It copies the device-support files in, configures from the saved .config,
# and builds with the clean PATH workaround for the WSL/WireGuard PATH bug.
set -euo pipefail

OVERLAY="$(cd "$(dirname "$0")" && pwd)"
OPENWRT="$(pwd)"

echo "==> Overlay : $OVERLAY"
echo "==> OpenWrt: $OPENWRT"

# 1) Firmware meta-package + uci-defaults
echo "==> Installing package/firmware/ux2000-support"
mkdir -p "$OPENWRT/package/firmware"
rm -rf "$OPENWRT/package/firmware/ux2000-support"
cp -r "$OVERLAY/package/firmware/ux2000-support" "$OPENWRT/package/firmware/"

# 2) DTS
echo "==> Installing DTS"
mkdir -p "$OPENWRT/target/linux/ramips/dts"
cp "$OVERLAY/target/linux/ramips/dts/mt7621_fiberhome_ux2000.dts" \
   "$OPENWRT/target/linux/ramips/dts/"

# 3) Device image block (append to mt7621.mk if not already present)
echo "==> Installing device image block"
if ! grep -q "fiberhome_ux2000" "$OPENWRT/target/linux/ramips/image/mt7621.mk"; then
  cat "$OVERLAY/target/linux/ramips/image/device-fiberhome_ux2000.mk" \
    >> "$OPENWRT/target/linux/ramips/image/mt7621.mk"
fi

# 4) Configure
echo "==> Configuring"
if [ -f "$OVERLAY/configs/ux2000.config" ]; then
  cp "$OVERLAY/configs/ux2000.config" "$OPENWRT/.config"
fi
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
make defconfig

# 5) Build (clean PATH to avoid the WSL WireGuard `find -execdir` breakage)
echo "==> Building"
make -j"$(nproc)"

echo "==> Done. Image:"
ls -1 "$OPENWRT/bin/targets/ramips/mt7621/"*fiberhome_ux2000* 2>/dev/null || true
