set -U fish_greeting

function banner
  set COLS (tput cols)
  printf '\e[H\e[2J'
  figlet -f standard -w $COLS "linuxdeda.com"
  echo
end

banner; fastfetch; echo

bind \cl 'banner; commandline -f repaint'

