# Stage 1: Build bootc natively from official source using cargo
FROM cachyos/cachyos:latest AS builder

RUN pacman-key --init && \
    pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key F3B607488DB35A47 && \
    pacman -Sy --noconfirm && \
    pacman -S --needed --noconfirm cachyos-keyring cachyos-mirrorlist cachyos-v3-mirrorlist cachyos-hooks && \
    pacman -Syu --noconfirm && \
    pacman -S --needed --noconfirm base-devel git rust ostree glib2 openssl zstd go-md2man

RUN git clone https://github.com/bootc-dev/bootc.git /usr/src/bootc && \
    cd /usr/src/bootc && \
    cargo build --release && \
    install -Dm755 target/release/bootc /opt/bootc-build/usr/bin/bootc

# Stage 2: Runtime CachyOS Steam Deck bootc image
FROM cachyos/cachyos:latest

RUN pacman-key --init && \
    pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key F3B607488DB35A47 && \
    pacman -Sy --noconfirm && \
    pacman -S --needed --noconfirm cachyos-keyring cachyos-mirrorlist cachyos-v3-mirrorlist cachyos-hooks && \
    pacman -Syu --noconfirm && \
    pacman -S --needed --noconfirm \
    ostree \
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

COPY --from=builder /opt/bootc-build /

RUN mkdir -p /etc/dracut.conf.d && \
    echo 'add_dracutmodules+=" ostree "' > /etc/dracut.conf.d/ostree.conf && \
    kernel_version=$(ls /lib/modules | head -n1) && \
    dracut --force --kver "$kernel_version"

LABEL containers.bootc="1"
LABEL ostree.bootable="1"

CMD ["/sbin/init"]
