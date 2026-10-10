FROM docker.io/alpine/git:latest AS ctx

RUN cd /
RUN git clone --depth 1 https://github.com/bootcrew/mono
RUN mv /mono/shared /







FROM docker.io/cachyos/cachyos-v3:latest AS base

FROM base AS builder

RUN pacman -Syu --noconfirm make git rust go-md2man ostree glibc pkgconf

WORKDIR /home/build
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/shared/build.sh

FROM base AS system

COPY --from=builder /output /

# Move everything from `/var` to `/usr/lib/sysimage` so behavior around pacman remains the same on `bootc usroverlay`'d systems
RUN grep "= */var" /etc/pacman.conf | sed "/= *\/var/s/.*=// ; s/ //" | xargs -n1 sh -c 'mkdir -p "/usr/lib/sysimage/$(dirname $(echo $1 | sed "s@/var/@@"))" && mv -v "$1" "/usr/lib/sysimage/$(echo "$1" | sed "s@/var/@@")"' '' && \
    sed -i -e "/= *\/var/ s/^#//" -e "s@= */var@= /usr/lib/sysimage@g" -e "/DownloadUser/d" /etc/pacman.conf

RUN pacman -Syu --noconfirm

RUN pacman -Sy --noconfirm base bubblewrap dracut linux-cachyos-deckify linux-firmware ostree btrfs-progs e2fsprogs xfsprogs dosfstools skopeo dbus dbus-glib glib2 ostree shadow openssh && pacman -S --clean --noconfirm

RUN systemctl enable systemd-networkd systemd-resolved systemd-timesyncd sshd && \
    systemctl mask systemd-firstboot.service

RUN echo "uninitialized" > /etc/machine-id && \
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime

RUN printf '[Match]\nType=ether\n\n[Network]\nDHCP=yes\n' \
    > /usr/lib/systemd/network/20-wired.network

RUN printf 'L! /etc/resolv.conf - - - - /run/systemd/resolve/stub-resolv.conf\n' \
    > /usr/lib/tmpfiles.d/resolv-conf.conf

RUN --mount=type=tmpfs,dst=/tmp --mount=type=tmpfs,dst=/root \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/shared/initramfs.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd" && \
    /ctx/shared/bootc-rootfs.sh

RUN sed -i '/^\[options\]/a DisableSandboxNetwork' /etc/pacman.conf

RUN pacman-key --init && \
    pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key F3B607488DB35A47 && \
    pacman -Sy --noconfirm && \
    pacman -S --needed --noconfirm cachyos-keyring cachyos-mirrorlist cachyos-v3-mirrorlist cachyos-hooks && \
    pacman -Syu --noconfirm && \
    pacman -S --needed --noconfirm \
    sudo \        
    git \
    podman \
    util-linux \
    systemd \
    dracut \
    ostree \
    libselinux \
    linux-cachyos-deckify \
    steam-powerbuttond-git \
    cachyos-settings \
    gamescope \
    gamescope-session-cachyos \
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
    flatpak \
    zram-generator
RUN pacman -S --clean --noconfirm



LABEL ostree.bootable=1
LABEL containers.bootc=1
RUN bootc container lint || bootc -h
