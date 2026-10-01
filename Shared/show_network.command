#!/bin/zsh
echo 'Hardware ports:'
networksetup -listallhardwareports
echo 'Default route:'
route -n get default
echo 'Wi-Fi interface (often en0):'
ifconfig en0
