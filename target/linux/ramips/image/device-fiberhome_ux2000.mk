define Device/fiberhome_ux2000
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  DEVICE_VENDOR := FiberHome
  DEVICE_MODEL := UX2000
  DEVICE_DTS := mt7621_fiberhome_ux2000
  KERNEL_SIZE := 4096k
  KERNEL := kernel-bin | append-dtb | lzma | loader-kernel | uImage none
  KERNEL_INITRAMFS := kernel-bin | append-dtb | lzma | loader-kernel | uImage none
  DEVICE_PACKAGES := \
    kmod-usb3 kmod-usb2 kmod-usb-net \
    kmod-usb-net-cdc-ncm kmod-usb-net-huawei-cdc-ncm kmod-usb-wdm \
    kmod-usb-serial-option kmod-usb-serial-wwan \
    ux2000-support \
    chat \
    kmod-mt7615e kmod-mt7615-firmware \
    wpad-basic-mbedtls \
    kmod-leds-gpio kmod-gpio-button-hotplug gpioctl-sysfs \
    luci-light \
    ppp ppp-mod-pppoe \
    ethtool ip-full uboot-envtools \
    signalled \

  IMAGE_SIZE := 32448k
  IMAGES += factory.bin recovery.bin
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | pad-rootfs | check-size | append-metadata
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | pad-rootfs | check-size
  IMAGE/recovery.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | pad-rootfs | check-size
  SUPPORTED_DEVICES += fiberhome,ux2000
  DEVICE_COMPAT_VERSION := 1.1
endef
TARGET_DEVICES += fiberhome_ux2000
