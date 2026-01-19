FROM docker.io/cachyos/cachyos-v3:latest AS cachyos

RUN rm -rf /lib/modules/*
RUN pacman -Sy --noconfirm
RUN pacman -S --noconfirm linux-cachyos-deckify


FROM ghcr.io/ublue-os/bazzite-deck:latest

#
# force distrobox to use a sub-directory for home
#
RUN mkdir -p /etc/distrobox/
RUN touch /etc/distrobox/distrobox.conf
RUN tee -a DBX_CONTAINER_HOME_PREFIX=$HOME/distrobox >> /etc/distrobox/distrobox.conf

#
# audio fix ( just in case... )
#
### Create autostart service
#RUN printf "[Unit]\n\
#Description=ALSA restore watchdog\n\
#After=multi-user.target\n\n\
#[Service]\n\
#Type=simple\n\
#ExecStart=/usr/bin/alsactl init\n\
#Restart=on-failure\n\
#RestartSec=10\n\
#StartLimitBurst=5\n\
#StartLimitIntervalSec=60\n\
#User=root\n\n\
#[Install]\n\
#WantedBy=multi-user.target\n" > /etc/systemd/system/alsactl-start.service
### enable service
#RUN systemctl enable alsactl-start.service

#RUN printf "[Unit]\n\
#Description=Run alsactl init on volume key press\n\
#After=multi-user.target\n\n\
#\[Service]\n\
#Type=simple\n\
#ExecStart=/bin/sh -c \"/usr/bin/libinput debug-events --device /dev/input/event5 | /usr/bin/awk '/KEY_VOLUME(UP|DOWN).*pressed/ { system(\\\"/usr/bin/alsactl init\\\") }'\"\n\
#Restart=always\n\
#User=root\n\n\
#\[Install]\n\
#WantedBy=multi-user.target\n" > /etc/systemd/system/alsactl-fix.service && \
#systemctl enable alsactl-fix.service

#
# Set vm.max_map_count for stability/improved gaming performance
# https://wiki.archlinux.org/title/Gaming#Increase_vm.max_map_count
#
RUN echo -e "vm.max_map_count = 2147483642" > /etc/sysctl.d/80-gamecompatibility.conf


#
# disable countme ( sorry )
#
RUN sed -i -e s,countme=1,countme=0, /etc/yum.repos.d/*.repo && systemctl mask --now rpm-ostree-countme.timer

RUN rm -rf /lib/modules
COPY --from=cachyos /lib/modules /lib/modules
COPY --from=cachyos /usr/share/licenses/ /usr/share/licenses/




# finish
ENV DRACUT_NO_XATTR=1
RUN mkdir -p /var/tmp
RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

RUN bootc container lint
