##################################################################################\\
################################################################################## # #
####                        this is just an experiment                         ### # #
################################################################################## # #
###             a complete image will be published every week.                 ### # #
################################################################################## # #
################################################################################## # #
 #                                                                                ###
  ################################################################################ #


FROM docker.io/cachyos/cachyos-v3:latest AS final

ENV DRACUT_NO_XATTR=1

########################################################################################################################################
# 
########################################################################################################################################

# Move everything from `/var` to `/usr/lib/sysimage` so behavior around pacman remains the same on `bootc usroverlay`'d systems
RUN grep "= */var" /etc/pacman.conf | sed "/= *\/var/s/.*=// ; s/ //" | xargs -n1 sh -c 'mkdir -p "/usr/lib/sysimage/$(dirname $(echo $1 | sed "s@/var/@@"))" && \
mv -v "$1" "/usr/lib/sysimage/$(echo "$1" | sed "s@/var/@@")"' '' && \
    sed -i -e "/= *\/var/ s/^#//" -e "s@= */var@= /usr/lib/sysimage@g" -e "/DownloadUser/d" /etc/pacman.conf

# Set it up such that pacman is always cleaned after installs
RUN echo -e "[Trigger]\n\
Operation = Install\n\
Operation = Upgrade\n\
Type = Package\n\
Target = *\n\
\n\
[Action]\n\
Description = Cleaning up package cache...\n\
Depends = coreutils\n\
When = PostTransaction\n\
Exec = /usr/bin/rm -rf /var/cache/pacman/pkg" > /usr/share/libalpm/hooks/package-cleanup.hook

# force refresh
RUN curl https://raw.githubusercontent.com/CachyOS/CachyOS-PKGBUILDS/master/cachyos-mirrorlist/cachyos-mirrorlist -o /etc/pacman.d/cachyos-mirrorlist
RUN pacman -Syy --needed --overwrite "*" --noconfirm cachyos-keyring cachyos-mirrorlist cachyos-v3-mirrorlist cachyos-v4-mirrorlist cachyos-hooks archlinux-keyring pacman-mirrorlist
RUN pacman -Syy --noconfirm

# Initialize the database
RUN pacman -Syu --noconfirm

# Use the Arch mirrorlist that will be best at the moment for both the containerfile and user too!
#RUN pacman -Sy --noconfirm reflector


# Base packages \ Linux Foundation \ Foss is love, foss is life! We split up packages by category for readability, debug ease, and less dependency trouble
RUN pacman -S --noconfirm --ask=4 base dracut linux-firmware ostree systemd btrfs-progs e2fsprogs xfsprogs binutils dosfstools skopeo dbus dbus-glib glib2 shadow jq crun firewalld tuned tuned-ppd networkmanager polkit sudo


# Pipewire
#RUN pacman -S --noconfirm pipewire pipewire-pulse pipewire-zeroconf pipewire-ffado pipewire-libcamera sof-firmware wireplumber alsa-firmware lib32-pipewire pipewire-audio linux-firmware-intel

# Network / VPN / SMB / storage
#RUN pacman -S --noconfirm libmtp nss-mdns samba smbclient networkmanager firewalld udiskie udisks2

##############################################################################################################################################
# 
##############################################################################################################################################

RUN pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com

RUN pacman-key --init && pacman-key --lsign-key 3056513887B78AEB

RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm

RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm

RUN echo -e '[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf

RUN pacman -Sy --noconfirm

RUN pacman -S --noconfirm \
    chaotic-aur/bootc chaotic-aur/flatpak-git

#RUN pacman -S --noconfirm --needed --overwrite="*" $(curl -L https://iso.builds.garudalinux.org/iso/latest/garuda/kde-lite/latest.pkgs.txt | awk '{print $1}')

RUN curl -L https://iso.builds.garudalinux.org/iso/latest/garuda/kde-lite/latest.pkgs.txt \
  | awk '{print $1}' \
  | grep -v 'garuda' \
  | grep -Ev '^(linux|linux-zen|linux-lts|mkinitcpio|nvidia|snapper|linux-zen-headers)$' \
  > /tmp/pkglist
RUN pacman -S --noconfirm --needed --overwrite="*" $(cat /tmp/pkglist)


RUN pacman -Rns --noconfirm --ask=4 linux-zen
RUN pacman -S --noconfirm --needed --overwrite="*" --ask=4 linux-cachyos-deckify linux-cachyos-deckify-headers amd-ucode intel-ucode
RUN pacman -S --noconfirm --needed --overwrite="*" --ask=4 podman docker distrobox fastfetch gamescope steam scx-scheds scx-manager ptyxis
RUN pacman -S --noconfirm --needed --overwrite="*" --ask=4 cachyos-handheld

#######################################################################################################################################################
# 
#######################################################################################################################################################

RUN mkdir -p /usr/share/flatpak/preinstall.d/

# Bazaar | Get most of your software here, flatpaks that are easy to install and use~
RUN echo -e "[Flatpak Preinstall io.github.kolunmi.Bazaar]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Bazaar.preinstall

# Elisa | Music player~
RUN echo -e "[Flatpak Preinstall org.kde.elisa]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Elisa.preinstall

# Ark | For unzipping files and file compression!
RUN echo -e "[Flatpak Preinstall org.kde.ark]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Ark.preinstall

# Faugus Launcher | This is fantastic for using windows software on linux
RUN echo -e "[Flatpak Preinstall io.github.faugus.faugus-launcher]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/FaugusLauncher.preinstall

# Kate | Writing documents~ Also can act as an IDE/development environment interestingly!
RUN echo -e "[Flatpak Preinstall org.kde.kate]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Kate.preinstall

# Warehouse | Manage your flatpak apps, delete whatever you don"t need/use/want! It's YOUR computer.
RUN echo -e "[Flatpak Preinstall io.github.flattool.Warehouse]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Warehouse.preinstall

# Gear Lever | Manage appimages!
RUN echo -e "[Flatpak Preinstall it.mijorus.gearlever]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/GearLever.preinstall

# Haruna | Watch video files! I actually personally like this better than VLC Media Player, nicer look/featureset
RUN echo -e "[Flatpak Preinstall org.kde.haruna]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Haruna.preinstall

# Gwenview | View images!
RUN echo -e "[Flatpak Preinstall org.kde.gwenview]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Gwenview.preinstall

# Rclone Shuttle | Files storage and transfer. 
RUN echo -e "[Flatpak Preinstall io.github.pieterdd.RcloneShuttle]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/RcloneShuttle.preinstall

########################################################################################################################################
#
########################################################################################################################################

# All kindsa Sudo changes for ease and flavor
RUN echo -e '%wheel ALL=(ALL:ALL) ALL\n\
\n\
Defaults insults\n\
Defaults pwfeedback\n\
Defaults secure_path="/usr/local/bin:/usr/bin:/bin:/home/linuxbrew/.linuxbrew/bin"\n\
Defaults env_keep += "EDITOR VISUAL PATH"\n\
Defaults timestamp_timeout=0' > /etc/sudoers.d/xenias-sudo-quiver && \
    chmod 440 /etc/sudoers.d/xenias-sudo-quiver

# All kindsa Sudo changes for ease and flavor
RUN echo -e '%wheel ALL=(ALL:ALL) ALL\n\
\n\
Defaults insults\n\
Defaults pwfeedback\n\
Defaults secure_path="/usr/local/bin:/usr/bin:/bin:/home/linuxbrew/.linuxbrew/bin"\n\
Defaults env_keep += "EDITOR VISUAL PATH"\n\
Defaults timestamp_timeout=0' > /etc/sudoers.d/xenias-sudo-quiver && \
    chmod 440 /etc/sudoers.d/xenias-sudo-quiver


# Set up zram, this will help users not run out of memory. Fox will fix!
RUN echo -e '[zram0]\nzram-size = min(ram, 8192)' >> /usr/lib/systemd/zram-generator.conf
RUN echo -e 'enable systemd-resolved.service' >> usr/lib/systemd/system-preset/91-resolved-default.preset
RUN echo -e 'L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf' >> /usr/lib/tmpfiles.d/resolved-default.conf
RUN systemctl preset systemd-resolved.service

# Set vm.max_map_count for stability/improved gaming performance
# https://wiki.archlinux.org/title/Gaming#Increase_vm.max_map_count
RUN echo -e "vm.max_map_count = 2147483642" > /etc/sysctl.d/80-gamecompatibility.conf

# Automount ext4/btrfs drives, feel free to mount your own in fstab if you understand how to do so
# To turn off, run sudo ln -s /dev/null /etc/media-automount.d/_all.conf
RUN git clone --depth=1 https://github.com/Zeglius/media-automount-generator /tmp/media-automount-generator && \
    cd /tmp/media-automount-generator && \
    ./install.sh && \
    rm -rf /tmp/media-automount-generator



##############################################################################################################################################################################
# Section 7 - Systemd n Services
##############################################################################################################################################################################

# Systemd flatpak preinstall service. 
RUN echo -e '[Unit]\n\
Description=Preinstall Flatpaks\n\
After=network-online.target\n\
Wants=network-online.target\n\
ConditionPathExists=/usr/bin/flatpak\n\
Documentation=man:flatpak-preinstall(1)\n\
\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/bin/flatpak preinstall -y\n\
RemainAfterExit=true\n\
Restart=on-failure\n\
RestartSec=30\n\
\n\
StartLimitIntervalSec=600\n\
StartLimitBurst=3\n\
\n\
[Install]\n\
WantedBy=multi-user.target' > /usr/lib/systemd/system/flatpak-preinstall.service

# This fixes a user/groups error with rebasing from other problematic images.
# FIXME Do NOT remove until fixed upstream or fixed universally. Updating with new fix also fine. Script created by Tulip.
RUN mkdir -p /usr/lib/systemd/system-preset /usr/lib/systemd/system

RUN echo -e '#!/bin/sh\ncat /usr/lib/sysusers.d/*.conf | grep -e "^g" | grep -v -e "^#" | awk "NF" | awk '\''{print $2}'\'' | grep -v -e "wheel" -e "root" -e "sudo" | xargs -I{} sed -i "/{}/d" $1' > /usr/libexec/os-group-fix
RUN chmod +x /usr/libexec/os-group-fix
RUN echo -e '[Unit]\n\
Description=Fix groups\n\
Wants=local-fs.target\n\
After=local-fs.target\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/libexec/os-group-fix /etc/group\n\
ExecStart=/usr/libexec/os-group-fix /etc/gshadow\n\
ExecStart=systemd-sysusers\n\
[Install]\n\
WantedBy=default.target multi-user.target' > /usr/lib/systemd/system/os-group-fix.service

RUN echo -e "enable os-group-fix.service" > /usr/lib/systemd/system-preset/01-os-group-fix.preset

# System services (Machine Boot level)
RUN systemctl enable polkit.service \
    NetworkManager.service \
    tuned.service \
    tuned-ppd.service \
    firewalld.service \
    flatpak-preinstall.service \
    os-group-fix.service

########################################################################################################################################
# Section 8 - CachyOS settings | Since we have the CachyOS kernel, we gotta put it to good use ≽^•⩊•^≼ ################################
########################################################################################################################################

# Activate NTSync, wags my tail in your general direction
RUN echo -e 'ntsync' > /etc/modules-load.d/ntsync.conf

# CachyOS bbr3 Config Option
RUN echo -e 'net.core.default_qdisc=fq \n\
net.ipv4.tcp_congestion_control=bbr' > /etc/sysctl.d/99-bbr3.conf

########################################################################################################################################
# Section 10 - Final Bootc Setup
########################################################################################################################################

RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

RUN rm -rf /home/build/.cache/* && \
    rm -rf \
        /tmp/* \
        /var/cache/pacman/pkg/*

# Necessary for general behavior expected by image-based systems
RUN sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd" && \
    rm -rf /boot /home /root /usr/local /srv /var /usr/lib/sysimage/log /usr/lib/sysimage/cache/pacman/pkg && \
    mkdir -p /sysroot /boot /usr/lib/ostree /var && \
    ln -s sysroot/ostree /ostree && ln -s var/roothome /root && ln -s var/srv /srv && ln -s var/opt /opt && ln -s var/mnt /mnt && ln -s var/home /home && \
    echo "$(for dir in opt home srv mnt usrlocal ; do echo "d /var/$dir 0755 root root -" ; done)" | tee -a "/usr/lib/tmpfiles.d/bootc-base-dirs.conf" && \
    printf "d /var/roothome 0700 root root -\nd /run/media 0755 root root -" | tee -a "/usr/lib/tmpfiles.d/bootc-base-dirs.conf" && \
    printf '[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n' | tee "/usr/lib/ostree/prepare-root.conf"

RUN bootc container lint
