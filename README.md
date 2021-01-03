# Xorg as a service

This is my attempt at getting `Xorg` to run as a user service, mostly following what I've found [here](https://wiki.archlinux.org/index.php/systemd/User#Xorg_as_a_systemd_user_service) and [here](https://github.com/gtmanfred/systemd-user).

At this point, I can get the `Xorg` server to start, and _apparently_ start things like `sxhkd` and `bspwm`, but it doesn't seem to work how it would if I use the `startx` route that I am trying to move away from.

# Version information

```
$ Xorg -version
X.Org X Server 1.20.9
X Protocol Version 11, Revision 0
Build Operating System:  5.8.7-200.fc32.x86_64
Current Operating System: Linux thiccpad 5.8.18-200.fc32.x86_64 #1 SMP Mon Nov 2 19:49:11 UTC 2020 x86_64
Kernel command line: BOOT_IMAGE=(hd0,gpt2)/vmlinuz-5.8.18-200.fc32.x86_64 root=/dev/mapper/fedora-root ro resume=/dev/mapper/fedora-swap rd.lvm.lv=fedora/root
rd.lvm.lv=fedora/swap quiet loglevel=3 nouveau.modeset=0 rd.plymouth=0 plymouth.enable=0
Build Date: 08 October 2020  12:00:00AM
Build ID: xorg-x11-server 1.20.9-1.fc32
Current version of pixman: 0.40.0
        Before reporting problems, check http://wiki.x.org
        to make sure that you have the latest version.
$ bspwm -version
0.9.9
$ sxhkd -version
0.6.1
$ systemctl --version
systemd 245 (v245.8-2.fc32)
+PAM +AUDIT +SELINUX +IMA -APPARMOR +SMACK +SYSVINIT +UTMP +LIBCRYPTSETUP +GCRYPT +GNUTLS +ACL +XZ +LZ4 +SECCOMP +BLKID +ELFUTILS +KMOD +IDN2 -IDN +PCRE2 defau
lt-hierarchy=unified
$ cat /etc/os-release
NAME=Fedora
VERSION="32 (Thirty Two)"
ID=fedora
VERSION_ID=32
VERSION_CODENAME=""
PLATFORM_ID="platform:f32"
PRETTY_NAME="Fedora 32 (Thirty Two)"
ANSI_COLOR="0;34"
LOGO=fedora-logo-icon
CPE_NAME="cpe:/o:fedoraproject:fedora:32"
HOME_URL="https://fedoraproject.org/"
DOCUMENTATION_URL="https://docs.fedoraproject.org/en-US/fedora/f32/system-administrators-guide/"
SUPPORT_URL="https://fedoraproject.org/wiki/Communicating_and_getting_help"
BUG_REPORT_URL="https://bugzilla.redhat.com/"
REDHAT_BUGZILLA_PRODUCT="Fedora"
REDHAT_BUGZILLA_PRODUCT_VERSION=32
REDHAT_SUPPORT_PRODUCT="Fedora"
REDHAT_SUPPORT_PRODUCT_VERSION=32
PRIVACY_POLICY_URL="https://fedoraproject.org/wiki/Legal:PrivacyPolicy"
```

# Setup

1. Set `Xwrapper` configuration:
```
$ cat /etc/X11/Xwrapper.config
allowed_users=anybody
needs_root_rights=yes
```
2. Setup various `systemd` units, see the files listed in the repository here.
3. Enable units:
```
$ command -v scu
alias scu='systemctl --user'
$ scu enable xorg@0.socket
$ scu enable bspwm.service
$ scu enable sxhkd.service
$ scu enable feh.service
$ which bspwm sxhkd feh
/usr/bin/bspwm
/usr/bin/sxhkd
/usr/bin/feh
$ scu list-unit-files
UNIT FILE                                     STATE     VENDOR PRESET
at-spi-dbus-bus.service                       static    disabled     
dbus-broker.service                           enabled   enabled      
dbus-daemon.service                           disabled  disabled     
dbus.service                                  enabled   disabled     
dirmngr.service                               static    disabled     
flatpak-oci-authenticator.service             static    disabled     
flatpak-portal.service                        static    disabled     
flatpak-session-helper.service                static    disabled     
glib-pacrunner.service                        static    disabled     
gpg-agent.service                             static    disabled     
grub-boot-success.service                     static    disabled     
p11-kit-client.service                        disabled  disabled     
p11-kit-server.service                        disabled  disabled     
pipewire.service                              disabled  disabled     
pulseaudio.service                            disabled  disabled     
run-r91d23f7d96fc4f6f9da6055bd8b3b364.service transient disabled     
sxhkd.service                                 enabled   disabled     
systemd-exit.service                          static    disabled     
systemd-tmpfiles-clean.service                static    disabled     
systemd-tmpfiles-setup.service                disabled  enabled      
xdg-desktop-portal-gtk.service                static    disabled     
xdg-desktop-portal.service                    static    disabled     
xdg-document-portal.service                   static    disabled     
xdg-permission-store.service                  static    disabled     
dbus.socket                                   enabled   enabled      
dirmngr.socket                                disabled  disabled     
gpg-agent-browser.socket                      disabled  disabled     
gpg-agent-extra.socket                        disabled  disabled     
gpg-agent-ssh.socket                          disabled  disabled     
gpg-agent.socket                              disabled  disabled     
p11-kit-server.socket                         disabled  disabled     
pipewire.socket                               enabled   enabled      
pulseaudio.socket                             enabled   enabled      
basic.target                                  static    disabled     
bluetooth.target                              static    disabled     
default.target                                static    disabled     
exit.target                                   static    disabled     
graphical-session-pre.target                  static    disabled     
graphical-session.target                      static    disabled     
paths.target                                  static    disabled     
printer.target                                static    disabled     
shutdown.target                               static    disabled     
smartcard.target                              static    disabled     
sockets.target                                static    disabled     
sound.target                                  static    disabled     
timers.target                                 static    disabled     
grub-boot-success.timer                       static    enabled      
systemd-tmpfiles-clean.timer                  disabled  enabled      
```
4. Reboot the system:
```
$ reboot
```

# Problems

At this point, I am greeted with a blank screen, with seemingly nothing being functional. Switching to `tty2`, I can look at the state of the system, where I do not see any `bspwm_0_0-socket` file, indicating that `bspwm` has actually started. However, I can run:
```
ps aux | grep -iE "bspwm|sxhkd"
```
and note that they are _both_ indeed running.

The journal shows a similar conclusion, as seen in [boot.log](boot.log), roughly [here](https://github.com/levouh/systemd/blob/27b61fc8459cd3cf5fc4e161f3f83a02776b113e/boot.log#L2135).

# Troubleshooting

## journal Xorg Warnings

Looking at the journal with:
```
journalctl -b -1 | grep -iE "(xorg.*(\(WW\)|\(EE\)))|(dbus)"
```

I can see that there are some warnings:

```
Jan 03 14:28:14 thiccpad Xorg[1778]: (WW) xf86OpenConsole: setpgid failed: Operation not permitted
Jan 03 14:28:14 thiccpad Xorg[1778]: (WW) xf86OpenConsole: setsid failed: Operation not permitted
Jan 03 14:28:14 thiccpad Xorg[1778]: (WW) Falling back to old probe method for fbdev
```

but I've not got much idea what to make of these. Googling leads to [here](https://bugs.freedesktop.org/show_bug.cgi?id=99003), but as far as I understand, the entire point is to run `Xorg` as a user? So why would:

>I fixed the problem xf86OpenConsole: setpgid failed: Operation not permitted by starting serverX with root privilege.

be involved here? Doesn't seem related to me.

## freedesktop.problems in journal

I see various things in the journal mentioning `freedesktop.problems@0.service`, however, I see the same thing when I go the `startx` route:

```
Jan 03 14:44:11 thiccpad systemd[1]: Created slice system-dbus\x2d:1.4\x2dorg.freedesktop.problems.slice.
Jan 03 14:44:11 thiccpad systemd[1]: Started dbus-:1.4-org.freedesktop.problems@0.service.
```

which does start `bspwm`, etc. successfully. This is done via setting up my `~/.bash_profile` like so:

```
$ cat ~/.bash_profile
[ "$(tty)" = /dev/tty1 ] && exec startx -- vt1 &> /dev/null
```

and like I said, works just fine, but is beside the point here.

## Looking at startx script

Looking at the provided `startx` script in `/usr/bin/startx`, there are places where it does:

```
...
unset DBUS_SESSION_BUS_ADDRESS
unset SESSION_MANAGER
...
```

so I've done similar in my `~/.bash_profile`:

```
export DISPLAY=0
export XAUTHORITY="$HOME/.Xauthority"

unset DBUS_SESSION_BUS_ADDRESS
unset SESSION_MANAGER

systemctl --user import-environment DISPLAY XAUTHORITY PATH DBUS_SESSION_BUS_ADDRESS SESSION_MANAGER
systemctl --user set-environment XDG_VTNR=1
```

but again, no success there.

## Comparing to a "successful" Xorg boot 

Here I say "successful" as this is not what I'm trying to do, but as you'd expect, it works. I mentioned before that for the successful method, I simply do:

```
$ cat ~/.bash_profile
[ "$(tty)" = /dev/tty1 ] && exec startx -- vt1 &> /dev/null
```

and all is fine and dandy. These logs are taken from `/var/log/Xorg.0.log` found via:

```
sudo updatedb
locate Xorg.0.log
```

and can be found [here](success.log). These are notably missing the _ERROR_ level logs from my attempts with `systemd`, noting:

```
Jan 03 14:28:14 thiccpad Xorg[1778]: (WW) xf86OpenConsole: setpgid failed: Operation not permitted
Jan 03 14:28:14 thiccpad Xorg[1778]: (WW) xf86OpenConsole: setsid failed: Operation not permitted
Jan 03 14:28:14 thiccpad Xorg[1778]: (WW) Falling back to old probe method for fbdev
```

which are **not** present in the successful logs. So, if I need to run as `root` to circumvent this, how do I run `Xorg` as a **user** service?

## systemd-logind

The journal also shows the following at _INFO_ level, so I presume it isn't important:

```
Jan 03 14:36:58 thiccpad Xorg[1829]: (II) systemd-logind: logind integration requires -keeptty and -keeptty was not provided, disabling logind integration
```

but I'm not really sure.
