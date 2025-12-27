FROM scratch AS builder

COPY --from=ghcr.io/xeniameraki/xeniaos:latest / /os

RUN pacman --noconfirm -Rns $( pacman -Qqe | grep ^linux-cachyos )


#RUN systemd disable '*'

RUN rm -rf /os/usr/lib/systemd/system/*
RUN rm -rf /os/etc/systemd/system/*
RUN rm -rf /os/run/systemd/system/*
RUN rm -rf /os/usr/lib/systemd/user/*
RUN rm -rf /os/etc/systemd/user/*
RUN rm -rf /os/run/systemd/user/*

COPY --from=docker.io/cachyos/cachyos-v3:latest /usr/lib/systemd/system /os/usr/lib/systemd/system
COPY --from=docker.io/cachyos/cachyos-v3:latest /etc/systemd/system /os/etc/systemd/system
#COPY --from=docker.io/cachyos/cachyos-v3:latest /run/systemd/system /os/run/systemd/system
COPY --from=docker.io/cachyos/cachyos-v3:latest /usr/lib/systemd/user /os/usr/lib/systemd/user
COPY --from=docker.io/cachyos/cachyos-v3:latest /etc/systemd/user /os/etc/systemd/user
#COPY --from=docker.io/cachyos/cachyos-v3:latest /run/systemd/user /os/run/systemd/user

RUN rm -rf /os/etc/plymouth
RUN rm -rf /os/bin/*
RUN rm -rf /os/usr/bin/*
RUN rm -rf /os/usr/sbin/*
RUN rm -rf /os/sbin/*

RUN rm -rf /os/usr/share/xeniaos
#RUN rm -rf /os/etc/profile.d/aliases.sh
#RUN rm -rf /os/etc/os-release

COPY --from=docker.io/cachyos/cachyos-v3:latest /etc/profile.d/aliases.sh /os/etc/profile.d/aliases.sh
COPY --from=docker.io/cachyos/cachyos-v3:latest /bin /os/bin
COPY --from=docker.io/cachyos/cachyos-v3:latest /sbin /os/sbin
COPY --from=docker.io/cachyos/cachyos-v3:latest /usr/bin /os/os/usr/bin
COPY --from=docker.io/cachyos/cachyos-v3:latest /usr/sbin /os/usr/sbin
COPY --from=docker.io/cachyos/cachyos-v3:latest /etc/os-release /os/etc/os-release
COPY --from=docker.io/cachyos/cachyos-v3:latest /etc/environment > /os/etc/environment

RUN pacman -Syy --noconfirm 
RUN pacman -Suu --noconfirm

# fonts
#COPY --from=ghcr.io/xeniameraki/xeniaos:latest /usr/share/fonts /os/usr/share/fonts
#COPY --from=ghcr.io/xeniameraki/xeniaos:latest /usr/share/licenses /os/usr/share/licenses

RUN pacman -S --root /os/ --noconfirm --overwrite="*" --ask=4 \
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


COPY --from=ghcr.io/xeniameraki/xeniaos:latest /usr/libexec/xeniaos-group-fix /os/usr/libexec/os-group-fix
RUN systemctl enable os-group-fix
RUN systemctl enable uupd.timer
RUN systemctl enable sddm

# kernel
RUN pacman -S --root /os/ --noconfirm --overwrite="*" --ask=4 \
    linux-cachyos-deckify

FROM scratch AS final
COPY --from=builder /os/ /

RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

RUN bootc container lint
