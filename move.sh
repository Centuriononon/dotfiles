#!/bin/bash

workdir="/home/Centurion/dotfiles"
files="$workdir/files"

config_names=("polybar" "zsh" "sxhkd" "bspwm")

polybar_sources=("/home/Centurion/.config/polybar/hack")
zsh_sources=("/home/Centurion/.config/zsh/.zshrc")
sxhkd_sources=("/home/Centurion/.config/sxhkd/sxhkdrc")
bspwm_sources=("/home/Centurion/.config/bspwm/bspwmrc")

cd $workdir

for cfg_name in "${config_names[@]}"; do
	sources_var="${cfg_name}_sources"
	eval sources=\${$sources_var[@]}
	
	dir="$files/$cfg_name"
	
	# Creating directory for cfg
	mkdir -p "$dir"
	
	# Validating if all the sources are presented
	for src in "${sources[@]}"; do
		if [[ ! -e "$src" ]]; then
			echo "Not existing source: $src"
			exit 1
		fi
	done

	# Resourcing
	for src in "${sources[@]}"; do
		echo "Moving source: $src"

		src_name=$(basename "$src")
		cp -r "$src" "$dir/$src_name"
	done
done
