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
```

# Setup

1. Set `Xwrapper` configuration:
```
$ cat /etc/X11/Xwrapper.config
allowed_users=anybody
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

The journal shows a similar conclusion, as seen in [boot.log](boot.log).

# Troubleshooting

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

but I've not got much idea what to make of these. Googling the error leads to `systemd` _Github_ issues, but most are beyond anything that I understand at the moment.
