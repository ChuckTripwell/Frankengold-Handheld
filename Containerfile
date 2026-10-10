FROM docker.io/cachyos/cachyos-v3:latest AS base

ENV DRACUT_NO_XATTR=1

RUN grep "= */var" /etc/pacman.conf | sed "/= *\/var/s/.*=// ; s/ //" | xargs -n1 sh -c 'mkdir -p "/usr/lib/sysimage/$(dirname $(echo $1 | sed "s@/var/@@"))" && \
mv -v "$1" "/usr/lib/sysimage/$(echo "$1" | sed "s@/var/@@")"' '' && \
    sed -i -e "/= *\/var/ s/^#//" -e "s@= */var@= /usr/lib/sysimage@g" -e "/DownloadUser/d" /etc/pacman.conf

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

RUN mkdir -p /sysroot && chmod 0755 /sysroot

RUN mkdir -p /etc/ostree && \
    echo -e "[composefs]\nenabled = yes" > /etc/ostree/prepare-root.conf

RUN mkdir -p /usr/lib/ostree && \
    mkdir -p /boot/ostree && \
    mkdir -p /etc/ostree

RUN mkdir -p /etc/dracut.conf.d && \
    printf 'hostonly=no\nadd_dracutmodules+=" ostree "\n' > /etc/dracut.conf.d/bootc.conf

RUN cp /etc/pacman.conf /etc/pacman.conf.bak && \
    sed -i 's/^#*SigLevel.*/SigLevel = Never/' /etc/pacman.conf && \
    BOOTC_URL=$(curl -s https://builds.garudalinux.org/repos/chaotic-aur/x86_64/ | grep -oE 'href="bootc-[0-9][^"]*x86_64\.pkg\.tar\.zst"' | sed 's/href="//;s/"//' | tail -n 1) && \
    pacman -U --noconfirm "https://builds.garudalinux.org/repos/chaotic-aur/x86_64/${BOOTC_URL}" && \
    mv /etc/pacman.conf.bak /etc/pacman.conf

#RUN KERNEL_VERSION=$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)") && \
#    depmod -a "$KERNEL_VERSION" && \
#    dracut --force --no-hostonly --add "ostree" --zstd --kver "$KERNEL_VERSION" "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"

#RUN : > /etc/fstab

#RUN ln -s /dev/null /usr/lib/systemd/system-generators/systemd-remount-fs-generator

RUN git clone --depth=1 https://github.com/Zeglius/media-automount-generator /tmp/media-automount-generator && \
    cd /tmp/media-automount-generator && \
    ./install.sh && \
    rm -rf /tmp/media-automount-generator

RUN echo -e '[zram0]\nzram-size = min(ram, 8192)' > /usr/lib/systemd/zram-generator.conf
RUN echo -e 'enable systemd-resolved.service' > /usr/lib/systemd/system-preset/91-resolved-default.preset
RUN echo -e 'L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf' > /usr/lib/tmpfiles.d/resolved-default.conf
RUN systemctl preset systemd-resolved.service


RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

RUN rm -rf /home/build/.cache/* && \
    rm -rf \
        /tmp/* \
        /var/cache/pacman/pkg/* && \
    pacman -Rns --noconfirm git

# Necessary for general behavior expected by image-based systems
RUN sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd" && \
    rm -rf /boot /home /root /usr/local /srv /opt /mnt /var /usr/lib/sysimage/log /usr/lib/sysimage/cache/pacman/pkg && \
    mkdir -p /sysroot /boot /usr/lib/ostree /var && \
    ln -sT sysroot/ostree /ostree && ln -sT var/roothome /root && ln -sT var/srv /srv && ln -sT var/opt /opt && ln -sT var/mnt /mnt && ln -sT var/home /home && ln -sT ../var/usrlocal /usr/local && \
    echo "$(for dir in opt home srv mnt usrlocal ; do echo "d /var/$dir 0755 root root -" ; done)" | tee -a "/usr/lib/tmpfiles.d/bootc-base-dirs.conf" && \
    printf "d /var/roothome 0700 root root -\nd /run/media 0755 root root -" | tee -a "/usr/lib/tmpfiles.d/bootc-base-dirs.conf" && \
    printf '[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n' | tee "/usr/lib/ostree/prepare-root.conf"


LABEL ostree.bootable=1
LABEL containers.bootc=1
RUN bootc container lint || bootc -h
