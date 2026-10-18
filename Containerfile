##################################################################################################################################################
### :::::: Pull CachyOS :::::: ###
##################################################################################################################################################
FROM docker.io/pkgforge/cachyos-base:x86_64 AS cachy

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
FROM ghcr.io/ublue-os/kinoite-main:latest AS ublue

# :::::: forcefully remove and replace kernel :::::: 
RUN rm -rf /lib/modules
COPY --from=cachy /lib/modules /lib/modules
COPY --from=cachy /usr/share/licenses/ /usr/share/licenses/

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
RUN dnf5 -y copr enable bieszczaders/kernel-cachyos-addons
    RUN dnf5 -y install --allowerasing scx-scheds scx-tools scxctl cachyos-settings uksmd scx-manager
RUN dnf5 -y copr disable bieszczaders/kernel-cachyos-addons




# Set vm.max_map_count for stability/improved gaming performance
# https://wiki.archlinux.org/title/Gaming#Increase_vm.max_map_count
  RUN echo -e "vm.max_map_count = 2147483642" > /etc/sysctl.d/80-gamecompatibility.conf








# :::::: install rum from rakuos (experimental for now...) :::::: 

RUN dnf5 -y install dnf5-plugins
RUN rpm --import https://repo.rakuos.org/pubkey.gpg
RUN dnf5 -y config-manager addrepo --from-repofile=https://repo.rakuos.org/rakuos.repo
RUN sed -i '/^\[rakuos-v3\]/,/^\[/ s/^enabled=0/enabled=1/' /etc/yum.repos.d/rakuos.repo

RUN dnf5 -y install rakuos-rum rum-dnf-shim




RUN REPO_OWNERS=$(rpm -qf --qf '%{NAME}\n' /usr/share/dnf5/repos.d/*.repo /etc/yum.repos.d/*.repo 2>/dev/null | grep -v 'not owned' | sort -u || true) && \
    if [ -n "$REPO_OWNERS" ]; then \
        rum reinstall -y $REPO_OWNERS || echo "WARNING: couldn't reinstall $REPO_OWNERS; moving their repo files instead"; \
    fi

RUN mkdir -p /usr/share/rum/repos.d

RUN for repo in /usr/share/dnf5/repos.d/*.repo /etc/yum.repos.d/*.repo; do \
    [ -e "$repo" ] || continue; \
    mv -f "$repo" /usr/share/rum/repos.d/; \
done


RUN shipped_repo_files() { \
    local dir; \
    for dir in /usr/share/rum/repos.d /etc/yum.repos.d /usr/share/dnf5/repos.d; do \
        ls "$dir/$1" 2>/dev/null || true; \
    done; \
}








RUN rum install -y --skip-broken --skip-unavailable akonadi-server \
  ${RAKUOS_RELEASE_PKG} \
  steam \
  inputplumber \
  wireplumber \
  steam-devices \
  powerbuttond \
  gamescope \
  gamescope-session \
  gamescope-session-steam \
  jupiter-fan-control \
  jupiter-hw-support \
  steamdeck-dsp \
  steamdeck-firmware

## Remove packages
RUN rum remove -y cardwire || true
RUN rum remove -y firefox || true


RUN systemctl enable inputplumber.service
# steamdeck-dsp: copy the Deck's pipewire/wireplumber hardware profiles
# (speaker DSP filter chain, mic, default-device rules) into /etc at boot
RUN systemctl enable pipewire-sysconf.service
RUN systemctl enable wireplumber-sysconf.service
RUN systemctl enable autologin-setup.service
RUN systemctl mask autologin-setup-plasma.service
RUN systemctl --global enable steamos-powerbuttond.service



RUN mkdir -p /build
RUN git clone --depth 1 --single-branch https://gitlab.com/rakuos/images/rakuos-gamescope /build
RUN cp /build/rakuos-gamescope/system_files/* /

##################################################################################################################################################
### :::::: Security and Finalization :::::: ###
##################################################################################################################################################

# :::::: protect base packages :::::: 
RUN rum mark -y dependency '*'

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

# RUN bootc container lint

LABEL containers.bootc 1
