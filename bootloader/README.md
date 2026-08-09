# Bootloader (U-Boot) for FiberHome UX2000

This directory holds the **replacement U-Boot** used on the UX2000 in this
project. The stock bootloader's MTD layout was **A/B (dual-slot) style**;
this build — a **DragonBluep U-Boot 2018.09** variant (from the
`DragonBluep/uboot-mt7621` repository, MTK U-Boot with Failsafe Mode) —
**restructures the flash into a single 32 MB firmware
partition**, which is what the OpenWrt image in this repo targets.

> ⚠️ **WARNING**: the stock U-Boot was accidentally wiped from the UX2000's
> `u-boot` MTD partition during development. Flashing the wrong bootloader
> (or a bootloader expecting a different MTD map) can **brick the device**.
> Only use these files if your unit is already running this DragonBluep build
> (or you have a UART + SPI recovery path). The OpenWrt `sysupgrade` image
> does **not** touch the bootloader partition.

## Files

| File | What it is |
|---|---|
| `mt7621_defconfig` | U-Boot build config (source of truth for the MTD map) |
| `u-boot-mt7621.bin` | Raw concatenated U-Boot image for SPI-NOR (`0x00000`) |
| `u-boot.img` | Legacy uImage wrapper (`u-boot-lzma.img` payload) |

## Key configuration (`mt7621_defconfig`)

```
CONFIG_MTDPARTS_DEFAULT="mtdparts=raspi:192k(u-boot),64k(u-boot-env),64k(factory),-(firmware)"
CONFIG_ENV_SIZE=0x10000
CONFIG_DEFAULT_DEVICE_TREE="mt7621_nor_template"
CONFIG_BOOTCOMMAND="mtkautoboot"
CONFIG_BOOTDELAY=0
CONFIG_SPI_BOOT=y
CONFIG_WEBUI_FAILSAFE=y
CONFIG_WEBUI_FAILSAFE_ON_AUTOBOOT_FAIL=y
CONFIG_FAILSAFE_ON_BUTTON=y
```

## Partition map (single-firmware layout)

| Partition | Offset | Size |
|---|---|---|
| `u-boot` | `0x00000` | 192 KiB (`0x30000`) |
| `u-boot-env` | `0x30000` | 64 KiB (`0x10000`) |
| `factory` | `0x40000` | 64 KiB (`0x10000`) — **64k, not the stock 128k** |
| `firmware` | `0x50000` | rest → **32448 KiB** (`0x1FB0000`) |

This is what the OpenWrt DTS (`target/linux/ramips/dts/mt7621_fiberhome_ux2000.dts`)
and `IMAGE_SIZE := 32448k` must match. There is **no separate config
partition** in this layout.

## Recovery

- The build enables a **web-based failsafe** (`CONFIG_WEBUI_FAILSAFE`) that
  triggers on autoboot failure, and a **button-triggered failsafe**
  (`CONFIG_FAILSAFE_ON_BUTTON`). Use these to recover a bad OpenWrt flash
  without UART if the bootloader itself is intact.
- The boot command is `mtkautoboot` with `BOOTDELAY=0`, so there is no
  interactive countdown by default — recovery is via the web UI / button, or
  a UART serial console.

## Rebuilding via the online builder

The `DragonBluep/uboot-mt7621` repo offers a GitHub Actions **"Build
customized u-boot"** workflow, so you can regenerate `u-boot-mt7621.bin`
without a local toolchain. To reproduce **this** build (the single-32 MB
firmware layout), fork the repo, open **Actions → Build customized
u-boot → Run workflow**, and set:

| Parameter | Value |
|---|---|
| Flash Type | **NOR Flash** |
| MTD Partition Table | `192k(u-boot),64k(u-boot-env),64k(factory),-(firmware)` |
| Kernel Load Address | `0x50000` (sum of all partitions before `firmware`: 192k+64k+64k) |
| Reset Button GPIO | `19` (from the UX2000 DTS `reset-gpios = <&gpio 19 …>`; leave unset if you do not need button-failsafe) |
| System LED GPIO | `6` (orange:status) or `7` (green:status) — the board's status LED |
| CPU Frequency | `880` (MHz) |
| DRAM Frequency | `1200` (MT/s, DDR3) |
| Baud Rate | `115200` |

The resulting `u-boot-mt7621.bin` is what you flash to the `u-boot` MTD
partition. The web-recovery / TFTP failsafe described above is built in
when the button/LED GPIOs are set.

> Note: the `mt7621_defconfig` archived in this directory is the saved
> config for the binary we used; the workflow above is the reproducible
> path if you need to rebuild from source.

## Source

The U-Boot source is **DragonBluep's `uboot-mt7621` repository** —
<https://github.com/DragonBluep/uboot-mt7621> ("MediaTek MT7621 U-Boot
with Failsafe Mode", by Shiji Yang / sanshian, GPL-2.0). This directory
keeps only the built artifacts + defconfig for archival/reflashing. The
`mt7621_defconfig` here corresponds to that repository's `mt7621_defconfig`.
