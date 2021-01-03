[ -e ~/.bashrc ] && source ~/.bashrc

# ---

export DISPLAY=0
export XAUTHORITY="$HOME/.Xauthority"

# unset DBUS_SESSION_BUS_ADDRESS
# unset SESSION_MANAGER

# Only start up X automatically on vt1
systemctl --user import-environment DISPLAY XAUTHORITY PATH
systemctl --user set-environment XDG_VTNR=1

echo "VTNR: $XDG_VTNR" >&2
echo "DISPLAY: $DISPLAY" >&2
echo "XAUTHORITY: $XAUTHORITY" >&2
echo "DBUS_SESSION_BUS_ADDRESS: $DBUS_SESSION_BUS_ADDRESS" >&2
echo "SESSION_MANAGER: $SESSION_MANAGER" >&2
echo "PATH: $PATH" >&2

# Run systemctl --user start xorg@0.socket to start, but ensure we are on a tty that matches
# the virtual terminal number that we requested

# ---

# [ "$(tty)" = /dev/tty1 ] && exec startx -- vt1 &> /dev/null
