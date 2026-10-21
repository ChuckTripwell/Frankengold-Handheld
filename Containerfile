##################################################################################################################################################
### :::::: Pull Kernel:::::: ###
##################################################################################################################################################
FROM ghcr.io/ublue-os/base-main:latest AS ublue_os

# :::::: prepare the kernel :::::: 
RUN rm -rf /lib/modules/*
RUN dnf5 copr -y enable catpieleaf/kernel-p03
RUN dnf5 -y install --setopt=tsflags=noscripts kernel-p03-deck

##################################################################################################################################################
### :::::: Pull Ublue-OS :::::: ###
##################################################################################################################################################
#FROM ghcr.io/ublue-os/bazzite-deck:latest AS system
FROM quay.io/rakuos/rakuos-gamescope-v3:staging AS system

# :::::: forcefully remove and replace kernel :::::: 
RUN rm -rf /lib/modules
COPY --from=ublue_os /lib/modules /lib/modules
COPY --from=ublue_os /usr/share/licenses/ /usr/share/licenses/

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






##################################################################################################################################################
### :::::: Selinux :::::: ###
##################################################################################################################################################

# tell Grub to add kargs - without them SELinux and nvidia-drivers might not work
  RUN echo 'kargs = ["lsm=landlock,lockdown,yama,integrity,selinux,bpf", "selinux=1", "enforcing=0", "selinux_dontaudit=0", "selinux_deny_unknown=1", "apparmor=0"]' > /usr/lib/bootc/kargs.d/90-security-overrides.toml



# 1) Policy RPMs (same ones Bazzite ships)
RUN dnf -y install \
        selinux-policy-targeted \
        policycoreutils \
        policycoreutils-python-utils \
        libselinux-utils \
    && dnf clean all

# 2) Enforcing + targeted (Bazzite-exact config)
RUN mkdir -p /etc/selinux \
    && printf 'SELINUX=enforcing\nSELINUXTYPE=targeted\n' > /etc/selinux/config

# 3) First-boot relabel (marker + bootc karg)
RUN touch /.autorelabel \
    && mkdir -p /usr/lib/bootc \
    && echo 'kargs = ["autorelabel=1"]' > /usr/lib/bootc/kargs.toml

# ── SELinux fs early mount — enabled by symlink, no systemctl ────────────
RUN install -d /etc/systemd/system /etc/systemd/system/sysinit.target.wants \
 && printf '%s\n' \
      '[Unit]' \
      'Description=SELinux File System' \
      'DefaultDependencies=no' \
      'Before=sysinit.target local-fs.target' \
      'ConditionSecurity=selinux' \
      '' \
      '[Mount]' \
      'What=selinuxfs' \
      'Where=/sys/fs/selinux' \
      'Type=selinuxfs' \
      'Options=defaults' \
      '' \
      '[Install]' \
      'WantedBy=sysinit.target' \
    > /etc/systemd/system/sys-fs-selinux.mount \
 && ln -sf ../sys-fs-selinux.mount /etc/systemd/system/sysinit.target.wants/sys-fs-selinux.mount#



RUN mkdir -p /usr/share/selinux/ 
COPY --from=ublue_os /usr/share/selinux/ /usr/share/selinux/
#RUN mkdir -p /usr/share/selinux-policy/
#COPY --from=ublue_os /usr/share/selinux-policy/ /usr/share/selinux-policy/
#RUN mkdir -p /usr/lib/selinux/
#COPY --from=ublue_os /usr/lib/selinux/ /usr/lib/selinux/








RUN semanage fcontext -d "/usr/bin/ostree" 2>/dev/null || true \
 && semanage fcontext -d "/usr/bin(/.*)?" 2>/dev/null || true

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
