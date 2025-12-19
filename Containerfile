FROM docker.io/cachyos/cachyos-v3:latest AS final

ENV DRACUT_NO_XATTR=1

# ✩₊˚.⋆☾𓃦☽⋆⁺₊✧ Index
# Section 1 - Package Installs
# Section 2 - Package List
# Section 3 - Chaotic AUR / AUR
# Section 4 - Flatpaks preinstalls
# Section 5 - Linux OS Stuffs
# Section 6 - Set up Brew
# Section 7 - Systemd n Services
# Section 8 - CachyOS Settings
# Section 9 - Niri/Chezmoi/DMS
# Section 10 - Final Bootc Setup

########################################################################################################################################
# Section 1 - Package Installs | We grab every package we can from official arch repo/set up all non-flatpak apps for user ^^ ##########
########################################################################################################################################

# Move everything from `/var` to `/usr/lib/sysimage` so behavior around pacman remains the same on `bootc usroverlay`'d systems
RUN grep "= */var" /etc/pacman.conf | sed "/= *\/var/s/.*=// ; s/ //" | xargs -n1 sh -c 'mkdir -p "/usr/lib/sysimage/$(dirname $(echo $1 | sed "s@/var/@@"))" && \
mv -v "$1" "/usr/lib/sysimage/$(echo "$1" | sed "s@/var/@@")"' '' && \
    sed -i -e "/= *\/var/ s/^#//" -e "s@= */var@= /usr/lib/sysimage@g" -e "/DownloadUser/d" /etc/pacman.conf

# Set it up such that pacman is always cleaned after installs
RUN echo -e "[Trigger]\n\
Operation = Install\n\
Operation = Upgrade\n\
Type = Package\n\
Target = *\n\
\n\
[Action]\n\
Description = Cleaning up package cache...\n\
Depends = coreutils\n\
When = PostTransaction\n\
Exec = /usr/bin/rm -rf /var/cache/pacman/pkg" > /usr/share/libalpm/hooks/package-cleanup.hook

# FIXME | Fix an issue with Cachy's docker, pacman -syu fails otherwise https://discuss.cachyos.org/t/cant-update-because-of-linux-firmware-notice/19835
RUN mkdir /usr/lib/sysimage/lib/pacmanlocal -p

# Initialize the database
RUN pacman -Syu --noconfirm

# Use the Arch mirrorlist that will be best at the moment for both the containerfile and user too! Fox will help!
RUN pacman -S --noconfirm reflector

# Base packages \ Linux Foundation \ Foss is love, foss is life! We split up packages by category for readability, debug ease, and less dependency trouble
RUN pacman -S --noconfirm base linux-firmware dracut ostree systemd btrfs-progs e2fsprogs xfsprogs binutils dosfstools skopeo dbus dbus-glib glib2 shadow

# Fonts
RUN pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji unicode-emoji noto-fonts-extra \
    ttf-ibm-plex otf-font-awesome ttf-jetbrains-mono wqy-microhei ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-common \
    ttf-nerd-fonts-symbols-mono ttf-croscore ttf-dejavu ttf-droid gsfonts ttf-arphic-uming ttf-baekmuk gnu-free-fonts otf-monaspace

# CLI Utilities
#RUN pacman -S --noconfirm sudo bash bash-completion fastfetch btop jq less lsof nano openssh powertop man-db wget yt-dlp \
#      tree usbutils vim wl-clip-persist cliphist unzip ptyxis glibc-locales tar udev starship tuned-ppd tuned hyfetch curl patchelf 

# Virtualization \ Containerization
RUN pacman -S --noconfirm distrobox docker podman

# Network / VPN / SMB / storage
#RUN pacman -S --noconfirm libmtp nss-mdns samba smbclient networkmanager firewalld udiskie udisks2

# User frontend programs/apps
RUN pacman -S --noconfirm scx-scheds scx-manager gnome-disk-utility

RUN pacman -S --noconfirm --overwrite="*" --ask=4 linux-cachyos-deckify
RUN pacman -S --noconfirm --overwrite="*" --ask=4 plasma-meta sddm
RUN pacman -S --noconfirm --overwrite="*" --ask=4 cachyos-handheld
RUN pacman -S --noconfirm --overwrite="*" --ask=4 sudo
RUN pacman -S --noconfirm --overwrite="*" --ask=4 fastfetch
#RUN pacman -S --noconfirm --overwrite="*" --ask=4 podman-compose

##############################################################################################################################################
# Section 3 - Chaotic AUR / AUR # We grab some precompiled packages from the Chaotic AUR for things not on Arch repos/better updated~ ovo ####
##############################################################################################################################################

# Chaotic AUR repo
RUN pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
RUN pacman-key --init && pacman-key --lsign-key 3056513887B78AEB
RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
RUN echo -e '[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
# Heck's Bootc repo
RUN pacman-key --recv-key 5DE6BF3EBC86402E7A5C5D241FA48C960F9604CB --keyserver keyserver.ubuntu.com
RUN pacman-key --lsign-key 5DE6BF3EBC86402E7A5C5D241FA48C960F9604CB
RUN echo -e '[bootc]\nSigLevel = Required\nServer=https://github.com/hecknt/arch-bootc-pkgs/releases/download/$repo' >> /etc/pacman.conf

RUN pacman -Sy --noconfirm

RUN pacman -S --noconfirm \
    chaotic-aur/flatpak-git \
    chaotic-aur/opentabletdriver \
    chaotic-aur/bootc 

RUN pacman -S --noconfirm \
  bootc/uupd && \
  systemctl enable uupd.timer

#######################################################################################################################################################
# Section 4 - Flatpaks preinstalls | Don't forget. Always, somewhere, someone is fighting for you. You are not alone. -Madoka Magica ##################
#######################################################################################################################################################

RUN mkdir -p /usr/share/flatpak/preinstall.d/

# Bazaar | Get most of your software here, flatpaks that are easy to install and use~
RUN echo -e "[Flatpak Preinstall io.github.kolunmi.Bazaar]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Bazaar.preinstall

########################################################################################################################################
# Section 5 - Linux OS stuffs | "I'd decide for myself whether his teachings are right or wrong." Near, Death Note #####################
########################################################################################################################################

# Place XeniaOS logo at plymouth folder location to appear on boot and shutdown.
#RUN mkdir -p /etc/plymouth && \
#      echo -e '[Daemon]\nTheme=spinner' | tee /etc/plymouth/plymouthd.conf && \
#      wget --tries=5 -O /usr/share/plymouth/themes/spinner/watermark.png \
#      https://raw.githubusercontent.com/XeniaMeraki/XeniaOS-G-Euphoria/refs/heads/main/xeniaos_textlogo_plymouth_delphic_melody.png

# All kindsa Sudo changes for ease and flavor
RUN echo -e '%wheel ALL=(ALL:ALL) ALL\n\
\n\
Defaults insults\n\
Defaults pwfeedback\n\
Defaults secure_path="/usr/local/bin:/usr/bin:/bin:/home/linuxbrew/.linuxbrew/bin"\n\
Defaults env_keep += "EDITOR VISUAL PATH"\n\
Defaults timestamp_timeout=0' > /etc/sudoers.d/xenias-sudo-quiver && \
    chmod 440 /etc/sudoers.d/xenias-sudo-quiver

RUN git clone --depth=1 https://github.com/vinceliuice/Colloid-icon-theme /tmp/colloid-icons && \
    cd /tmp/colloid-icons && \
    ./install.sh \
      -s catppuccin \
      -t orange \
      -d /usr/share/icons && \
    rm -rf /tmp/colloid-icons

# Set up zram, this will help users not run out of memory. Fox will fix!
RUN echo -e '[zram0]\nzram-size = min(ram, 8192)' > /usr/lib/systemd/zram-generator.conf
RUN echo -e 'enable systemd-resolved.service' > /usr/lib/systemd/system-preset/91-resolved-default.preset
RUN echo -e 'L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf' > /usr/lib/tmpfiles.d/resolved-default.conf
RUN systemctl preset systemd-resolved.service

# Symlink Vi to Vim / Make it to where a user can use vi in terminal command to use vim automatically | Thanks Tulip
#RUN ln -s ./vim /usr/bin/vi

# System-wide default application associations for filetype calls
RUN mkdir -p /etc/xdg/

RUN echo -e '[Default Applications]\n\
text/plain=org.kde.kate.desktop\n\
application/json=org.kde.kate.desktop\n\
\n\
text/html=floorp.desktop\n\
\n\
video/mp4=haruna.desktop\n\
video/x-matroska=haruna.desktop\n\
video/webm=haruna.desktop\n\
video/quicktime=haruna.desktop\n\
\n\
audio/mpeg=org.kde.elisa.desktop\n\
audio/flac=org.kde.elisa.desktop\n\
audio/ogg=org.kde.elisa.desktop\n\
audio/wav=org.kde.elisa.desktop\n\
\n\
image/png=pinta.desktop\n\
image/jpeg=pinta.desktop\n\
image/gif=org.kde.gwenview.desktop\n\
\n\
application/zip=org.kde.ark.desktop\n\
application/x-rar=org.kde.ark.desktop\n\
application/x-tar=org.kde.ark.desktop\n\
\n\
[Added Associations]' > /etc/xdg/mimeapps.list

# ENV default exports, QT theming 
# Load shared objects immediately for better first time latency
# Apply OBS_VK to all vulkan instances for better OBS game capture, some other windows may come along for the ride
# Auto dark mode everywhere
RUN echo -e 'QT_QPA_PLATFORMTHEME=qt6ct\n\
LD_BIND_NOW=1\n\
OBS_VKCAPTURE=1\n\
#GTK_THEME=Colloid-Orange-Dark-Catppuccin\n\
#QT_STYLE_OVERRIDE=Colloid-Orange-Dark-Catppuccin\n\
XDG_MENU_PREFIX=arch-\n\
XDG_MENU_PREFIX=plasma-' > /etc/environment

RUN kbuildsycoca6

# Set vm.max_map_count for stability/improved gaming performance
# https://wiki.archlinux.org/title/Gaming#Increase_vm.max_map_count
RUN echo -e "vm.max_map_count = 2147483642" > /etc/sysctl.d/80-gamecompatibility.conf

# Automount ext4/btrfs drives, feel free to mount your own in fstab if you understand how to do so
# To turn off, run sudo ln -s /dev/null /etc/media-automount.d/_all.conf
RUN git clone --depth=1 https://github.com/Zeglius/media-automount-generator /tmp/media-automount-generator && \
    cd /tmp/media-automount-generator && \
    ./install.sh && \
    rm -rf /tmp/media-automount-generator

########################################################################################################################################
# Section 6 - Set up brew | terminal packages manager utility | https://brew.sh/ | Foxy witch will mix up a brew for you! ##############
########################################################################################################################################

RUN curl -s --variable '%AUTH_HEADER' --expand-header '{{AUTH_HEADER}}' https://api.github.com/repos/ublue-os/packages/releases/latest \
    | jq -r '.assets[] | select(.name | test("homebrew-x86_64.*\\.tar\\.zst")) | .browser_download_url' \
    | xargs -I {} wget -O /usr/share/homebrew.tar.zst {}

RUN echo '[[ -d /home/linuxbrew/.linuxbrew && $- == *i* ]] && \
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' > /etc/profile.d/brew.sh

RUN echo -e "[Unit]\n\
Description=Setup Homebrew from tarball\n\
After=local-fs.target\n\
ConditionPathExists=!/var/home/linuxbrew/.linuxbrew\n\
ConditionPathExists=/usr/share/homebrew.tar.zst\n\
\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/bin/mkdir -p /tmp/homebrew\n\
ExecStart=/usr/bin/mkdir -p /var/home/linuxbrew\n\
ExecStart=/usr/bin/tar --zstd -xf /usr/share/homebrew.tar.zst -C /tmp/homebrew\n\
ExecStart=/usr/bin/cp -R -n /tmp/homebrew/linuxbrew/.linuxbrew /var/home/linuxbrew\n\
ExecStart=/usr/bin/chown -R 1000:1000 /var/home/linuxbrew\n\
ExecStart=/usr/bin/rm -rf /tmp/homebrew\n\
ExecStart=/usr/bin/touch /etc/.linuxbrew\n\
\n\
[Install]\n\
WantedBy=multi-user.target" > /usr/lib/systemd/system/brew-setup.service

RUN systemctl enable brew-setup.service

##############################################################################################################################################################################
# Section 7 - Systemd n Services | Hope is just like every other kind of work you do on your body, it's cyclical, and needs to be refreshed every day -Harpy #################
##############################################################################################################################################################################

# Systemd flatpak preinstall service, thanks Aurora
RUN echo -e '[Unit]\n\
Description=Preinstall Flatpaks\n\
After=network-online.target\n\
Wants=network-online.target\n\
ConditionPathExists=/usr/bin/flatpak\n\
Documentation=man:flatpak-preinstall(1)\n\
\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/bin/flatpak preinstall -y\n\
RemainAfterExit=true\n\
Restart=on-failure\n\
RestartSec=30\n\
\n\
StartLimitIntervalSec=600\n\
StartLimitBurst=3\n\
\n\
[Install]\n\
WantedBy=multi-user.target' > /usr/lib/systemd/system/flatpak-preinstall.service

# This fixes a user/groups error with rebasing from other problematic images.
# FIXME Do NOT remove until fixed upstream or fixed universally. Updating with new fix also fine. Script created by Tulip.
RUN mkdir -p /usr/lib/systemd/system-preset /usr/lib/systemd/system

RUN echo -e '#!/bin/sh\ncat /usr/lib/sysusers.d/*.conf | grep -e "^g" | grep -v -e "^#" | awk "NF" | awk '\''{print $2}'\'' | grep -v -e "wheel" -e "root" -e "sudo" | xargs -I{} sed -i "/{}/d" $1' > /usr/libexec/xeniaos-group-fix
RUN chmod +x /usr/libexec/xeniaos-group-fix
RUN echo -e '[Unit]\n\
Description=Fix groups\n\
Wants=local-fs.target\n\
After=local-fs.target\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/libexec/xeniaos-group-fix /etc/group\n\
ExecStart=/usr/libexec/xeniaos-group-fix /etc/gshadow\n\
ExecStart=systemd-sysusers\n\
[Install]\n\
WantedBy=default.target multi-user.target' > /usr/lib/systemd/system/os-group-fix.service

RUN echo -e "enable os-group-fix.service" > /usr/lib/systemd/system-preset/01-xeniaos-group-fix.preset

# System services (Machine Boot level)
RUN systemctl enable polkit.service \
    NetworkManager.service \
    tuned.service \
    tuned-ppd.service \
    firewalld.service \
    greetd.service \
    flatpak-preinstall.service \
    os-group-fix.service \

########################################################################################################################################
# Section 8 - CachyOS settings | Since we have the CachyOS kernel, we gotta put it to good use ≽^•⩊•^≼ ################################
########################################################################################################################################

# Activate NTSync, wags my tail in your general direction
RUN echo -e 'ntsync' > /etc/modules-load.d/ntsync.conf

# CachyOS bbr3 Config Option
RUN echo -e 'net.core.default_qdisc=fq \n\
net.ipv4.tcp_congestion_control=bbr' > /etc/sysctl.d/99-bbr3.conf

########################################################################################################################################
# Section 9 - Niri/Chezmoi/DMS | Everything to do with the desktop/visual look of your taskbar/ config files (⸝⸝>w<⸝⸝) #################
########################################################################################################################################

# Add Maple Mono font, it's so cute! It's a pain to download! You'll love it.
RUN mkdir -p "/usr/share/fonts/Maple Mono" && \
    curl --retry 5 --retry-all-errors -fsSL \
      https://github.com/subframe7536/maple-font/releases/download/v7.9/MapleMono-Variable.zip \
      -o /tmp/maple.zip && \
    unzip -q /tmp/maple.zip -d "/usr/share/fonts/Maple Mono" && \
    rm -f /tmp/maple.zip && \
    fc-cache -f || true

########################################################################################################################################
# Section 10 - Final Bootc Setup | The horrors are endless. but we stay silly :3c -junoinfernal -maia arson crimew #####################
########################################################################################################################################

RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

RUN rm -rf /home/build/.cache/* && \
    rm -rf \
        /tmp/* \
        /var/cache/pacman/pkg/* && \
    pacman -Rns --noconfirm

# Necessary for general behavior expected by image-based systems
RUN sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd" && \
    rm -rf /boot /home /root /usr/local /srv /var /usr/lib/sysimage/log /usr/lib/sysimage/cache/pacman/pkg && \
    mkdir -p /sysroot /boot /usr/lib/ostree /var && \
    ln -s sysroot/ostree /ostree && ln -s var/roothome /root && ln -s var/srv /srv && ln -s var/opt /opt && ln -s var/mnt /mnt && ln -s var/home /home && \
    echo "$(for dir in opt home srv mnt usrlocal ; do echo "d /var/$dir 0755 root root -" ; done)" | tee -a "/usr/lib/tmpfiles.d/bootc-base-dirs.conf" && \
    printf "d /var/roothome 0700 root root -\nd /run/media 0755 root root -" | tee -a "/usr/lib/tmpfiles.d/bootc-base-dirs.conf" && \
    printf '[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n' | tee "/usr/lib/ostree/prepare-root.conf"

RUN bootc container lint
