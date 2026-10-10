FROM docker.io/cachyos/cachyos-v3:latest AS base

RUN sed -i '/^#DisableSandboxNetwork/s/^#//' /etc/pacman.conf || echo "DisableSandboxNetwork" >> /etc/pacman.conf

RUN pacman-key --init && \
    pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key F3B607488DB35A47 && \
    pacman -Sy --noconfirm && \
    pacman -S --needed --noconfirm cachyos-keyring cachyos-mirrorlist cachyos-v3-mirrorlist cachyos-hooks && \
    pacman -Syu --noconfirm && \
    pacman -S --needed --noconfirm \
    git \
    base-devel \
    rust \
    cargo \
    pkgconf \
    glib2 \
    openssl \
    libselinux \
    util-linux \
    systemd \
    dracut \
    ostree \
    linux-cachyos-deckify \
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
    flatpak

# Build bootc natively from source: 100% dynamic linking against CachyOS toolchain
RUN git clone https://github.com/bootc-dev/bootc.git /tmp/bootc && \
    cd /tmp/bootc && \
    cargo build --release && \
    install -Dm755 target/release/bootc /usr/bin/bootc && \
    rm -rf /tmp/bootc

RUN git clone https://github.com/CachyOS/gamescope-session.git /tmp/gamescope-session && \
    cp -r /tmp/gamescope-session/usr/* /usr/ && \
    rm -rf /tmp/gamescope-session

RUN mkdir -p /var/tmp
RUN printf 'hostonly=no\nadd_dracutmodules+=" ostree "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      depmod -a "$KERNEL_VERSION" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION" "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

RUN rm -rf /usr/etc
LABEL ostree.bootable=1
LABEL containers.bootc=1
RUN bootc container lint || bootc -h
