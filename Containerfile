##################################################################################################################################################
### :::::: Pull CachyOS :::::: ###
##################################################################################################################################################
FROM docker.io/pkgforge/cachyos-base:x86_64 AS cachyos

# :::::: prepare the kernel :::::: 
RUN rm -rf /lib/modules/*
RUN pacman -Sy --disable-sandbox --noconfirm
RUN pacman -Sy --disable-sandbox --noconfirm archlinux-keyring cachyos-keyring
RUN pacman -Sy --disable-sandbox --noconfirm
RUN pacman -S --disable-sandbox --noconfirm linux-cachyos-deckify
RUN pacman -S --disable-sandbox --noconfirm vulkan-tools vulkan-icd-loader lib32-vulkan-icd-loader dkms

##################################################################################################################################################
### :::::: Pull Ublue-OS :::::: ###
##################################################################################################################################################
FROM ghcr.io/ublue-os/bazzite-deck:latest

# :::::: forcefully remove and replace kernel :::::: 
RUN rm -rf /lib/modules
COPY --from=cachyos /lib/modules /lib/modules
COPY --from=cachyos /usr/share/licenses/ /usr/share/licenses/

##################################################################################################################################################
### :::::: Modifications :::::: ###
##################################################################################################################################################
# :::::: disable countme ( I like my telemetry opt-in,thank you very much. you can enable it if you want... ) :::::: 
RUN sed -i -e s,countme=1,countme=0, /etc/yum.repos.d/*.repo && systemctl mask --now rpm-ostree-countme.timer

# :::::: force distrobox to use a sub-directory for home :::::: 
RUN mkdir -p /usr/share/distrobox/
RUN touch /usr/share/distrobox/distrobox.conf
RUN echo "DBX_CONTAINER_HOME_PREFIX=~/distrobox" >> /usr/share/distrobox/distrobox.conf

# :::::: install preformence-related stuff :::::: 
#RUN dnf5 -y copr enable bieszczaders/kernel-cachyos-addons
#    RUN dnf5 -y install --allowerasing scx-scheds scx-tools scxctl cachyos-settings scx-manager
#RUN dnf5 -y copr disable bieszczaders/kernel-cachyos-addons 

# Set vm.max_map_count for stability/improved gaming performance
# https://wiki.archlinux.org/title/Gaming#Increase_vm.max_map_count
  RUN echo -e "vm.max_map_count = 2147483642" > /etc/sysctl.d/80-gamecompatibility.conf
















RUN set -euo pipefail; \
    FACTORY_VAR_ROOT="/usr/share/factory/var" && \
    PACKAGES_LIST="$FACTORY_VAR_ROOT/lib/rakuos/packages.list" && \
    UPPER_DIR="$FACTORY_VAR_ROOT/lib/rakuos/overlay/upper" && \
    WORK_DIR="$FACTORY_VAR_ROOT/lib/rakuos/overlay/work" && \
    STATE_FILE="$FACTORY_VAR_ROOT/lib/rakuos/overlay.state" && \
    DIRTY_FILE="$FACTORY_VAR_ROOT/lib/rakuos/overlay.dirty" && \
    FACTORY_RUM_RPMDB="$FACTORY_VAR_ROOT/lib/rakuos/rum-rpmdb" && \
    \
    echo "[rakuos] Seeding overlay state for first-boot install..." && \
    \
    mkdir -p "$FACTORY_VAR_ROOT/lib/rakuos" "$UPPER_DIR" "$WORK_DIR" && \
    \
    touch "$PACKAGES_LIST" && \
    echo "[rakuos] packages.list is empty — no packages will be installed on first boot." && \
    rm -f "$STATE_FILE" "$DIRTY_FILE" && \
    sed -i -e '$a\' "$PACKAGES_LIST" && \
    echo "[rakuos] stale overlay state cleared — prebake will write fresh first-boot state." && \
    echo "[rakuos] Post-build seed complete." && \
    \
    echo "Appending minimal protected packages to protected-packages.txt..." && \
    cat >> /usr/share/rakuos/protected-packages.txt << 'EOF'

# Minimal packages (from rakuos-minimal/build_files/build.sh)

EOF

RUN set -euo pipefail; \
    FACTORY_VAR_ROOT="/usr/share/factory/var" && \
    UPPER_DIR="$FACTORY_VAR_ROOT/lib/rakuos/overlay/upper" && \
    WORK_DIR="$FACTORY_VAR_ROOT/lib/rakuos/overlay/work" && \
    STATE_FILE="$FACTORY_VAR_ROOT/lib/rakuos/overlay.state" && \
    DIRTY_FILE="$FACTORY_VAR_ROOT/lib/rakuos/overlay.dirty" && \
    FACTORY_RUM_RPMDB="$FACTORY_VAR_ROOT/lib/rakuos/rum-rpmdb" && \
    \
    installroot="$(mktemp -d /var/tmp/rakuos-overlay-installroot.XXXXXX)" && \
    trap 'rm -rf "$installroot"' EXIT && \
    \
    echo "[rakuos] Prebaking overlay packages into installroot via rum..." && \
    rum install --installroot "$installroot" -y --refresh firefox && \
    rum remove --installroot "$installroot" -y firefox && \
    rm -f "$installroot/usr/share/icons/default/index.theme" && \
    \
    echo "[rakuos] Copying prebaked /usr payload into overlay upper..." && \
    rm -rf "$UPPER_DIR" "$WORK_DIR" && \
    mkdir -p "$UPPER_DIR" "$WORK_DIR" && \
    cp -a "$installroot/usr/." "$UPPER_DIR/" && \
    \
    echo "[rakuos] Copying prebaked rum overlay rpmdb into factory seed..." && \
    rm -rf "$FACTORY_RUM_RPMDB" && \
    mkdir -p "$(dirname "$FACTORY_RUM_RPMDB")" && \
    cp -a "$installroot/var/lib/rakuos/rum-rpmdb" "$FACTORY_RUM_RPMDB" && \
    \
    if [ -d "$installroot/etc" ] && [ -n "$(ls -A "$installroot/etc" 2>/dev/null)" ]; then \
        echo "[rakuos] Copying prebaked /etc payload into image..." && \
        cp -a "$installroot/etc/." /etc/; \
    fi && \
    \
    echo "prebaked-installroot" > "$STATE_FILE" && \
    rm -f "$DIRTY_FILE" && \
    echo "[rakuos] Overlay prebake complete." && \
    \
    echo "Generating base file manifest..." && \
    /usr/libexec/rakuos/generate-base-manifest













##################################################################################################################################################
### :::::: Security and Finalization :::::: ###
##################################################################################################################################################
# :::::: Fix SELinux :::::: 
#
RUN sed -i 's/^SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config
#
RUN touch /etc/.autorelabel
#
RUN mkdir -p /usr/lib/bootc/kargs.d/
RUN sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/lib/systemd/system/selinux-autorelabel-mark.service
RUN sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/libexec/selinux/selinux-autorelabel
RUN sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/lib/systemd/system-generators/selinux-autorelabel-generator.sh
RUN echo 'kargs = ["lsm=landlock,lockdown,yama,integrity,selinux,bpf", "selinux=1", "enforcing=1", "selinux_dontaudit=0", "selinux_deny_unknown=1"]' > /usr/lib/bootc/kargs.d/90-security-overrides.toml
#
RUN sed -i 's/active = yes/active = no/' /etc/audit/plugins.d/sedispatch.conf
#
# :::::: slot the kernel into place :::::: 
RUN mkdir -p /var/tmp
RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'
#
#  :::::: finish :::::: 
RUN rm -rf /usr/etc
LABEL containers.bootc 1
RUN bootc container lint || true
