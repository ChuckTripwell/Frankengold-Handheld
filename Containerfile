FROM docker.io/cachyos/cachyos-v3:latest AS base

RUN sed -i '/^\[options\]/a DisableSandboxNetwork' /etc/pacman.conf

RUN pacman-key --init && \
    pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key F3B607488DB35A47 && \
    pacman -Sy --noconfirm && \
    pacman -S --needed --noconfirm cachyos-keyring cachyos-mirrorlist cachyos-v3-mirrorlist cachyos-hooks && \
    pacman -Syu --noconfirm && \
    pacman -S --needed --noconfirm \
        accountsservice \
        adobe-source-han-sans-cn-fonts \
        adobe-source-han-sans-jp-fonts \
        adobe-source-han-sans-kr-fonts \
        alacritty \
        alsa-firmware \
        alsa-plugins \
        alsa-utils \
        amd-ucode \
        ark \
        awesome-terminal-fonts \
        bash-completion \
        bcachefs-tools \
        bluedevil \
        bluez \
        bluez-hid2hci \
        bluez-libs \
        bluez-utils \
        breeze-gtk \
        btop \
        btrfs-progs \
        cachy-chroot \
        cachyos-calamares-deckify \
        cachyos-cli-installer-new \
        cachyos-fish-config \
        cachyos-handheld \
        cachyos-hello \
        cachyos-hooks \
        cachyos-keyring \
        cachyos-micro-settings \
        cachyos-mirrorlist \
        cachyos-rate-mirrors \
        cachyos-settings \
        cachyos-v3-mirrorlist \
        cachyos-v4-mirrorlist \
        cachyos-wallpapers \
        cachyos-zsh-config \
        cantarell-fonts \
        capitaine-cursors \
        char-white \
        chwd \
        ckbcomp \
        clonezilla \
        cloud-init \
        cpio \
        cpupower \
        cryptsetup \
        darkhttpd \
        dbus \
        dbus-glib \
        ddrescue \
        dhclient \
        dhcpcd \
        diffutils \
        discover \
        dmidecode \
        dmraid \
        dnsmasq \
        dnsutils \
        docker \
        dolphin \
        dosfstools \
        dracut \
        drm-info \
        duf \
        e2fsprogs \
        edk2-shell \
        efibootmgr \
        efitools \
        egl-wayland \
        espeak-ng \
        ethtool \
        exfatprogs \
        f2fs-tools \
        fastfetch \
        fatresize \
        ffmpegthumbnailer \
        ffmpegthumbs \
        findutils \
        flatpak \
        freetype2 \
        fsarchiver \
        fwupd \
        gamescope \
        gamescope-session-cachyos \
        git \
        glances \
        glib2 \
        gpart \
        gparted \
        gpm \
        gptfdisk \
        grsync \
        grub \
        gst-libav \
        gst-plugin-pipewire \
        gst-plugins-bad \
        gst-plugins-ugly \
        gwenview \
        haveged \
        hdparm \
        hwdetect \
        hwinfo \
        hyperv \
        imwheel \
        inetutils \
        inotify-tools \
        intel-ucode \
        intltool \
        inxi \
        iptables-nft \
        irssi \
        iwd \
        iw \
        jfsutils \
        kcalc \
        kate \
        kde-gtk-config \
        kdegraphics-thumbnailers \
        kdeconnect \
        kdeplasma-addons \
        kinfocenter \
        kio \
        kitty-terminfo \
        konsole \
        kscreen \
        kxkb2locale1 \
        kwallet-pam \
        kwalletmanager \
        ldns \
        less \
        lftp \
        lib32-mesa \
        lib32-vulkan-intel \
        lib32-vulkan-radeon \
        libdvdcss \
        libfido2 \
        libgsf \
        libopenraw \
        libplasma \
        libselinux \
        libusb-compat \
        libwnck3 \
        libxinerama \
        linux-atm \
        linux-cachyos-deckify \
        linux-cachyos-deckify-headers \
        linux-cachyos-deckify-nvidia-open \
        linux-cachyos-deckify-zfs \
        linux-firmware \
        linux-firmware-marvell \
        lsb-release \
        lsscsi \
        lvm2 \
        lynx \
        man-db \
        man-pages \
        mc \
        mdadm \
        meld \
        memtest86+ \
        memtest86+-efi \
        mesa \
        mesa-utils \
        micro \
        mkinitcpio \
        mkinitcpio-archiso \
        mkinitcpio-nfs-utils \
        mlocate \
        mobile-broadband-provider-info \
        modemmanager \
        mousetweaks \
        mtools \
        nano \
        nano-syntax-highlighting \
        nbd \
        ndisc6 \
        net-tools \
        networkmanager \
        networkmanager-openvpn \
        nfs-utils \
        nilfs-utils \
        nmap \
        noto-color-emoji-fontconfig \
        noto-fonts \
        noto-fonts-cjk \
        noto-fonts-emoji \
        nss-mdns \
        ntfs-3g \
        ntp \
        nvidia-utils \
        nvme-cli \
        openconnect \
        opendesktop-fonts \
        open-iscsi \
        openssh \
        open-vm-tools \
        openvpn \
        orca \
        os-prober \
        ostree \
        pacman-contrib \
        partclone \
        parted \
        partimage \
        partitionmanager \
        paru \
        pavucontrol \
        pcsclite \
        phonon-qt6-vlc \
        pipewire \
        pipewire-alsa \
        pipewire-jack \
        pipewire-pulse \
        pkgfile \
        plasma-browser-integration \
        plasma-desktop \
        plasma-firewall \
        plasma-integration \
        plasma-keyboard \
        plasma-login-manager \
        plasma-nm \
        plasma-pa \
        plasma-systemmonitor \
        plasma-thunderbolt \
        plasma-workspace \
        podman \
        polkit \
        polkit-kde-agent \
        poppler-glib \
        power-profiles-daemon \
        powerdevil \
        ppp \
        pptpclient \
        profile-sync-daemon \
        pv \
        python \
        python-defusedxml \
        python-packaging \
        qemu-guest-agent \
        qt6-wayland \
        realtime-privileges \
        rebuild-detector \
        reflector \
        ripgrep \
        rp-pppoe \
        rsync \
        rtkit \
        rxvt-unicode-terminfo \
        sdparm \
        sed \
        shadow \
        sg3_utils \
        skopeo \
        smartmontools \
        smbclient \
        sof-firmware \
        solid \
        spectacle \
        spice-vdagent \
        squashfs-tools \
        steam \
        steamdeck-firmware \
        sudo \
        syslinux \
        systemd \
        systemd-resolvconf \
        tcpdump \
        terminus-font \
        testdisk \
        tpm2-tss \
        traceroute \
        ttf-bitstream-vera \
        ttf-dejavu \
        ttf-liberation \
        ttf-meslo-nerd \
        ttf-opensans \
        udftools \
        unrar \
        unzip \
        upower \
        usb_modeswitch \
        usbmuxd \
        usbutils \
        util-linux \
        v4l-utils \
        vi \
        vim \
        virtualbox-guest-utils \
        vpnc \
        vulkan-intel \
        vulkan-radeon \
        wpa_supplicant \
        wget \
        wireplumber \
        wireless-regdb \
        wireless_tools \
        wvdial \
        xdg-desktop-portal \
        xdg-desktop-portal-kde \
        xdg-user-dirs \
        xdg-user-dirs-gtk \
        xdg-utils \
        xed \
        xf86-input-elographics \
        xf86-input-evdev \
        xf86-input-libinput \
        xf86-input-synaptics \
        xf86-input-vmmouse \
        xf86-input-void \
        xf86-video-amdgpu \
        xf86-video-fbdev \
        xf86-video-nouveau \
        xf86-video-qxl \
        xf86-video-vmware \
        xfprogs \
        xl2tpd \
        xorg-server \
        xorg-xdpyinfo \
        xorg-xinit \
        xorg-xinput \
        xorg-xkill \
        xorg-xrandr \
        xorg-xrdb \
        xsettingsd \
        xz \
        yad \
        zfs-utils
RUN pacman -S --clean --noconfirm

RUN mkdir -p /sysroot && chmod 0755 /sysroot

RUN mkdir -p /etc/ostree && \
    echo -e "[composefs]\nenabled = yes" > /etc/ostree/prepare-root.conf

RUN cp /etc/pacman.conf /etc/pacman.conf.bak && \
    sed -i 's/^#*SigLevel.*/SigLevel = Never/' /etc/pacman.conf && \
    BOOTC_URL=$(curl -s https://builds.garudalinux.org/repos/chaotic-aur/x86_64/ | grep -oE 'href="bootc-[0-9][^"]*x86_64\.pkg\.tar\.zst"' | sed 's/href="//;s/"//' | tail -n 1) && \
    pacman -U --noconfirm "https://builds.garudalinux.org/repos/chaotic-aur/x86_64/${BOOTC_URL}" && \
    mv /etc/pacman.conf.bak /etc/pacman.conf

#RUN git clone https://github.com/CachyOS/CachyOS-Handheld /tmp/CachyOS-Handheld && \
#    rm -rf /tmp/CachyOS-Handheld/*EADME.* && \
#    cp -r /tmp/CachyOS-Handheld/* / && \
#    rm -rf /tmp/CachyOS-Handheld

RUN mkdir -p /var/tmp
RUN printf 'hostonly=no\nadd_dracutmodules+=" ostree "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      depmod -a "$KERNEL_VERSION" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION" "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

RUN rm -rf /usr/etc
LABEL ostree.bootable=1
LABEL containers.bootc=1
RUN bootc container lint || bootc -h
