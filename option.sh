#!/bin/bash

function option_from_file() {
    local GAME_ID=$1
    local FILE_PATH=$2
    local ADDON_OPTION=$3
    local RELOAD_STEAM=$4

    id_match=$'^\t{5}'"\"$GAME_ID\""
    block_end_match=$'^\t{5}'"}"
    option_match=$'^\t{6}'"\"LaunchOptions\""

    echo "$FILE_PATH"

    # 获取id_line所在的行号
    id_line_num=$(grep -n -E "$id_match" $FILE_PATH | cut -d : -f 1)
    if [[ -n $id_line_num ]]; then
        # echo "id_line_num: $id_line_num"
        # 从 id_line_num 行开始查找 block_end_match
        block_end_offset=$(sed -n "${id_line_num},\$p" $FILE_PATH | grep -n -E "$block_end_match" | head -n 1 | cut -d : -f 1)
        # echo "block_end_offset: $block_end_offset"
        if [[ -n $block_end_offset ]]; then
            block_end_line_num=$(($id_line_num + $block_end_offset - 1))
            # echo "block_end_line_num: $block_end_line_num"

            option_line_offset=$(sed -n "${id_line_num},${block_end_line_num}p" $FILE_PATH | grep -n -E "$option_match" | head -n 1 | cut -d : -f 1)
            # echo "option_line_offset: $option_line_offset"

            if [[ -n $option_line_offset ]]; then
                option_line_num=$(($id_line_num + $option_line_offset - 1))
                echo "option_line_num: $option_line_num"
            fi

            if [[ -n $option_line_num ]]; then

                # 获取 option 所在的行
                option_line=$(sed -n "${option_line_num}p" $FILE_PATH)

                # 从 id_line_num 行开始查找 OPTION
                option_line=$(sed -n "${id_line_num},${block_end_line_num}p" $FILE_PATH | grep -E "$option_match")

                # echo "option_line: [$option_line]"

                # 示例
                # 						"LaunchOptions"		"SteamDeck=0 LANG=\"zh_CN.utf8\" %command%"
                option_raw=$(echo $option_line | awk -F '"LaunchOptions" ' '{print $2}')
                echo "option_raw [$option_raw]"
                # "SteamDeck=0 LANG=\"zh_CN.utf8\" %command%" -> SteamDeck=0 LANG="zh_CN.utf8" %command%
                option=$(echo $option_raw | sed 's/^\"//g;s/\"$//g;s/\\"/"/g')
                echo "option [$option]"
            fi

            if [[ -n $ADDON_OPTION ]]; then
                if [[ -z $option ]]; then
                    new_option="$ADDON_OPTION %command%"
                fi

                # 如果 option 中已经包含了 ADDON_OPTION 则不添加
                if [[ $option =~ "$ADDON_OPTION " ]]; then
                    return
                fi

                # 如果 option 包含 "%command%"
                if [[ $option =~ "%command%" ]]; then
                    # 将 %command% 替换为 ADDON_OPTION %command%
                    new_option=$(echo $option | sed "s/%command%/$ADDON_OPTION %command%/g")
                else
                    new_option="$ADDON_OPTION %command% $option"
                fi

                new_option_raw="\"$(echo $new_option | sed 's/"/\\"/g')\""
                echo "new_option_raw [$new_option_raw]"
                option_raw_sed=$(echo $option_raw | sed 's#\"#\\"#g;s#"#\"#g')
                new_option_raw_sed=$(echo $new_option_raw | sed 's#\"#\\"#g;s#"#\"#g')
                if [[ -n $option_line_num ]]; then
                    command="sed -i '${option_line_num}s#$option_raw_sed#$new_option_raw_sed#' $FILE_PATH"
                    echo "command: $command"
                    # sed -i "${option_line_num}s#$option_raw#$new_option_raw#" $FILE_PATH
                    eval $command
                else
                    echo "add new option to line $block_end_line_num"
                    sed -i "${block_end_line_num}i \ \t\t\t\t\t\t\\\"LaunchOptions\\\"\t\t$new_option_raw_sed" $FILE_PATH
                fi

                if [[ "$option" != "$new_option" ]]; then
                    echo "option changed from [$option] to [$new_option]"
                    if [[ -n "$RELOAD_STEAM" ]]; then
                        pkill -HUP steam
                    fi
                fi
            fi
        fi
    fi

}

function get_option() {
    local GAME_ID=$1

    vdf_path="$HOME/.local/share/Steam/userdata/*/config/localconfig.vdf"
    for file in $vdf_path; do
        if [ -f "$file" ]; then
            option_from_file $GAME_ID $file
        fi
    done
}

function add_option() {
    local GAME_ID=$1
    local OPTION=$2
    local RELOAD_STEAM=$3

    vdf_path="$HOME/.local/share/Steam/userdata/*/config/localconfig.vdf"
    for file in $vdf_path; do
        if [ -f "$file" ]; then
            option_from_file $GAME_ID $file $OPTION $RELOAD_STEAM
        fi
    done
}

case $1 in
add)
    if [[ -n $2 && -n $3 ]]; then
        add_option $2 $3 $4
    else
        echo "Usage: $0 {add|get} {GAME_ID} {OPTION}"
    fi
    ;;
get)
    if [[ -n $2 ]]; then
        get_option $2
    else
        echo "Usage: $0 {add|get} {GAME_ID}"
    fi
    ;;
*)
    echo "Usage: $0 {add|get} {GAME_ID}"
    ;;
esac
