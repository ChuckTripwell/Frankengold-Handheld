FROM scratch AS base

COPY --from=ghcr.io/xeniameraki/xeniaos:latest / /

RUN pacman --noconfirm -Rns $( pacman -Qo /usr/lib/modules/$(uname -r) | awk '{print $5}' )


RUN systemd disable '*'

RUN rm -rf /usr/lib/systemd/system/*
RUN rm -rf /etc/systemd/system/*
RUN rm -rf /run/systemd/system/*
RUN rm -rf /usr/lib/systemd/user/*
RUN rm -rf /etc/systemd/user/*
RUN rm -rf /run/systemd/user/*

COPY --from=docker.io/cachyos/cachyos-v3:latest /usr/lib/systemd/system/ /usr/lib/systemd/system/
COPY --from=docker.io/cachyos/cachyos-v3:latest /etc/systemd/system/ /etc/systemd/system/
COPY --from=docker.io/cachyos/cachyos-v3:latest /run/systemd/system/ /run/systemd/system/
COPY --from=docker.io/cachyos/cachyos-v3:latest /usr/lib/systemd/user/ /usr/lib/systemd/user/
COPY --from=docker.io/cachyos/cachyos-v3:latest /etc/systemd/user/ /etc/systemd/user/
COPY --from=docker.io/cachyos/cachyos-v3:latest /run/systemd/user/ /run/systemd/user/

RUN rm -rf /etc/plymouth
RUN rm -rf /bin/*
RUN rm -rf /usr/bin/*
RUN rm -rf /usr/sbin/*
RUN rm -rf /sbin/*

RUN rm -rf /usr/share/xeniaos
#RUN rm -rf /etc/profile.d/aliases.sh
#RUN rm -rf /etc/os-release

COPY --from=docker.io/cachyos/cachyos-v3:latest /etc/profile.d/aliases.sh /etc/profile.d/aliases.sh
COPY --from=docker.io/cachyos/cachyos-v3:latest /bin /bin
COPY --from=docker.io/cachyos/cachyos-v3:latest /sbin /sbin
COPY --from=docker.io/cachyos/cachyos-v3:latest /usr/bin /usr/bin
COPY --from=docker.io/cachyos/cachyos-v3:latest /usr/sbin /usr/sbin
COPY --from=docker.io/cachyos/cachyos-v3:latest /etc/os-release /etc/os-release
COPY --from=docker.io/cachyos/cachyos-v3:latest /etc/environment > /etc/environment

RUN pacman -Syy --noconfirm 
RUN pacman -Suu --noconfirm

# fonts
#COPY --from=ghcr.io/xeniameraki/xeniaos:latest /usr/share/fonts /usr/share/fonts
#COPY --from=ghcr.io/xeniameraki/xeniaos:latest /usr/share/licenses /usr/share/licenses

RUN pacman -S --noconfirm --overwrite="*" --ask=4 \
    base linux-firmware dracut ostree systemd btrfs-progs \
    e2fsprogs xfsprogs binutils dosfstools skopeo dbus dbus-glib glib2 shadow \
    sudo bash bash-completion fastfetch btop jq rsync \
    distrobox docker podman ntfs-3g \
    firewalld amd-ucode intel-ucode \
    steam gamescope scx-scheds scx-manager \
    gnome-disk-utility \
    plasma-meta sddm \
    linux-cachyos-handheld \
    uupd bootc-git


COPY --from=ghcr.io/xeniameraki/xeniaos:latest /usr/libexec/xeniaos-group-fix /usr/libexec/os-group-fix
RUN systemctl enable os-group-fix
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
