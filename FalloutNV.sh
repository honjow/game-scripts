#!/bin/bash

steam_id="22380"

options="bash -c 'exec \"\${@/FalloutNVLauncher.exe/FalloutNV.exe}\"' -- %command%"

# get current game options
current_options=$(./steam_options.py get $steam_id)
echo "current options: $current_options"

./steam_options.py set "$steam_id" "$options"
current_options=$(./steam_options.py get $steam_id)
echo ">> current options: [$current_options]"