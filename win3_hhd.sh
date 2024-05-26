#!/bin/bash

set -e

# l4 esc
l4_code="0x29"

# r4 l_alt
r4_code="0xE2"

# l4 + r4 求和
l4_r4_code=$(printf '0x%X\n' $(( $(echo $l4_code) + $(echo $r4_code) )))

hhd_path=/usr/lib/python*/site-packages/hhd
gpd_base_path="$hhd_path/device/gpd/win/base.py"

ori_l4_code="0x46"
ori_r4_code="0x48"
ori_l4_r4_code="0x8E"

sed -i "s/case ${ori_l4_code}/case ${l4_code}/g" $gpd_base_path
sed -i "s/case ${ori_r4_code}/case ${r4_code}/g" $gpd_base_path
sed -i "s/case ${ori_l4_r4_code}/case ${l4_r4_code}/g" $gpd_base_path

sudo systemctl restart hhd@$USER.service