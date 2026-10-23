##################################################################################################################################################
### :::::: Pull CachyOS :::::: ###
##################################################################################################################################################
FROM docker.io/pkgforge/cachyos-base:x86_64 AS cachyos

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
FROM ghcr.io/ublue-os/bazzite-deck:latest

# :::::: forcefully remove and replace kernel :::::: 
RUN rm -rf /lib/modules
COPY --from=cachyos /lib/modules /lib/modules
COPY --from=cachyos /usr/share/licenses/ /usr/share/licenses/

##################################################################################################################################################
### :::::: Modifications :::::: ###
##################################################################################################################################################
# :::::: disable countme ( I like my telemetry opt-in,thank you very much. you can enable it if you want... ) :::::: 
RUN sed -i -e s,countme=1,countme=0, /etc/yum.repos.d/*.repo && systemctl mask --now rpm-ostree-countme.timer || true

# :::::: force distrobox to use a sub-directory for home :::::: 
RUN mkdir -p /usr/share/distrobox/
RUN touch /usr/share/distrobox/distrobox.conf
RUN echo "DBX_CONTAINER_HOME_PREFIX=~/distrobox" >> /usr/share/distrobox/distrobox.conf


# :::::: install preformence-related stuff :::::: 
RUN dnf5 -y copr enable bieszczaders/kernel-cachyos-addons
  RUN dnf5 -y install --allowerasing scx-scheds || true 
  RUN dnf5 -y install --allowerasing scx-tools || true
  RUN dnf5 -y install --allowerasing scxctl || true
  RUN dnf5 -y install --allowerasing cachyos-settings || true
  RUN dnf5 -y install --allowerasing uksmd scx-manager || true
RUN dnf5 -y copr disable bieszczaders/kernel-cachyos-addons

# :::::: Small fixes ::::::
# Set vm.max_map_count for stability/improved gaming performance
# https://wiki.archlinux.org/title/Gaming#Increase_vm.max_map_count
  RUN echo -e "vm.max_map_count = 2147483642" > /etc/sysctl.d/80-gamecompatibility.conf

##################################################################################################################################################
### :::::: Security and Finalization :::::: ###
##################################################################################################################################################
#
# :::::: slot the kernel into place :::::: 
RUN mkdir -p /var/tmp
RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \      
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \      
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -mindepth 1 -type d | tail -n 1)")" && \
      depmod -a "$KERNEL_VERSION" && \      
      dracut --force --no-hostonly --reproducible --zstd --verbose "/usr/lib/modules/$KERNEL_VERSION/initramfs.img" "$KERNEL_VERSION"'
#
#  :::::: finish :::::: 
RUN rm -rf /usr/etc
LABEL containers.bootc 1
RUN bootc container lint
