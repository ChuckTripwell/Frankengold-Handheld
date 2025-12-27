FROM docker.io/cachyos/cachyos-v3:latest AS builder
ENV DRACUT_NO_XATTR=1

#COPY --from=docker.io/cachyos/cachyos-v3:latest / /

# fonts
COPY --from=ghcr.io/ublue-os/bazzite-deck:latest /usr/share/fonts /usr/share/fonts
COPY --from=ghcr.io/ublue-os/bazzite-deck:latest /usr/share/licenses /usr/share/licenses

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
    uupd bootc-git

RUN systemctl enable uupd.timer
RUN systemctl enable sddm

# kernel
RUN pacman -S --noconfirm --overwrite="*" --ask=4 \
    linux-cachyos-deckify


RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

RUN bootc container lint
