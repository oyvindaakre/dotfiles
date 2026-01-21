#!/usr/bin/env bash

pkill waybar

if hyprctl monitors | grep -q "DP-2"; then
	waybar -c ~/.config/waybar/config_dp2.jsonc &
else
	waybar -c ~/.config/waybar/config_laptop.jsonc &
fi
