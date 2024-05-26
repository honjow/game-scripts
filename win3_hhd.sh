#!/bin/bash

set -e

# l4 esc
l4_code="0x29"

# r4 =
r4_code="0x2E"

# l4 + r4 求和
l4_r4_code=$(printf '0x%X\n' $(( $(echo $l4_code) + $(echo $r4_code) )))

hhd_path="/usr/lib/python*/site-packages/hhd"
gpd_base_path="$hhd_path/device/gpd/win/base.py"

# 分别获取包含 "case 0x" 的行号
lines=$(grep -n "case 0x" $gpd_base_path | cut -d: -f1)
# 取前三个行号
line1=$(echo $lines | cut -d' ' -f1)
line2=$(echo $lines | cut -d' ' -f2)
line3=$(echo $lines | cut -d' ' -f3)

# 分别在对应行进行替换, "case 0xXXXX:" -> "case l4_code:"
sudo sed -i "${line1}s/0x[0-9A-Fa-f]*/$l4_code/" $gpd_base_path
sudo sed -i "${line2}s/0x[0-9A-Fa-f]*/$r4_code/" $gpd_base_path
sudo sed -i "${line3}s/0x[0-9A-Fa-f]*/$l4_r4_code/" $gpd_base_path

sudo systemctl restart hhd@$USER.service