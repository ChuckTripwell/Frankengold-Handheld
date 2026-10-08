FROM ghcr.io/ublue-os/bazzite-deck:stable


RUN wget https://copr.fedorainfracloud.org/coprs/catpieleaf/kernel-p03/repo/fedora-$(rpm -E %fedora)/catpieleaf-kernel-p03-$(rpm -E %fedora).repo -O /etc/yum.repos.d/catpieleaf-kernel-p03.repo

RUN dnf5 remove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra 
RUN dnf5 install kernel-p03



##################################################################################################################################################
### :::::: Modifications :::::: ###
##################################################################################################################################################
# :::::: disable countme ( I like my telemetry opt-in,thank you very much. you can enable it if you want... ) :::::: 
RUN sed -i -e s,countme=1,countme=0, /etc/yum.repos.d/*.repo && systemctl mask --now rpm-ostree-countme.timer

# :::::: install controld dns :::::: 
RUN curl -fsSL https://dl.controld.com/linux-amd64/ctrld \
    -o /usr/bin/ctrld && \
    chmod 755 /usr/bin/ctrld

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
#  :::::: finish :::::: 
RUN rm -rf /usr/etc
LABEL containers.bootc 1
RUN bootc -h
RUN bootc container lint
