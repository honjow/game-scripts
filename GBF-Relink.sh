#!/bin/bash

# GBFRelinkFix

git_url="https://github.com/Lyall/GBFRelinkFix.git"
api_url="https://api.github.com/repos/Lyall/GBFRelinkFix/releases/latest"

game_dir="$HOME/.local/share/Steam/steamapps/common/Granblue Fantasy Relink"
steam_id="881020"

options='WINEDLLOVERRIDES="winmm=n,b"'

temp_dir=$(mktemp -d)

# Get the latest release from the GitHub API
latest_release=$(curl -s $api_url | grep "browser_download_url" | cut -d : -f 2,3 | tr -d \")

# Download the latest release
curl -L $latest_release -o $temp_dir/GBFRelinkFix.zip

# Unzip the release
unzip -o $temp_dir/GBFRelinkFix.zip -d "$temp_dir/GBFRelinkFix"

# copy the files to the game directory
cp -r $temp_dir/GBFRelinkFix/* "${game_dir}"

# get current game options
current_options=$(./option.sh get $steam_id)
echo "current options: $current_options"

./option.sh add "$steam_id" "$options" 1
current_options=$(./option.sh get $steam_id)
echo ">> current options: $current_options"

