# Bootloader (U-Boot) for FiberHome UX2000

This directory holds the **replacement U-Boot** used on the UX2000 in this
project. The stock bootloader's MTD layout was **A/B (dual-slot) style**;
this build — a **DragonBluep U-Boot 2018.09** variant, contributed to the
*dragonp* project — **restructures the flash into a single 32 MB firmware
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

## Source

The U-Boot source is **https://github.com/DragonBluep/uboot-mt7621**
("MTK U-Boot (MT7621) v2018.09 Build Customized u-boot Online", branch
`main`). This directory keeps only the built artifacts + defconfig for
archival/reflashing. The `mt7621_defconfig` here corresponds to that
project's `mt7621_defconfig`.
