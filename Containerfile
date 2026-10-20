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






























# =============================================================================
# RakuOS-style rum split-mode overlay for Bazzite/Fedora bootc
# - Does NOT disable SELinux (preserves all SELinux contexts)
# - Uses dnf5 with split rpmdb architecture
# - Persistent overlay on /usr survives bootc updates
# =============================================================================

ENV DEBIAN_FRONTEND=noninteractive
ENV SYSTEMD_OFFLINE=1

# =============================================================================
# 1. Install required packages
# =============================================================================
RUN dnf5 install -y \
        dracut \
        findutils \
        shadow-utils \
        tar \
        xz \
        policycoreutils \
        libselinux-utils \
    && dnf5 clean all

# =============================================================================
# 2. Create overlay directory structure
#    RakuOS stores upper layer at /var/lib/rakuos/rum-overlay/usr
# =============================================================================
RUN mkdir -p /var/lib/rakuos/rum-overlay/usr \
    && mkdir -p /var/lib/rakuos/rum-overlay/work \
    && chmod 755 /var/lib/rakuos/rum-overlay \
    && chcon -t var_t /var/lib/rakuos -R

# =============================================================================
# 3. Create split rpmdb structure
#    Base rpmdb: /usr/share/rpm (read-only in base)
#    Overlay rpmdb: /var/lib/rakuos/rum-rpmdb (persistent)
#    Both unioned at query time via rpm config
# =============================================================================
RUN mkdir -p /var/lib/rakuos/rum-rpmdb \
    && chmod 755 /var/lib/rakuos/rum-rpmdb

# Copy base rpm database as reference (for queries and dependency resolution)
RUN cp -a /usr/share/rpm /var/lib/rakuos/rum-rpmdb/base-rpmdb \
    && chcon -t rpm_db_t /var/lib/rakuos/rum-rpmdb/base-rpmdb -R

# =============================================================================
# 4. Create RPM configuration for split mode
#    Tells rpm to read from both databases when querying
#    Writes new packages only to overlay rpmdb
# =============================================================================
RUN mkdir -p /etc/rpm \
    && cat > /etc/rpm/rpmrc << 'EOF'
# RakuOS-style split rpmdb configuration
# Based on rum's architecture

# Where to write new packages and transactions
_rpmdbpath /var/lib/rakuos/rum-rpmdb

# Query paths (union of base and overlay at resolution time)
# In standalone mode (outside overlay system), this defaults to single db
# In RakuOS mode, the overlay-aware layer handles merging

# Preserve SELinux file contexts
__fileattrs_mask 0x0000001f

# Compatibility settings
_vendor fedora
_os linux
EOF

# =============================================================================
# 5. Create dracut module for early overlay mount
#    Mounts overlay OVER /usr BEFORE switch_root completes
#    This allows even akmods and DKMS modules to work properly
# =============================================================================
RUN mkdir -p /usr/lib/dracut/modules.d/99rum-overlay

# Module setup script
RUN cat > /usr/lib/dracut/modules.d/99rum-overlay/module-setup.sh << 'MODULESETUP'
#!/bin/bash
# Dracut module setup for RakuOS-style /usr overlay

check() {
    return 0
}

depends() {
    # Run after ostree and basic filesystem modules
    echo base rootfs-block
    return 0
}

install() {
    # Install the hook script at priority 50 (after filesystem setup)
    inst_hook preempt-mount 50 "$moddir/mount-overlay-usr.sh"
    
    # Install necessary binaries
    inst_binary mount
    inst_binary mkdir
    inst_binary ls
    
    # Copy overlay directory structure into initramfs if present
    if [ -d "/sysroot/var/lib/rakuos/rum-overlay" ]; then
        inst_directory /var/lib/rakuos/rum-overlay /var/lib/rakuos/rum-overlay
    fi
}
MODULESETUP
chmod +x /usr/lib/dracut/modules.d/99rum-overlay/module-setup.sh

# The actual mount script - runs early in initramfs
RUN cat > /usr/lib/dracut/modules.d/99rum-overlay/mount-overlay-usr.sh << 'MOUNTSCRIPT'
#!/bin/sh
# Mount overlayfs over /usr in early boot
# This runs BEFORE switch_root, allowing overlay to be active for entire system

log_info() {
    echo "[rum-overlay] $*"
}

log_err() {
    echo "[rum-overlay ERROR] $*" >&2
}

# Check if overlay already mounted (idempotent)
if grep -q "overlay /usr" /proc/mounts 2>/dev/null; then
    log_info "/usr already mounted with overlay, skipping"
    exit 0
fi

# Determine sysroot location
SYSROOT="/sysroot"
if [ ! -d "$SYSROOT" ]; then
    log_err "/sysroot not found, cannot proceed"
    exit 1
fi

# Overlay directories on the persistent partition
OVERLAY_BASE="$SYSROOT/var/lib/rakuos/rum-overlay"
UPPER_DIR="$OVERLAY_BASE/usr"
WORK_DIR="$OVERLAY_BASE/work"

# Verify overlay directories exist
if [ ! -d "$UPPER_DIR" ]; then
    log_info "Creating upper directory: $UPPER_DIR"
    mkdir -p "$UPPER_DIR"
fi

if [ ! -d "$WORK_DIR" ]; then
    log_info "Creating work directory: $WORK_DIR"
    mkdir -p "$WORK_DIR"
fi

# Create lower overlay directory for tracking purposes
LOWER_OVERLAY="$SYSROOT/usr/.rum-overlay-lower"
mkdir -p "$LOWER_OVERLAY" 2>/dev/null || true

# Mount overlay over /usr
# Note: /usr is typically a symlink to /sysroot/usr in initramfs
log_info "Mounting overlay over /usr"
log_info "  lowerdir=$SYSROOT/usr"
log_info "  upperdir=$UPPER_DIR"
log_info "  workdir=$WORK_DIR"

mount -t overlay overlay \
    -o lowerdir=$SYSROOT/usr,upperdir=$UPPER_DIR,workdir=$WORK_DIR \
    /usr

if [ $? -eq 0 ]; then
    log_info "Successfully mounted overlay over /usr"
else
    log_err "Failed to mount overlay over /usr"
    exit 1
fi
MOUNTSCRIPT
chmod +x /usr/lib/dracut/modules.d/99rum-overlay/mount-overlay-usr.sh

# =============================================================================
# 6. Create dracut configuration to force module inclusion
# =============================================================================
RUN mkdir -p /etc/dracut.conf.d \
    && cat > /etc/dracut.conf.d/99rum-overlay.conf << 'EOF'
# Force inclusion of rum-overlay module
add_dracutmodules+=" 99rum-overlay "
EOF

# =============================================================================
# 7. Create dnf5 configuration for split mode operation
# =============================================================================
RUN mkdir -p /etc/dnf \
    && cat > /etc/dnf/dnf.conf << 'EOF'
[main]
gpgcheck=1
install_weak_deps=False
excludepkgs=kernel*,grub*,ostree*
metadata_expire=3h
refresh_package_metadata=True

# RakuOS-style split rpmdb mode
# When in overlay system, dnf operates on overlay rpmdb
# When in standalone mode, operates on single rpmdb
var_subdir=/var/lib/rakuos/rum-rpmdb

# Preserve SELinux contexts during installs
tsflags=nodocs,noscripts

[fedora]
name=Fedora $releasever - $basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-primary
gpgcheck=1

[updates]
name=Fedora $releasever - $basearch - Updates
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-primary
gpgcheck=1
EOF

# =============================================================================
# 8. Create rum wrapper script (dnf5-compatible)
#    Detects if running in overlay system or standalone mode
# =============================================================================
RUN cat > /usr/bin/rum << 'RUMWRAPPER'
#!/bin/bash
# RakuOS-style rum wrapper for dnf5
# Detects split-mode vs standalone operation

set -e

# Configuration paths
OVERLAY_RPMDB="/var/lib/rakuos/rum-rpmdb"
BASE_RPMDB="/usr/share/rpm"
OVERLAY_ACTIVE="/var/run/rum-overlay-active"

# Detection function
detect_mode() {
    if [ -f "$OVERLAY_ACTIVE" ] || mountpoint -q /usr; then
        echo "overlay"
    elif [ -d "$OVERLAY_RPMDB" ]; then
        echo "standalone"
    else
        echo "standard"
    fi
}

MODE=$(detect_mode)

case "$MODE" in
    "overlay")
        # Running in RakuOS-style overlay mode
        # dnf5 operates with overlay-aware rpmdb
        export RPMDBPATH="$OVERLAY_RPMDB"
        exec dnf5 "$@"
        ;;
    "standalone")
        # Running outside overlay system, use standalone mode
        # Single rpmdb, no split logic
        exec dnf5 --nodocs "$@"
        ;;
    "standard")
        # Standard Fedora, just use dnf5 normally
        exec dnf5 "$@"
        ;;
esac
RUMWRAPPER
chmod +x /usr/bin/rum

# =============================================================================
# 9. Create helper scripts for overlay management
# =============================================================================
RUN cat > /usr/local/bin/rum-reset << 'RESETSCRIPT'
#!/bin/bash
# Reset overlay to pristine state
# WARNING: Removes all packages installed in overlay

set -e

OVERLAY_UPPER="/var/lib/rakuos/rum-overlay/usr"
OVERLAY_WORK="/var/lib/rakuos/rum-overlay/work"
OVERLAY_RPMDB="/var/lib/rakuos/rum-rpmdb"

echo "Resetting rum overlay..."
rm -rf "$OVERLAY_UPPER"/*
rm -rf "$OVERLAY_WORK"/*
rm -rf "${OVERLAY_RPMDB:?}/"*"/installed"

echo "Overlay reset complete. All overlay packages removed."
echo "System will return to base image state after reboot."
RESETSCRIPT
chmod +x /usr/local/bin/rum-reset

# =============================================================================
# 10. Regenerate initramfs with overlay module included
# =============================================================================
RUN dracut --force --add 99rum-overlay

# =============================================================================
# 11. Final verification and cleanup
# =============================================================================
RUN rm -rf /var/cache/dnf/* \
    && rm -rf /tmp/* \
    && dnf5 clean all



























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
