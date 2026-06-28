##################################################################################################################################################
### :::::: pull cachyos :::::: ###
##################################################################################################################################################
FROM docker.io/cachyos/cachyos-v3:latest AS cachyos

# :::::: prepare the kernel :::::: 
RUN rm -rf /lib/modules/*
RUN pacman -Sy --disable-sandbox --noconfirm archlinux-keyring cachyos-keyring
RUN pacman -Sy --disable-sandbox --noconfirm
RUN pacman -S --disable-sandbox --noconfirm linux-cachyos-deckify

##################################################################################################################################################
### :::::: pull ublue-os :::::: ###
##################################################################################################################################################
FROM ghcr.io/ublue-os/bazzite-deck:latest

# :::::: force distrobox to use a sub-directory for home :::::: 
RUN mkdir -p /usr/share/distrobox/
RUN touch /usr/share/distrobox/distrobox.conf
RUN echo "DBX_CONTAINER_HOME_PREFIX=~/distrobox" >> /usr/share/distrobox/distrobox.conf

# :::::: Set vm.max_map_count for stability/improved gaming performance  - experimental! ::::::
# :::::: https://wiki.archlinux.org/title/Gaming#Increase_vm.max_map_count :::::: 
#RUN echo -e "vm.max_map_count = 2147483642" > /etc/sysctl.d/80-gamecompatibility.conf
#RUN echo "vm.swappiness=10" >> /etc/sysctl.conf
#RUN echo "kernel.sched_migration_cost_ns=5000000" >> /etc/sysctl.conf

# :::::: disable countme ( I like my telemetry opt-in,thank you very much. you can enable it if you want... ) :::::: 
RUN sed -i -e s,countme=1,countme=0, /etc/yum.repos.d/*.repo && systemctl mask --now rpm-ostree-countme.timer

# :::::: forcefully remove and replace kernel :::::: 
RUN rm -rf /lib/modules
COPY --from=cachyos /lib/modules /lib/modules
COPY --from=cachyos /usr/share/licenses/ /usr/share/licenses/

# :::::: install preformence-related stuff :::::: 
RUN dnf5 -y copr enable bieszczaders/kernel-cachyos-addons
RUN dnf5 -y install --allowerasing scx-scheds scx-tools scxctl cachyos-settings uksmd scx-manager
RUN dnf5 -y copr disable bieszczaders/kernel-cachyos-addons

# :::::: refresh akmods so that some drivers actually catch... :::::: 
RUN dnf5 -y install rpmdevtools akmods

# :::::: install additional stuff :::::: 
RUN dnf5 -y install --allowerasing python3-pygame
RUN dnf5 -y install --allowerasing zcfan

# :::::: Fix Vulkan :::::: 
RUN TMPDIR="$(mktemp -d)" && \
    dnf5 download "VK_hdr_layer" --destdir "$TMPDIR" && \
    RPM_FILE=$(ls "$TMPDIR"/*.rpm) && \
    mkdir "$TMPDIR/VK_hdr_layer" && \
    cd "$TMPDIR/VK_hdr_layer" && \
    # Extract RPM
    rpm2cpio "$RPM_FILE" | cpio -idmv && \
    # Libraries
    mkdir -p /usr/lib64/VK_hdr_layer && \
    cp -v usr/lib64/VK_hdr_layer/* /usr/lib64/VK_hdr_layer/ && \
    # Vulkan implicit layer
    mkdir -p /usr/share/vulkan/implicit_layer.d && \
    mkdir -p /usr/share/vulkan/implicit_layer.d && \
    cp -v usr/share/vulkan/implicit_layer.d/VkLayer_hdr_wsi.*.json /usr/share/vulkan/implicit_layer.d/ && \
    # License & Docs
    mkdir -p /usr/share/licenses/VK_hdr_layer && \
    cp -v usr/share/licenses/VK_hdr_layer/* /usr/share/licenses/VK_hdr_layer/ && \
    mkdir -p /usr/share/doc/VK_hdr_layer && \
    cp -v usr/share/doc/VK_hdr_layer/* /usr/share/doc/VK_hdr_layer/

# :::::: Fix SELinux :::::: 

RUN echo '[Unit]' > /etc/systemd/system/selinux-activate.service
RUN echo 'Description=Activate SELinux kernel arguments once after graphical boot' >> /etc/systemd/system/selinux-activate.service
RUN echo 'After=graphical.target' >> /etc/systemd/system/selinux-activate.service
RUN echo 'Wants=graphical.target' >> /etc/systemd/system/selinux-activate.service
RUN echo 'ConditionPathExists=!/etc/.selinux_is_activated.lock' >> /etc/systemd/system/selinux-activate.service
RUN echo '' >> /etc/systemd/system/selinux-activate.service
RUN echo '[Service]' >> /etc/systemd/system/selinux-activate.service
RUN echo 'Type=oneshot' >> /etc/systemd/system/selinux-activate.service
RUN echo 'ExecStart=/bin/sh -c '\''/usr/sbin/restorecon -R /var/log && rpm-ostree kargs --append="lsm=landlock,lockdown,yama,integrated,selinux,bpf" --append="selinux=1" --append="enforcing=1" --append="selinux_dontaudit=0" --append="selinux_deny_unknown=1" && touch /etc/.selinux_is_activated.lock'\''' >> /etc/systemd/system/selinux-activate.service
RUN echo 'RemainAfterExit=yes' >> /etc/systemd/system/selinux-activate.service
RUN echo '' >> /etc/systemd/system/selinux-activate.service
RUN echo '[Install]' >> /etc/systemd/system/selinux-activate.service
RUN echo 'WantedBy=graphical.target' >> /etc/systemd/system/selinux-activate.service
RUN systemctl enable selinux-activate.service

RUN restorecon -R -v -F /etc


#RUN echo '[Unit]' > /etc/systemd/system/var-labeling.service
#RUN echo 'Description=Run SELinux relabeling of /var once after graphical boot' >> /etc/systemd/system/var-labeling.service
#RUN echo 'After=graphical.target' >> /etc/systemd/system/var-labeling.service
#RUN echo 'Wants=graphical.target' >> /etc/systemd/system/var-labeling.service
#RUN echo 'ConditionPathExists=/etc/.labeling_complete.lock' >> /etc/systemd/system/var-labeling.service
#RUN echo 'ConditionPathExists=!/etc/.var_labeling_complete.lock' >> /etc/systemd/system/var-labeling.service
#RUN echo '' >> /etc/systemd/system/var-labeling.service
#RUN echo '[Service]' >> /etc/systemd/system/var-labeling.service
#RUN echo 'Type=oneshot' >> /etc/systemd/system/var-labeling.service
#RUN echo 'ExecStart=/bin/sh -c '\''/usr/bin/restorecon -R -F -e /var/lib/flatpak -e /var/lib/containers /var && touch /etc/.var_labeling_complete.lock'\''' >> /etc/systemd/system/var-labeling.service
#RUN echo 'RemainAfterExit=yes' >> /etc/systemd/system/var-labeling.service
#RUN echo '' >> /etc/systemd/system/var-labeling.service
#RUN echo '[Install]' >> /etc/systemd/system/var-labeling.service
#RUN echo 'WantedBy=graphical.target' >> /etc/systemd/system/var-labeling.service
#RUN systemctl enable var-labeling.service


RUN systemctl mask sedispatch.service


# :::::: slot the kernel into place :::::: 
RUN mkdir -p /var/tmp
RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

#  :::::: finish :::::: 
RUN rm -rf /usr/etc
LABEL containers.bootc 1
RUN bootc container lint
