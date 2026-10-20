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



























RUN mkdir -p /var/lib/rakuos/rum-overlay/usr /var/lib/rakuos/rum-overlay/work /var/lib/rakuos/rum-rpmdb /usr/lib/dracut/modules.d/96rum-overlay /etc/dracut.conf.d
RUN chmod 755 /var/lib/rakuos
RUN cp -a /usr/share/rpm /var/lib/rakuos/rum-rpmdb

RUN echo '#!/bin/bash' > /usr/lib/dracut/modules.d/96rum-overlay/module-setup.sh
RUN echo 'check() { return 0; }' >> /usr/lib/dracut/modules.d/96rum-overlay/module-setup.sh
RUN echo 'depends() { echo base rootfs-block; }' >> /usr/lib/dracut/modules.d/96rum-overlay/module-setup.sh
RUN echo 'install() {' >> /usr/lib/dracut/modules.d/96rum-overlay/module-setup.sh
RUN echo '    inst_hook pre-pivot 97 "$moddir/mount-overlay-usr.sh"' >> /usr/lib/dracut/modules.d/96rum-overlay/module-setup.sh
RUN echo '    inst_multiple mount mkdir ls' >> /usr/lib/dracut/modules.d/96rum-overlay/module-setup.sh
RUN echo '}' >> /usr/lib/dracut/modules.d/96rum-overlay/module-setup.sh
RUN chmod +x /usr/lib/dracut/modules.d/96rum-overlay/module-setup.sh

RUN echo '#!/bin/sh' > /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo 'SYSROOT=/sysroot' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo 'UPPER="$SYSROOT/var/lib/rakuos/rum-overlay/usr"' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo 'WORK="$SYSROOT/var/lib/rakuos/rum-overlay/work"' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo 'RPM_OVERLAY="$SYSROOT/var/lib/rakuos/rum-rpmdb"' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo 'RPM_SYSTEM="$SYSROOT/usr/share/rpm"' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo '' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo 'if grep -q " /sysroot/usr overlay " /proc/self/mountinfo 2>/dev/null; then' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo '    exit 0' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo 'fi' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo '' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo '[ -d "$SYSROOT/usr" ] || exit 0' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo 'mkdir -p "$UPPER" "$WORK"' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo '' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo 'mount -t overlay overlay \' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo '    -o lowerdir=$SYSROOT/usr,upperdir=$UPPER,workdir=$WORK \' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo '    $SYSROOT/usr' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo '' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo 'mkdir -p "$SYSROOT/usr/share"' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN echo 'mount --bind "$RPM_OVERLAY" "$RPM_SYSTEM"' >> /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh
RUN chmod +x /usr/lib/dracut/modules.d/96rum-overlay/mount-overlay-usr.sh

RUN echo 'add_dracutmodules+=" rum-overlay "' > /etc/dracut.conf.d/96rum-overlay.conf
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
