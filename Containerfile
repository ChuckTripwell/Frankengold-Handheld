##################################################################################################################################################
### :::::: pull cachyos :::::: ###
##################################################################################################################################################
FROM docker.io/cachyos/cachyos-v3:latest AS cachyos

# :::::: prepare the kernel :::::: 
RUN rm -rf /lib/modules/*
RUN pacman -Sy --disable-sandbox --noconfirm archlinux-keyring cachyos-keyring
RUN pacman -Sy --disable-sandbox --noconfirm
RUN pacman -S --disable-sandbox --noconfirm linux-cachyos-deckify

# install AppArmor for later
  RUN pacman -S --disable-sandbox --noconfirm apparmor apparmor.d

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

# :::::: Enable Terra Repo :::::: 
#RUN sed -i 's/^enabled=0$/enabled=1/' /etc/yum.repos.d/terra*

# :::::: Replace Malfunctioning SELinux With Apparmor Profiles & Stage Kargs :::::: 
#RUN dnf5 install -y apparmor-parser apparmor-utils apparmor-profiles

# :::::: Disable Terra Repo :::::: 
#RUN sed -i 's/^enabled=1$/enabled=0/' /etc/yum.repos.d/terra*

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

# :::::: Replace Malfunctioning SELinux With Apparmor Profiles & Stage Kargs :::::: 

RUN dnf5 -y install apparmor apparmor-utils apparmor-profiles

RUN mkdir -p /etc/apparmor.d

COPY --from=cachyos /usr/bin/apparmor_parser /usr/bin/apparmor_parser
COPY --from=cachyos /etc/apparmor.d/ /etc/apparmor.d/

# AppArmor Kernel Arguments Service (Delays until graphical interface is ready)
RUN SERVICE_FILE="/usr/lib/systemd/system/activate-apparmor.service" && \
    echo "[Unit]" > "$SERVICE_FILE" && \
    echo "Description=Enable AppArmor Kernel Arguments" >> "$SERVICE_FILE" && \
    echo "ConditionPathExists=!/etc/.apparmor_is_activated.lock" >> "$SERVICE_FILE" && \
    echo "DefaultDependencies=no" >> "$SERVICE_FILE" && \
    echo "After=graphical.target" >> "$SERVICE_FILE" && \
    echo "" >> "$SERVICE_FILE" && \
    echo "[Service]" >> "$SERVICE_FILE" && \
    echo "Type=oneshot" >> "$SERVICE_FILE" && \
    echo "RemainAfterExit=yes" >> "$SERVICE_FILE" && \
    echo "ExecStart=/usr/bin/sh -c '/usr/bin/rpm-ostree kargs | grep -q apparmor || /usr/bin/rpm-ostree kargs --append=lsm=landlock,lockdown,yama,integrity,apparmor'" >> "$SERVICE_FILE" && \
    echo "ExecStartPost=/usr/bin/touch /etc/.apparmor_is_activated.lock" >> "$SERVICE_FILE" && \
    echo "" >> "$SERVICE_FILE" && \
    echo "[Install]" >> "$SERVICE_FILE" && \
    echo "WantedBy=graphical.target" >> "$SERVICE_FILE"

# Enable the Kernel Arguments Service
RUN mkdir -p /usr/lib/systemd/system/graphical.target.wants && \
    ln -s /usr/lib/systemd/system/activate-apparmor.service /usr/lib/systemd/system/graphical.target.wants/activate-apparmor.service

# AppArmor Profile Parser Service (Delays until graphical interface is ready)
RUN LOADER_FILE="/usr/lib/systemd/system/apparmor-profile-loader.service" && \
    echo "[Unit]" > "$LOADER_FILE" && \
    echo "Description=AppArmor Profile Parser" >> "$LOADER_FILE" && \
    echo "After=graphical.target" >> "$LOADER_FILE" && \
    echo "" >> "$LOADER_FILE" && \
    echo "[Service]" >> "$LOADER_FILE" && \
    echo "Type=oneshot" >> "$LOADER_FILE" && \
    echo "RemainAfterExit=yes" >> "$LOADER_FILE" && \
    echo "ExecStart=/usr/bin/bash -c 'if [ -d /etc/apparmor.d ]; then /usr/bin/apparmor_parser -r -W /etc/apparmor.d/; fi'" >> "$LOADER_FILE" && \
    echo "" >> "$LOADER_FILE" && \
    echo "[Install]" >> "$LOADER_FILE" && \
    echo "WantedBy=graphical.target" >> "$LOADER_FILE"

# Enable the Profile Parser Service
RUN mkdir -p /usr/lib/systemd/system/graphical.target.wants && \
    ln -s /usr/lib/systemd/system/apparmor-profile-loader.service /usr/lib/systemd/system/graphical.target.wants/apparmor-profile-loader.service


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
