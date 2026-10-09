FROM quay.io/centos/centos:stream9 AS bootc-source
RUN dnf install -y bootc ostree

FROM cachyos/cachyos-v3:latest

COPY --from=bootc-source /usr/bin/bootc /usr/bin/bootc
COPY --from=bootc-source /usr/lib64/libostree* /usr/lib64/
COPY --from=bootc-source /usr/bin/ostree /usr/bin/ostree

RUN pacman-key --init && \
    pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key F3B607488DB35A47 && \
    pacman -Sy --noconfirm && \
    pacman -S --needed --noconfirm cachyos-keyring cachyos-mirrorlist cachyos-v3-mirrorlist cachyos-hooks && \
    pacman -Syu --noconfirm && \
    pacman -S --needed --noconfirm \
    glib2 \
    openssl \
    util-linux \
    systemd \
    dracut \
    linux-cachyos-deckify \
    cachyos-settings \
    gamescope \
    gamescope-session-steam \
    steam \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    wireplumber \
    networkmanager \
    mesa \
    lib32-mesa \
    vulkan-radeon \
    lib32-vulkan-radeon \
    vulkan-intel \
    lib32-vulkan-intel \
    alsa-utils \
    flatpak

RUN mkdir -p /etc/dracut.conf.d && \
    echo 'add_dracutmodules+=" ostree "' > /etc/dracut.conf.d/ostree.conf && \
    kernel_version=$(ls /lib/modules | head -n1) && \
    dracut --force --kver "$kernel_version"

LABEL containers.bootc="1"
LABEL ostree.bootable="1"

CMD ["/sbin/init"]
