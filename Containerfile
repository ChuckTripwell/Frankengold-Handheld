FROM docker.io/cachyos/cachyos-v3:latest AS cachyos
ENV DRACUT_NO_XATTR=1

RUN rm -rf /lib/modules/*
RUN pacman -Sy --noconfirm linux-cachyos-deckify



FROM ghcr.io/ublue-os/bazzite-deck:latest
ENV DRACUT_NO_XATTR=1

RUN dnf5 -y install --allowerasing kmod


RUN rm -rf /lib/modules
COPY --from=cachyos /lib/modules /lib/modules




RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'


RUN bootc container lint
