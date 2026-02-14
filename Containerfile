##################################################################################################################################################
### :::::: pull cachyos :::::: ###
##################################################################################################################################################
FROM docker.io/cachyos/cachyos-v3:latest AS cachyos

# :::::: prepare the kernel :::::: 
RUN rm -rf /lib/modules/*
RUN pacman -Sy --noconfirm
RUN pacman -S --noconfirm linux-cachyos-deckify

##################################################################################################################################################
### :::::: pull ublue-os :::::: ###
##################################################################################################################################################
FROM ghcr.io/ublue-os/bazzite-deck:latest

# :::::: force distrobox to use a sub-directory for home :::::: 
RUN mkdir -p /usr/share/distrobox/
RUN touch /usr/share/distrobox/distrobox.conf
RUN echo "DBX_CONTAINER_HOME_PREFIX=$HOME/distrobox" >> /usr/share/distrobox/distrobox.conf

# :::::: Set vm.max_map_count for stability/improved gaming performance :::::: 
# :::::: https://wiki.archlinux.org/title/Gaming#Increase_vm.max_map_count :::::: 
RUN echo -e "vm.max_map_count = 2147483642" > /etc/sysctl.d/80-gamecompatibility.conf
RUN echo "vm.swappiness=10" >> /etc/sysctl.conf
RUN echo "kernel.sched_migration_cost_ns=5000000" >> /etc/sysctl.conf

# :::::: disable countme ( we always disable it anyway, so this  is to save us time. you can enable it if you want... ) :::::: 
RUN sed -i -e s,countme=1,countme=0, /etc/yum.repos.d/*.repo && systemctl mask --now rpm-ostree-countme.timer

# :::::: forcefully remove and replace kernel :::::: 
RUN rm -rf /lib/modules
COPY --from=cachyos /lib/modules /lib/modules
COPY --from=cachyos /usr/share/licenses/ /usr/share/licenses/

##################################################################################################################################################
# :::::: experimental :::::: ###
##################################################################################################################################################

# :::::: audio fix ::::::

RUN printf "[Unit]\n\
Description=Run alsactl init at boot\n\
After=multi-user.target\n\
\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/sbin/alsactl init\n\
\n\
[Install]\n\
WantedBy=multi-user.target\n" > /etc/systemd/system/alsactl-init.service

RUN systemctl enable alsactl-init.service

RUN printf "ACTION==\"change\", SUBSYSTEM==\"input\", ENV{KEY}==\"114|115\", TAG+=\"systemd\", ENV{SYSTEMD_WANTS}=\"volume-alsactl.service\"\n" \
> /etc/udev/rules.d/99-volume-alsactl.rules /n/ \
printf "[Unit]\n\
Description=Run alsactl init on volume key press\n\
\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/sbin/alsactl init\n" > /etc/systemd/system/volume-alsactl.service

RUN systemctl enable volume-alsactl.service

# :::::: install preformence-related stuff :::::: 
RUN dnf5 -y copr enable bieszczaders/kernel-cachyos-addons
RUN dnf5 -y install --allowerasing scx-scheds scx-tools scxctl cachyos-settings uksmd scx-manager
RUN dnf5 -y copr disable bieszczaders/kernel-cachyos-addons

# :::::: refresh akmods so that some drivers actually catch... :::::: 
RUN dnf5 -y install rpmdevtools akmods

# :::::: install additional stuff :::::: 
RUN dnf5 -y install python3-pygame

##################################################################################################################################################
### :::::: end of experimental :::::: ###
##################################################################################################################################################

# :::::: slot the kernel into place :::::: 
ENV DRACUT_NO_XATTR=1
RUN mkdir -p /var/tmp
RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

#  :::::: finish :::::: 
RUN bootc container lint
