FROM docker.io/cachyos/cachyos-v3:latest AS builder
ENV DRACUT_NO_XATTR=1

RUN echo -e '%wheel ALL=(ALL:ALL) ALL

# Chaotic AUR repo
RUN pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
RUN pacman-key --init && pacman-key --lsign-key 3056513887B78AEB
RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
RUN echo -e '[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
# Hec's Bootc repo
RUN pacman-key --recv-key 5DE6BF3EBC86402E7A5C5D241FA48C960F9604CB --keyserver keyserver.ubuntu.com
RUN pacman-key --lsign-key 5DE6BF3EBC86402E7A5C5D241FA48C960F9604CB
RUN echo -e '[bootc]\nSigLevel = Required\nServer=https://github.com/hecknt/arch-bootc-pkgs/releases/download/$repo' >> /etc/pacman.conf

RUN pacman -Sy --noconfirm

RUN pacman -Sy --noconfirm --overwrite="*" --ask=4 \
    base linux-firmware dracut ostree systemd btrfs-progs \
    e2fsprogs xfsprogs binutils dosfstools skopeo dbus dbus-glib glib2 shadow \
    sudo bash bash-completion fastfetch btop jq rsync \
    distrobox docker podman ntfs-3g \
    firewalld amd-ucode intel-ucode \
    steam gamescope scx-scheds scx-manager \
    gnome-disk-utility \
    plasma-meta sddm \
    cachyos-handheld \
    uupd bootc flatpak-git

RUN systemctl enable uupd.timer
RUN systemctl enable sddm

# kernel
RUN pacman -S --noconfirm --overwrite="*" --ask=4 \
    linux-cachyos-deckify

# Set vm.max_map_count for stability/improved gaming performance
# https://wiki.archlinux.org/title/Gaming#Increase_vm.max_map_count
RUN echo -e "vm.max_map_count = 2147483642" > /etc/sysctl.d/80-gamecompatibility.conf

# fonts
COPY --from=ghcr.io/ublue-os/bazzite-deck:latest /usr/share/fonts /usr/share/fonts
COPY --from=ghcr.io/ublue-os/bazzite-deck:latest /usr/share/licenses /usr/share/licenses

RUN echo -e '[zram0]\nzram-size = min(ram, 8192)' > /usr/lib/systemd/zram-generator.conf
RUN echo -e 'enable systemd-resolved.service' > /usr/lib/systemd/system-preset/91-resolved-default.preset
RUN echo -e 'L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf' > /usr/lib/tmpfiles.d/resolved-default.conf
RUN systemctl preset systemd-resolved.service



# This fixes a user/groups error with rebasing from other problematic images.
# FIXME Do NOT remove until fixed upstream or fixed universally. Updating with new fix also fine. Script created by Tulip.
RUN mkdir -p /usr/lib/systemd/system-preset /usr/lib/systemd/system
RUN echo -e '#!/bin/sh\ncat /usr/lib/sysusers.d/*.conf | grep -e "^g" | grep -v -e "^#" | awk "NF" | awk '\''{print $2}'\'' | grep -v -e "wheel" -e "root" -e "sudo" | xargs -I{} sed -i "/{}/d" $1' > /usr/libexec/xeniaos-group-fix
RUN chmod +x /usr/libexec/xeniaos-group-fix
RUN echo -e '[Unit]\n\
Description=Fix groups\n\
Wants=local-fs.target\n\
After=local-fs.target\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/libexec/xeniaos-group-fix /etc/group\n\
ExecStart=/usr/libexec/xeniaos-group-fix /etc/gshadow\n\
ExecStart=systemd-sysusers\n\
[Install]\n\
WantedBy=default.target multi-user.target' > /usr/lib/systemd/system/os-group-fix.service

RUN echo -e "enable os-group-fix.service" > /usr/lib/systemd/system-preset/01-os-group-fix.preset

# System services (Machine Boot level)
RUN systemctl enable NetworkManager.service \
    tuned.service \
    tuned-ppd.service \
    firewalld.service \
    os-group-fix.service \



RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

RUN bootc container lint
