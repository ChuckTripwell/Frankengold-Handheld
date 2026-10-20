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































































# 1. Install rum and shim globally first so the binary exists in $PATH
RUN dnf5 -y install dnf5-plugins && \
    rpm --import https://repo.rakuos.org/pubkey.gpg && \
    dnf5 -y config-manager addrepo --from-repofile=https://repo.rakuos.org/rakuos.repo && \
    sed -i -e '/^\[rakuos-v3\]/,/^\[/ s/^enabled=0/enabled=1/' /etc/yum.repos.d/rakuos.repo && \
    dnf5 -y install rakuos-rum rum-dnf-shim rakuos-core

# 2. Now run the overlay prebake (rum is now available)
RUN set -eo pipefail && \
    FACTORY_VAR="/usr/share/factory/var/lib/rakuos" && \
    UPPER_DIR="$FACTORY_VAR/overlay/upper" && \
    WORK_DIR="$FACTORY_VAR/overlay/work" && \
    mkdir -p "$UPPER_DIR" "$WORK_DIR" && \
    \
    installroot="$(mktemp -d /var/tmp/rakuos-overlay-installroot.XXXXXX)" && \
    trap 'rm -rf "$installroot"' EXIT && \
    \
    RAKUOS_PKGS="rakuos-rum rakuos-core rakuos-settings rakuos-release rakuos-release-common" && \
    DUMMY_PKG="firefox" && \
    \
    echo "$RAKUOS_PKGS" | tr ' ' '\n' > "$FACTORY_VAR/packages.list" && \
    \
    rum install --installroot "$installroot" -y --refresh --allowerasing $RAKUOS_PKGS $DUMMY_PKG && \
    rum remove --installroot "$installroot" -y $DUMMY_PKG && \
    \
    rm -rf "$UPPER_DIR" "$WORK_DIR" && \
    mkdir -p "$UPPER_DIR" "$WORK_DIR" && \
    if [ -d "$installroot/usr" ]; then cp -a "$installroot/usr/." "$UPPER_DIR/"; fi && \
    \
    rm -rf "$FACTORY_VAR/rum-rpmdb" && \
    mkdir -p "$FACTORY_VAR/rum-rpmdb" && \
    if [ -d "$installroot/var/lib/rakuos/rum-rpmdb" ]; then cp -a "$installroot/var/lib/rakuos/rum-rpmdb/." "$FACTORY_VAR/rum-rpmdb/"; fi && \
    \
    echo "prebaked-installroot" > "$FACTORY_VAR/overlay.state" && \
    rm -f "$FACTORY_VAR/overlay.dirty"



















































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
