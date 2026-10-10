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
    flatpak

# Install bootc last in its own isolated section with temporary signature bypass
RUN cp /etc/pacman.conf /etc/pacman.conf.bak && \
    sed -i 's/^#*SigLevel.*/SigLevel = Never/' /etc/pacman.conf && \
    BOOTC_URL=$(curl -s https://builds.garudalinux.org/repos/chaotic-aur/x86_64/ | grep -oE 'href="bootc-[0-9][^"]*x86_64\.pkg\.tar\.zst"' | sed 's/href="//;s/"//' | tail -n 1) && \
    pacman -U --noconfirm "https://builds.garudalinux.org/repos/chaotic-aur/x86_64/${BOOTC_URL}" && \
    mv /etc/pacman.conf.bak /etc/pacman.conf

RUN git clone https://github.com/CachyOS/CachyOS-Handheld /tmp/CachyOS-Handheld && \
    rm -rf /tmp/CachyOS-Handheld/*README* && \
    cp -r /tmp/CachyOS-Handheld/* / && \
    rm -rf /tmp/CachyOS-Handheld

RUN mkdir -p /var/tmp
RUN printf 'hostonly=no\nadd_dracutmodules+=" ostree "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      depmod -a "$KERNEL_VERSION" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION" "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

RUN rm -rf /usr/etc
LABEL ostree.bootable=1
LABEL containers.bootc=1
RUN bootc container lint || bootc -h
