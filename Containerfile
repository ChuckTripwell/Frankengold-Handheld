FROM ghcr.io/ublue-os/bazzite-deck:latest AS bazzite
FROM docker.io/cachyos/cachyos-v3:latest AS cachyos

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

RUN pacman -Sy --noconfirm base dracut ostree btrfs-progs e2fsprogs xfsprogs dosfstools skopeo dbus dbus-glib glib2 ostree shadow && pacman -S --clean --noconfirm

RUN pacman -Sy --noconfirm --overwrite="*" --ask=4 linux-cachyos-deckify
#RUN pacman -Sy --noconfirm --overwrite="*" --ask=4 cachyos-handheld
#RUN pacman -Sy --noconfirm --overwrite="*" --ask=4 plasma-meta

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


RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

RUN rm -rf /home/build/.cache/* && \
    rm -rf \
        /tmp/* \
        /var/cache/pacman/pkg/*

# Necessary for general behavior expected by image-based systems
RUN sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd" && \
    rm -rf /boot /home /root /usr/local /srv /var /usr/lib/sysimage/log /usr/lib/sysimage/cache/pacman/pkg && \
    mkdir -p /sysroot /boot /usr/lib/ostree /var && \
    ln -s sysroot/ostree /ostree && ln -s var/roothome /root && ln -s var/srv /srv && ln -s var/opt /opt && ln -s var/mnt /mnt && ln -s var/home /home && \
    echo "$(for dir in opt home srv mnt usrlocal ; do echo "d /var/$dir 0755 root root -" ; done)" | tee -a "/usr/lib/tmpfiles.d/bootc-base-dirs.conf" && \
    printf "d /var/roothome 0700 root root -\nd /run/media 0755 root root -" | tee -a "/usr/lib/tmpfiles.d/bootc-base-dirs.conf" && \
    printf '[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n' | tee "/usr/lib/ostree/prepare-root.conf"

RUN bootc container lint




COPY --from="bazzite" /bin /
COPY --from="bazzite" /bin /
COPY --from="bazzite" /sbin /
COPY --from="bazzite" /usr/bin /
COPY --from="bazzite" /usr/sbin /
COPY --from="bazzite" /lib /
COPY --from="bazzite" /lib64 /
COPY --from="bazzite" /opt /

RUN bootc container lint
