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





























RUN dnf5 -y install dnf5-plugins && \
    rpm --import https://repo.rakuos.org/pubkey.gpg && \
    dnf5 -y config-manager addrepo --from-repofile=https://repo.rakuos.org/rakuos.repo && \
    sed -i -e '/^\[rakuos-v3\]/,/^\[/ s/^enabled=0/enabled=1/' /etc/yum.repos.d/rakuos.repo && \
    dnf5 -y install rakuos-rum rum-dnf-shim
RUN FACTORY_VAR_ROOT="/usr/share/factory/var" && \
    PACKAGES_LIST="$FACTORY_VAR_ROOT/lib/rakuos/packages.list" && \
    UPPER_DIR="$FACTORY_VAR_ROOT/lib/rakuos/overlay/upper" && \
    WORK_DIR="$FACTORY_VAR_ROOT/lib/rakuos/overlay/work" && \
    STATE_FILE="$FACTORY_VAR_ROOT/lib/rakuos/overlay.state" && \
    DIRTY_FILE="$FACTORY_VAR_ROOT/lib/rakuos/overlay.dirty" && \
    FACTORY_RUM_RPMDB="$FACTORY_VAR_ROOT/lib/rakuos/rum-rpmdb" && \
    mkdir -p "$FACTORY_VAR_ROOT/lib/rakuos" "$UPPER_DIR" "$WORK_DIR" && \
    touch "$PACKAGES_LIST" && \
    installroot="$(mktemp -d /var/tmp/rakuos-overlay-installroot.XXXXXX)" && \
    trap 'rm -rf "$installroot"' EXIT && \
    rum install --installroot "$installroot" -y --refresh firefox && \
    rum remove --installroot "$installroot" -y firefox && \
    rm -f "$installroot/usr/share/icons/default/index.theme" && \
    rm -rf "$UPPER_DIR" "$WORK_DIR" && \
    mkdir -p "$UPPER_DIR" "$WORK_DIR" && \
    cp -a "$installroot/usr/." "$UPPER_DIR/" && \
    rm -rf "$FACTORY_RUM_RPMDB" && \
    mkdir -p "$(dirname "$FACTORY_RUM_RPMDB")" && \
    cp -a "$installroot/var/lib/rakuos/rum-rpmdb" "$FACTORY_RUM_RPMDB" && \
    if [[ -d "$installroot/etc" ]] && [[ -n "$(ls -A "$installroot/etc" 2>/dev/null)" ]]; then \
        cp -a "$installroot/etc/." /etc/; \
    fi && \
    echo "prebaked-installroot" > "$STATE_FILE" && \
    rm -f "$DIRTY_FILE"
RUN systemctl enable rakuos-overlay-sync.service
























































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
