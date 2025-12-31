FROM docker.io/cachyos/cachyos-v3:latest AS cachyos
RUN rm -rf /lib/modules/*
RUN pacman -Sy --noconfirm
RUN pacman -S --noconfirm linux-cachyos-deckify


FROM ghcr.io/ublue-os/bazzite-deck:latest
RUN rm -rf /lib/modules
COPY --from=cachyos /lib/modules /lib/modules
COPY --from=cachyos /usr/share/licenses/ /usr/share/licenses/

#
# noaudio fix
#
# Create the service directly
RUN echo '[Unit]
Description=Run alsactl init at first login after boot - to fix no audio glitch
After=default.target

[Service]
Type=oneshot
ExecStart=/usr/bin/alsactl init"
RemainAfterExit=yes

[Install]
WantedBy=default.target' > /etc/systemd/system/alsactl-init.service

# Enable the service
RUN systemctl enable alsactl-init.service


#
# disable countme
RUN sed -i -e s,countme=1,countme=0, /etc/yum.repos.d/*.repo && systemctl mask --now rpm-ostree-countme.timer

# finish
ENV DRACUT_NO_XATTR=1
RUN mkdir -p /var/tmp
RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

RUN bootc container lint
