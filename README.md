# OpenWrt for FiberHome UX2000

Custom OpenWrt build for the **FiberHome UX2000** — a MT7621A-based indoor
5G CPE. This repository holds the device-support overlay (DTS, image
definition, firmware meta-package, and first-boot uci-defaults) that turns a
stock OpenWrt 25.12 source tree into a flashable UX2000 image.

> Status: builds and flashes. LAN + WiFi (MT7615 DBDC) + LuCI + multi-WAN
> (mwan3) are working. The cellular (RM500U-CNV, MBIM) **data interface
> bring-up is not automated in this image** — see [Cellular](#cellular) below.

## Hardware

| | |
|---|---|
| SoC | MediaTek MT7621A (880 MHz, dual-core) |
| RAM | 256 MB DDR3 |
| Flash | 32 MB SPI-NOR |
| Switch | MT7530 (5× GE, DSA) |
| WiFi | MediaTek MT7615 DBDC (2.4 GHz + 5 GHz) |
| Modem | Quectel **RM500U-CNV** (5G, USB3, **MBIM-only**) |
| LEDs | status (orange/green), net (green/blue), signal bars (green 1–4), line/volte |
| UART | 115200 8N1 |
| Bootloader | DragonBluep U-Boot 2018.09 |

### Ethernet / switch layout (DSA)
- `lan1`..`lan4` — LAN switch ports
- `wan` — uplink (DHCP client by default)
- `wwan` — cellular interface (created manually / by your own init script)

### Partition map (DragonBluep U-Boot)
```
raspi:192k(u-boot),64k(u-boot-env),64k(factory),-(firmware)
```
DTS must use: u-boot `0x0/0x30000`, u-boot-env `0x30000/0x10000`,
factory `0x40000/0x10000` (**64k**, not the stock 128k), firmware
`0x50000/0x1FB0000` (32448k). `IMAGE_SIZE := 32448k`.

## Software / base version

- **OpenWrt v25.12.5** (git `6311c6495bcdde37aeaa68a41c04d97ee6499390`, 2026-08-07)
- Package manager: **apk** (not opkg)
- Feeds pinned (see `feeds.conf.default` in the OpenWrt tree)

## What this build includes

Meta-package `ux2000-support` pulls:

- **WiFi**: `kmod-mt7615e` + `kmod-mt7615-firmware`, `wpad-basic-mbedtls`
- **Web UI**: `luci-light` + `uhttpd` (+ `uhttpd-mod-ubus`) — baked in
- **Cellular (packages only)**: `libmbim`, `umbim`, `mbim-utils` (provides `mbimcli`),
  `kmod-usb-net-cdc-mbim`, `kmod-usb-serial-option`, `kmod-usb-serial-wwan`, `chat`
- **Multi-WAN / failover**: `mwan3` + `luci-app-mwan3`, `kmod-ipt-ipset`, `kmod-ip6tables`, `kmod-bonding`, `proto-bonding`
- **QoS**: SQM (`sqm-scripts` + `kmod-sched-cake` + `luci-app-sqm`) — legacy `luci-app-qos` intentionally **removed**
- **VPN**: `wireguard-tools` + `kmod-wireguard` + `luci-proto-wireguard`
- **Misc**: `ethtool`, `ip-full`, `uboot-envtools`

First-boot uci-defaults (run once, then self-delete):
- `99-ux2000-network` — LAN `192.168.8.1/24`, enables **both** WiFi radios *and*
  AP interfaces (OpenWrt leaves them disabled on a config reset), sets default APN
- `99-ux2000-mwan3` — `wan` = primary (metric 1), `wwan` = cellular backup (metric 2)
- `99-ux2000-voice` — SLIC/FXS enable (legacy EC200A-era; harmless on RM500U)

## Cellular

The RM500U-CNV is **MBIM-only** (usbnet modes 1/3/5/11/13/15; no QMI).
It enumerates as `wwan0` (via `cdc_mbim`) + `/dev/cdc-wdm0`, with
AT port on `/dev/ttyUSB2`.

> **This image does NOT ship an init script to auto-bring-up the modem.**
> The `network.wwan` interface and a boot-time bring-up script are left to you.
> Manual bring-up that is known to work on this unit:
>
> ```sh
> # 1) turn the RF on (MBIM radio-on fails on this unit; use AT+CFUN=1)
> picocom -b 115200 /dev/ttyUSB2     # then: AT+CFUN=1
> # 2) create the interface
> uci set network.wwan=interface
> uci set network.wwan.proto=mbim
> uci set network.wwan.device=/dev/cdc-wdm0
> uci set network.wwan.pdptype=ipv4v6
> uci set network.wwan.apn=internet
> uci set network.wwan.metric=20
> uci commit network
> # 3) (DITO is SA-only — NSA connect fails with PacketServiceDetached)
> ifup wwan
> ```

AT commands are reserved for **manual** tuning only (NSA/SA mode, IMEI,
band/tower lock) in picocom — they are intentionally **not** in any
automated path.

## Repository layout

```
openwrt-ux2000/
├── README.md
├── build.sh                      # helper: sync overlay into a OpenWrt tree + build
├── configs/
│   └── ux2000.config             # saved .config (reference)
├── package/firmware/ux2000-support/
│   ├── Makefile                  # meta-package + uci-defaults install
│   ├── 99-ux2000-network
│   ├── 99-ux2000-mwan3
│   └── 99-ux2000-voice
└── target/linux/ramips/
    ├── dts/mt7621_fiberhome_ux2000.dts
    └── image/device-fiberhome_ux2000.mk
```

## Building

### Prerequisites
- A Linux build host (this was built under **WSL2** on Windows)
- OpenWrt build deps installed (`setup.py` / `make prereq`)
- ~20 GB free, a few CPU cores

### Steps

```sh
# 1) Get OpenWrt 25.12 source + feeds (pins in feeds.conf.default)
git clone https://git.openwrt.org/openwrt/openwrt.git
cd openwrt
git checkout 6311c6495bcdde37aeaa68a41c04d97ee6499390   # v25.12.5
cp /path/to/feeds.conf.default .
./scripts/feeds update -a
./scripts/feeds install -a

# 2) Drop this overlay into the tree
#    (build.sh does this for you — see below)
cp -r openwrt-ux2000/package/firmware/ux2000-support  package/firmware/
cp    openwrt-ux2000/target/linux/ramips/dts/mt7621_fiberhome_ux2000.dts target/linux/ramips/dts/
#    append the device block to the ramips image makefile:
cat   openwrt-ux2000/target/linux/ramips/image/device-fiberhome_ux2000.mk \
      >> target/linux/ramips/image/mt7621.mk

# 3) Configure + build
cp openwrt-ux2000/configs/ux2000.config .config
make defconfig
# NOTE: on WSL the Windows PATH can leak a "Program Files/WireGuard" entry that
# breaks `find -execdir`. Always prefix the build with a clean PATH:
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
make -j$(nproc)
```

Artifacts land in `bin/targets/ramips/mt7621/`:
`openwrt-ramips-mt7621-fiberhome_ux2000-squashfs-sysupgrade.bin`,
`factory.bin`, `recovery.bin`, `initramfs-kernel.bin`.

### Using build.sh

`build.sh` assumes it is run from inside a checked-out OpenWrt tree and
copies the overlay in, then builds:

```sh
cd /path/to/openwrt
/path/to/openwrt-ux2000/build.sh
```

## Flashing

Via running OpenWrt (sysupgrade, **no settings kept** — the `-n` matters
because the WiFi/network uci-defaults only run on a clean flash):

```sh
scp openwrt-...-squashfs-sysupgrade.bin root@192.168.8.1:/tmp/
ssh root@192.168.8.1 "sysupgrade -n /tmp/openwrt-...-squashfs-sysupgrade.bin"
```

After flash: LAN `192.168.8.1`, WiFi SSID `OpenWrt` on both bands,
LuCI at http://192.168.8.1.

## Notes / gotchas

- **LuCI must be in the image** (`luci-light` + `uhttpd`). Earlier builds
  omitted `uhttpd` and LuCI was unreachable until installed via `apk add`.
- **MT7615 driver** must be selected (`kmod-mt7615e` + `kmod-mt7615-firmware`);
  the wrong `kmod-mt7915e` was selected once and produced no WiFi.
- **WSL PATH bug**: Windows `C:\Program Files\WireGuard` leaks into `$PATH`
  and breaks OpenWrt's `find -execdir`. Prefix every `make` with the clean
  `PATH` shown above.
- **DITO (PH) is SA-only**: in NSA mode `--connect` fails with
  `PacketServiceDetached`. Set the modem to SA (or LTE) first.
- The `99-ux2000-voice` (SLIC) script is legacy EC200A-era; it is harmless
  on the RM500U but does not drive voice on this module.

## License

OpenWrt and its packages are under their respective licenses (mostly GPL-2.0).
The device-support files in this repository are released under GPL-2.0.
See <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.
