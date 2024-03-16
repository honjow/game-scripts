#!/bin/bash

function add_option() {
    GAME_ID=$1
    OPTION=$2

    vdf_path="$HOME/.local/share/Steam/userdata/*/config/localconfig.vdf"
    for file in $vdf_path; do
        if [ -f "$file" ]; then
            break
        fi
    done
}

function option_from_file() {
    GAME_ID=$1
    FILE_PATH=$2
    ADDON_OPTION=$3

    id_line=$'^\t{5}'"\"$GAME_ID\""
    block_end_line=$'^\t{5}'"}"
    option_line=$'^\t{6}'"\"LaunchOptions\""

    # 获取id_line所在的行号
    id_line_num=$(grep -n -E "$id_line" $FILE_PATH | cut -d : -f 1)
    if [[ -n $id_line_num ]]; then
        # echo "id_line_num: $id_line_num"
        # 从 id_line_num 行开始查找 block_end_line
        block_end_offset=$(sed -n "${id_line_num},\$p" $FILE_PATH | grep -n -E "$block_end_line" | head -n 1 | cut -d : -f 1)
        # echo "block_end_offset: $block_end_offset"
        if [[ -n $block_end_offset ]]; then
            block_end_line_num=$(($id_line_num + $block_end_offset - 1))
            # echo "block_end_line_num: $block_end_line_num"
            # 从 id_line_num 行开始查找 OPTION
            option_line=$(sed -n "${id_line_num},${block_end_line_num}p" $FILE_PATH | grep -E "$option_line")
            # echo "option_line: $option_line"
            # 示例
            # 						"LaunchOptions"		"SteamDeck=0 LANG=\"zh_CN.utf8\" %command%"
            option=$(echo $option_line | awk -F '"LaunchOptions" ' '{print $2}')
            # "SteamDeck=0 LANG=\"zh_CN.utf8\" %command%" -> SteamDeck=0 LANG="zh_CN.utf8" %command%
            option=$(echo $option | sed 's/^\"//g;s/\"$//g;s/\\"/"/g')
            echo "option: $option"

            if [[ -n $ADDON_OPTION ]]; then
                # 如果 option 中已经包含了 ADDON_OPTION 则不添加
                if [[ $option != *"$ADDON_OPTION"* ]]; then
                    option="$option $ADDON_OPTION"
                    echo "new option: $option"
                fi
            fi
        fi
    fi

}

function get_option() {
    GAME_ID=$1

    vdf_path="$HOME/.local/share/Steam/userdata/*/config/localconfig.vdf"
    for file in $vdf_path; do
        if [ -f "$file" ]; then
            option_from_file $GAME_ID $file
        fi
    done
}

case $1 in
    add)
        if [[ -n $2 && -n $3 ]]; then
            add_option $2 $3
        else
            echo "Usage: $0 {add|get} {GAME_ID} {OPTION}"
        fi
        add_option $2 $3
        ;;
    get)
        if [[ -n $2 ]]; then
            get_option $2
        else
            echo "Usage: $0 {add|get} {GAME_ID}"
        fi
        get_option $2
        ;;
    *)
        echo "Usage: $0 {add|get} {GAME_ID}"
        ;;
esac