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

RUN dnf5 -y install dnf5-plugins
RUN rpm --import https://repo.rakuos.org/pubkey.gpg
RUN dnf5 -y config-manager addrepo --from-repofile=https://repo.rakuos.org/rakuos.repo

RUN dnf5 -y install rakuos-rum rum-dnf-shim

##################################################################################################################################################
### :::::: Security and Finalization :::::: ###
##################################################################################################################################################

# :::::: Fix SELinux :::::: 
#
#RUN sed -i 's/^SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config
#
#RUN touch /etc/.autorelabel
#
RUN mkdir -p /usr/lib/bootc/kargs.d/
#RUN sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/lib/systemd/system/selinux-autorelabel-mark.service
#RUN sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/libexec/selinux/selinux-autorelabel
#RUN sed -i 's|/\.autorelabel|/etc/.autorelabel|g' /usr/lib/systemd/system-generators/selinux-autorelabel-generator.sh
#RUN echo 'kargs = ["lsm=landlock,lockdown,yama,integrity,selinux,bpf", "selinux=1", "enforcing=1", "selinux_dontaudit=0", "selinux_deny_unknown=1"]' > /usr/lib/bootc/kargs.d/90-security-overrides.toml
#
#RUN sed -i 's/active = yes/active = no/' /etc/audit/plugins.d/sedispatch.conf
#
# :::::: slot the kernel into place :::::: 
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
