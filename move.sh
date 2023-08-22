#!/bin/bash

PROCESS=$(tput setaf 3)
SUCCESS=$(tput setaf 2)
ERROR=$(tput setaf 1)
_RESET=$(tput sgr0)

user="Centurion"
user_dir="/home/$user"

workdir="$user_dir/dotfiles"
files="$workdir/files"

config_names=("polybar" "zsh" "sxhkd" "bspwm" "nvim" "picom")

polybar_sources=("$user_dir/.config/polybar/hack")
zsh_sources=("$user_dir/.config/zsh/.zshrc")
sxhkd_sources=("$user_dir/.config/sxhkd/sxhkdrc")
bspwm_sources=("$user_dir/.config/bspwm/bspwmrc")
nvim_sources=("$user_dir/.config/nvim/init.lua")
picom_sources=("$user_dir/.config/picom")

rm -r "$files"
mkdir "$files"
cd "$workdir"

echo "${PROCESS}Validation sources..."
for cfg_name in "${config_names[@]}"; do
  sources_var="${cfg_name}_sources"
  eval sources=\${$sources_var[@]}
  
  # Validating the sources
  for src in "${sources[@]}"; do
    if [[ ! -e "$src" ]]; then
      echo "${ERROR}Not existing source: $src"
      exit 1
    fi
    
    if [ ! -f "$src" ] && [ ! -d "$src" ]; then
      echo "${ERROR}Invalid source: $src; must be: file, directory."
      exit 1
    fi

    if [ ! -r "$src" ]; then
      echo "${ERROR}Have no access to read source: $src" 
      exit 1
    fi
  done
done

echo "${SUCCESS}Validated sources successfuly.${_RESET}"

for cfg_name in "${config_names[@]}"; do
  echo "${PROCESS}Moving sources of $cfg_name...${_RESET}" 
  
  sources_var="${cfg_name}_sources"
  eval sources=\${$sources_var[@]}
  sources_len=${#sources[@]}
  dir="$files/$cfg_name"
	
  mkdir "$dir"

  # Resourcing
  for src in "${sources[@]}"; do
    src_name=$(basename "$src")

    if [ "$sources_len" -eq 1 ] && [ "$cfg_name" == "$src_name" ] ; then
      cp -r "$src" "$dir"
    else
      cp -r "$src" "$dir/$src_name" 
    fi

    if [ $? -eq 1 ]; then
      echo "${ERROR}Could not move source: $src"
    else
      echo "${SUCCESS}Moved source: $src${_RESET}"
    fi
  done
done

echo "${PROCESS}Dedicating sources to default user.${_RESET}"
chown -R "$user" "$files"
chmod -R u+rwx "$files"
