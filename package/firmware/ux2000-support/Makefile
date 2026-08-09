include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=ux2000-support
PKG_RELEASE:=1
PKG_FLAGS:=nonshared

include $(INCLUDE_DIR)/package.mk

define Package/ux2000-support
  SECTION:=firmware
  CATEGORY:=Firmware
  TITLE:=FiberHome UX2000 support bundle
  DEPENDS:= \
    +umbim +libmbim +mbim-utils +kmod-usb-net-cdc-mbim \
    +kmod-usb-serial-option +kmod-usb-serial-wwan \
    +kmod-mt7615e +kmod-mt7615-firmware \
    +wireguard-tools +kmod-wireguard +luci-proto-wireguard \
    +sqm-scripts +kmod-sched-cake +kmod-sched-ctinfo +kmod-ifb +luci-app-sqm \
    +luci-proto-mbim \
    +mwan3 +luci-app-mwan3 \
    +kmod-ipt-ipset +kmod-ip6tables +kmod-bonding +proto-bonding \
    +ethtool \
    +uhttpd +uhttpd-mod-ubus +luci
endef

define Package/ux2000-support/description
  Meta-package pulling in all FiberHome UX2000 extras: Quectel RM500U-CNV
  5G modem (MBIM), WireGuard VPN, SQM/basic QoS, multi-WAN failover (mwan3),
  and kernel bonding support for PDN aggregation. Selecting this guarantees
  the packages survive a normal 'make' even when only one device profile
  is built.
endef

define Build/Compile
	true
endef

define Package/ux2000-support/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./99-ux2000-network $(1)/etc/uci-defaults/99-ux2000-network
	$(INSTALL_BIN) ./99-ux2000-mwan3 $(1)/etc/uci-defaults/99-ux2000-mwan3
	$(INSTALL_BIN) ./99-ux2000-voice $(1)/etc/uci-defaults/99-ux2000-voice
endef

$(eval $(call BuildPackage,ux2000-support))
