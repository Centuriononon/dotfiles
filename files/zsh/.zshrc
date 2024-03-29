#================> Oh-my-zsh
# Path to your oh-my-zsh installation. 
export ZSH="$HOME/.config/zsh/ohmyzsh"

#================> Exports
# export BROWSER="/var/lib/flatpak/app/com.brave.Browser/x86_64/stable/active/files/brave" 
export BROWSER="com.brave.Browser.desktop" 

#================> Settings
# "minimal" is dark
ZSH_THEME="minimal"

# Using case-sensitive completion.
CASE_SENSITIVE="true"


#===============> Plugins
plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
  asdf
)

source $ZSH/oh-my-zsh.sh

#===============> Variables
_editor="nvim"
_polybar="hack"

#===============> Functions
# Runs programs separately 
fork() {
  sh -ic "($* &) &>/dev/null"
}

# Lolcat output
colorize() {
  if [ -t 1 ]; then
    "$@" | lolcat
  else
      "$@"
  fi
}

# Intro
say_hello() {
cat << 'END'
             ____                      ,
            /---.'.__             ____//
                 '--.\           /.---' 
            _______  \\         //      
          /.------.\  \|      .'/  ______ 
         //  ___  \ \ ||/|\  //  _/_----.\\__
        |/  /.-.\  \ \:|< >|// _/.'..\\   '--'
           //   \'. | \'.|.'/ /_/ /   \\  
          //     \ \_\/\" ' ~\-'.-'    \\   
         //       '-._| :H: |'-.__      \\
        //           (/'==='\)'-._\     ||  
        ||                        \\    \|
        ||                         \\    '
        |/             _            \\
  _ __  ___ _   _  ___| |__   ___   ||
 | '_ \/ __| | | |/ __| '_ \ / _ \  ||
 | |_) \__ | |_| | (__| | | | (_) | \|
 | .__/|___/\__, |\___|_| |_|\___/   '
 |_|        |___/                           

END
}


#===============> Aliases 
# Editor
alias v="${_editor}"

# Cfg
alias zsh_cfg="${_editor} ~/.config/zsh/.zshrc"
alias nvim_cfg="${_editor} ~/.config/nvim/init.lua"
alias bspwm_cfg="${_editor} ~/.config/bspwm/bspwmrc"
alias sxhkd_cfg="${_editor} ~/.config/sxhkd/sxhkdrc"
alias polybar_cfg="${_editor} ~/.config/polybar/${_polybar}/config.ini"
alias picom_cfg="${_editor} ~/.config/picom/picom.conf"
alias zathura_cfg="${_editor} ~/.config/zathura/zathurarc"

# Power Profiles
alias power_l="powerprofilesctl set power-saver"
alias power_m="powerprofilesctl set balanced"
alias power_t="powerprofilesctl set performance"
alias power="powerprofilesctl get"

# Helpers
alias polybar_start='fork "~/.config/polybar/launch.sh --${_polybar}"'
alias switch_hdmi='xrandr --output eDP-1 --off --output HDMI-1 --mode 1920x1080 --pos 0x0 --rotate normal eDP-1'
alias plug_hdmi='xrandr --output HDMI-2 --auto --right-of eDP1'
alias unplug_hdmi='xrandr --output HDMI-2 --off'

# Resolution
alias scale_1="xrandr --output eDP-1 --mode 1920x1080 --scale 1x1"
alias scale_1-2="xrandr --output eDP-1 --mode 1600x900 --scale 1.2x1.2"
alias scale_1-5="xrandr --output eDP-1 --mode 1280x720 --scale 1.5x1.5"

# Change Directory
alias cd_trash='cd ~/.local/share/Trash/files'

# Notes
_notes='~/.config/tmp_notes'
alias nt="${_notes}/make-note.sh"
alias nt_dl="${_notes}/delete-note.sh"
alias nt_mg="${_notes}/merge-notes.sh"
alias nt_ls="${_notes}/list-notes.sh"

# Programs
alias screenshot='fork "maim -o --select | xclip -selection clipboard -t image/png"'
alias telegram='fork "flatpak run org.telegram.desktop"'
alias brave='fork "flatpak run com.brave.Browser"'
alias obsidian='fork "flatpak run md.obsidian.Obsidian"'
alias discord='fork "flatpak run com.discordapp.Discord --no-sandbox"'
alias steam='fork "flatpak run com.valvesoftware.Steam"'
alias httpie-app='fork "/home/Centurion/Documents/Soft/HTTPie-2023.3.6.AppImage"'
alias bruno='fork "bruno"'
alias whatsapp='fork "flatpak run com.github.eneshecan.WhatsAppForLinux"'

# Bluetooth
alias conn_jbl="bluetoothctl connect 68:59:32:01:38:A6"
alias conn_keyboard="bluetoothctl connect EA:6E:5C:75:A7:67"

#==============> Start
# Hello text
if [ $(power) = "performance" ]; then                                      
  colorize say_hello
else
  say_hello
fi


