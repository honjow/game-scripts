#!/bin/bash

set -e

PYTHON_SITE_PACKAGES_PATH=$(python3 -c "import site; print(site.getsitepackages()[0])")
HHD_PATH="${PYTHON_SITE_PACKAGES_PATH}/hhd"
GPD_BASE_PATH="${HHD_PATH}/device/gpd/win/base.py"

function replace_hhd_old() {
    # l4 esc
    l4_code="0x29"
    # r4 =
    r4_code="0x2E"
    # l4 + r4 求和
    l4_r4_code=$(printf '0x%X\n' $(($(echo $l4_code) + $(echo $r4_code))))

    # 分别获取包含 "case 0x" 的行号
    lines=$(grep -n "case 0x" "$GPD_BASE_PATH" | cut -d: -f1) || return 1
    line1=$(echo $lines | cut -d' ' -f1)
    line2=$(echo $lines | cut -d' ' -f2)
    line3=$(echo $lines | cut -d' ' -f3)

    [ -z "$line1" ] || [ -z "$line2" ] || [ -z "$line3" ] && return 1

    # 分别在对应行进行替换
    sudo sed -i "${line1}s/0x[0-9A-Fa-f]*/$l4_code/" "$GPD_BASE_PATH"
    sudo sed -i "${line2}s/0x[0-9A-Fa-f]*/$r4_code/" "$GPD_BASE_PATH"
    sudo sed -i "${line3}s/0x[0-9A-Fa-f]*/$l4_r4_code/" "$GPD_BASE_PATH"
    return 0
}

function replace_hhd() {
    DEFAULT_L4_KEY='"KEY_SYSRQ"'
    DEFAULT_R4_KEY='"KEY_PAUSE"'
    REP_L4_KEY='"KEY_ESC"'
    REP_R4_KEY='"KEY_EQUAL"'

    grep -q "$DEFAULT_L4_KEY\|$DEFAULT_R4_KEY" "$GPD_BASE_PATH" || return 1
    
    sudo sed -i "s/$DEFAULT_L4_KEY/$REP_L4_KEY/g" "$GPD_BASE_PATH"
    sudo sed -i "s/$DEFAULT_R4_KEY/$REP_R4_KEY/g" "$GPD_BASE_PATH"
    return 0
}

r1=0
replace_hhd_old || r1=$?

r2=0
replace_hhd || r2=$?

# 如果任意一个函数成功，就重启服务
[ $r1 -eq 0 ] || [ $r2 -eq 0 ] && sudo systemctl restart "hhd@$USER.service"
