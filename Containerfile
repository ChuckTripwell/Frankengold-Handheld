FROM docker.io/cachyos/cachyos-v3:latest AS cachyos
RUN rm -rf /lib/modules/*
RUN pacman -Sy --noconfirm linux-cachyos-deckify

FROM ghcr.io/ublue-os/bazzite-deck:latest
RUN rm -rf /lib/modules
COPY --from=cachyos /lib/modules /lib/modules
COPY --from=cachyos /usr/share/licenses/ /usr/share/licenses/


RUN mkdir -p /lib/firmware/amd/sof
RUN mkdir -p /usr/share/alsa/ucm2


COPY --from=cachyos /lib/firmware/amd/sof /lib/firmware/amd/sof
COPY --from=cachyos /usr/share/alsa/ucm2 /usr/share/alsa/ucm2
COPY --from=cachyos /etc/asound.conf /etc/asound.conf
COPY --from=cachyos /etc/pipewire/pipewire.conf /etc/pipewire/pipewire.conf
COPY --from=cachyos /etc/pipewire/pipewire-pulse.conf /etc/pipewire/pipewire-pulse.conf



ENV DRACUT_NO_XATTR=1
RUN mkdir -p /var/tmp
RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'


RUN bootc container lint
