#
#    Copyright (C) 2016 Routek, S.L.
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#    The full GNU General Public License is included in this distribution in
#    the file called "COPYING".
#
# Contributors:
#	Agustí Moll i Garcia
#

include $(TOPDIR)/rules.mk

PKG_NAME:=batadv-config
PKG_RELEASE:=1.0.0
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/batadv-config
  TITLE:=BATMAN-adv autoconfiguration for BestFreeWifi
  SECTION:=net
  CATEGORY:=Network
  URL:=http://dev.qmp.cat
  DEPENDS:=+kmod-batman-adv +batctl
endef


define Package/batadv-config/description
	This package set configuration wireless "romming" with batman-adv.
endef

define Build/Prepare
 mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/batadv-config/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,batadv-config))
