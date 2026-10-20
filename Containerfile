##################################################################################################################################################
### :::::: Pull Kernel:::::: ###
##################################################################################################################################################
FROM ghcr.io/ublue-os/base-main:latest AS kernel

# :::::: prepare the kernel :::::: 
RUN rm -rf /lib/modules/*
RUN dnf5 copr -y enable catpieleaf/kernel-p03
RUN dnf5 -y install --setopt=tsflags=noscripts kernel-p03-deck

##################################################################################################################################################
### :::::: Pull Ublue-OS :::::: ###
##################################################################################################################################################
FROM ghcr.io/ublue-os/bazzite-deck:latest AS system

# :::::: forcefully remove and replace kernel :::::: 
RUN rm -rf /lib/modules
COPY --from=kernel /lib/modules /lib/modules
COPY --from=kernel /usr/share/licenses/ /usr/share/licenses/

##################################################################################################################################################
### :::::: Modifications :::::: ###
##################################################################################################################################################
# :::::: disable countme ( I like my telemetry opt-in,thank you very much. you can enable it if you want... ) :::::: 
RUN sed -i -e s,countme=1,countme=0, /etc/yum.repos.d/*.repo && systemctl mask --now rpm-ostree-countme.timer || true

# :::::: force distrobox to use a sub-directory for home :::::: 
RUN mkdir -p /usr/share/distrobox/
RUN touch /usr/share/distrobox/distrobox.conf
RUN echo "DBX_CONTAINER_HOME_PREFIX=~/distrobox" >> /usr/share/distrobox/distrobox.conf

# Set vm.max_map_count for stability/improved gaming performance
# https://wiki.archlinux.org/title/Gaming#Increase_vm.max_map_count
  RUN echo -e "vm.max_map_count = 2147483642" > /etc/sysctl.d/80-gamecompatibility.conf


























RUN rm -f /usr/bin/rpm-ostree

RUN mkdir -p \
        /var/lib/rakuos/rum-overlay/usr \
        /var/lib/rakuos/rum-overlay/work \
        /var/lib/rakuos/rum-rpmdb \
    && chmod 755 /var/lib/rakuos

RUN cp -a /usr/share/rpm /var/lib/rakuos/rum-rpmdb

RUN mkdir -p /usr/lib/dracut/modules.d/96rum-overlay

RUN cat > /usr/lib/dracut/modules.d/96rum-overlay/module-setup.sh <<'EOF'
#!/bin/bash
check() { return 0; }
depends() { echo base rootfs-block; }
install() {
    inst_hook pre-pivot 97 "$moddir/mount-overlay-usr.sh"
    inst_multiple mount mkdir ls
}
EOF

RUN cat > /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh <<'EOF'
#!/bin/sh
SYSROOT=/sysroot
UPPER="$SYSROOT/var/lib/rakuos/rum-overlay/usr"
WORK="$SYSROOT/var/lib/rakuos/rum-overlay/work"
RPM_OVERLAY="$SYSROOT/var/lib/rakuos/rum-rpmdb"
RPM_SYSTEM="$SYSROOT/usr/share/rpm"

if grep -q " /sysroot/usr overlay " /proc/self/mountinfo 2>/dev/null; then
    exit 0
fi

[ -d "$SYSROOT/usr" ] || exit 0
mkdir -p "$UPPER" "$WORK"

# Mount overlayfs over /usr
mount -t overlay overlay \
    -o lowerdir=$SYSROOT/usr,upperdir=$UPPER,workdir=$WORK \
    $SYSROOT/usr

# Bind-mount overlay rpmdb over system rpmdb (this makes dnf5/rpm use it automatically)
mkdir -p "$SYSROOT/usr/share"
mount --bind "$RPM_OVERLAY" "$RPM_SYSTEM"
EOF

RUN chmod +x /usr/lib/dracut/modules.d/96rum-overlay/module-setup.sh \
           /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh

RUN mkdir -p /etc/dracut.conf.d \
    && echo 'add_dracutmodules+=" rum-overlay "' > /etc/dracut.conf.d/96rum-overlay.conf

RUN dracut --force --add rum-overlay


















































##################################################################################################################################################
### :::::: Security and Finalization :::::: ###
##################################################################################################################################################

RUN mkdir -p /var/tmp
RUN set -eu; \
    D=/usr/lib/dracut/dracut.conf.d; install -d "$D"; \
    printf '%s\n' 'systemdsystemconfdir=/etc/systemd/system' 'systemdsystemunitdir=/usr/lib/systemd/system' > "$D/30-bootcrew-fix-bootc-module.conf"; \
    printf '%s\n' 'hostonly=no' 'add_dracutmodules+=" ostree bootc "' > "$D/30-bootcrew-bootc-modules.conf"; \
    K=$(ls /usr/lib/modules); \
    depmod -a "$K"; \
    dracut -f --reproducible --zstd -v --kver "$K" "/usr/lib/modules/$K/initramfs.img"
#
#  :::::: finish :::::: 
RUN rm -rf /usr/etc
LABEL containers.bootc 1
RUN bootc container lint || true
