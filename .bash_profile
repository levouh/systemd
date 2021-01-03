export DISPLAY=0
export XAUTHORITY="$HOME/.Xauthority"

systemctl --user import-environment DISPLAY XAUTHORITY
systemctl --user set-environment XDG_VTNR=1
