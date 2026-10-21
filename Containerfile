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

RUN dnf install -y \
        selinux-policy \
        selinux-policy-targeted \
        policycoreutils \
        libselinux-utils \
        policycoreutils-python-utils \
    && dnf clean all

RUN sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config \
    && sed -i 's/^SELINUXTYPE=.*/SELINUXTYPE=targeted/' /etc/selinux/config

RUN test -f /etc/selinux/targeted/contexts/files/file_contexts







 


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
