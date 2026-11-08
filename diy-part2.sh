#!/bin/bash
#============================================================
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#============================================================

# Modify default IP
sed -i 's/192.168.6.1/192.168.233.1/g' package/base-files/files/bin/config_generate

# Limit OpenClash sysupgrade backups to persistent user data. Downloadable
# runtime assets such as the core and GeoIP/GeoSite databases can otherwise
# make the backup too large to restore safely on devices with small flash.
OPENCLASH_DEFAULTS="feeds/luci/applications/luci-app-openclash/root/etc/uci-defaults/luci-openclash"
python3 - "$OPENCLASH_DEFAULTS" <<'PYTHON'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = '''cat > "/lib/upgrade/keep.d/luci-app-openclash" <<-EOF
/etc/openclash/
EOF'''
new = '''cat > "/lib/upgrade/keep.d/luci-app-openclash" <<-EOF
/etc/openclash/config/
/etc/openclash/custom/
/etc/openclash/overwrite/
/etc/openclash/proxy_provider/
/etc/openclash/rule_provider/
/etc/openclash/game_rules/
/etc/openclash/backup/
EOF'''

if old not in text:
    raise SystemExit(f"OpenClash sysupgrade keep block not found in {path}")

path.write_text(text.replace(old, new, 1))
PYTHON

# Modify hostname
#sed -i 's/OpenWrt/360T7/g' package/base-files/files/bin/config_generate

# ---------------------------------------------------------
# PassWall 新版内核适配
# sing-box 1.14.4、geoview 0.2.9 的 go.mod 要求 Go >= 1.25，
# 而本源码树自带 Go 1.23.12（构建时报
# "go.mod requires go >= 1.25.0 (running go 1.23.12; GOTOOLCHAIN=local)"）。
# 打开 GOTOOLCHAIN=auto，让 go 自动拉取 go.mod 要求的工具链。
# ---------------------------------------------------------
GOLANG_PKG_MK="feeds/packages/lang/golang/golang-package.mk"
if [ -f "$GOLANG_PKG_MK" ]; then
  sed -i 's/^\([[:space:]]*\)GOTOOLCHAIN=local[[:space:]]*$/\1GOTOOLCHAIN=auto/' "$GOLANG_PKG_MK"
  if ! grep -q 'GOTOOLCHAIN=auto' "$GOLANG_PKG_MK"; then
    echo "ERROR: failed to patch GOTOOLCHAIN in $GOLANG_PKG_MK" >&2
    exit 1
  fi
  echo "GOTOOLCHAIN=auto patched for PassWall kernels"
else
  echo "ERROR: $GOLANG_PKG_MK not found" >&2
  exit 1
fi
