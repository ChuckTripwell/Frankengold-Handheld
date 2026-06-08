##################################################################################################################################################
### :::::: pull cachyos :::::: ###
##################################################################################################################################################
FROM docker.io/cachyos/cachyos-v3:latest AS cachyos

# :::::: prepare the kernel :::::: 
RUN rm -rf /lib/modules/*
RUN pacman -Sy --noconfirm archlinux-keyring cachyos-keyring
RUN pacman -Sy --noconfirm
RUN pacman -S --noconfirm linux-cachyos-deckify

##################################################################################################################################################
### :::::: pull ublue-os :::::: ###
##################################################################################################################################################
FROM ghcr.io/ublue-os/bazzite-deck:stable

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

##################################################################################################################################################
# :::::: experimental :::::: ###
##################################################################################################################################################

# :::::: install preformence-related stuff :::::: 
RUN dnf5 -y copr enable bieszczaders/kernel-cachyos-addons
RUN dnf5 -y install --allowerasing scx-scheds scx-tools scxctl cachyos-settings uksmd scx-manager
RUN dnf5 -y copr disable bieszczaders/kernel-cachyos-addons

# :::::: refresh akmods so that some drivers actually catch... :::::: 
RUN dnf5 -y install rpmdevtools akmods

##################################################################################################################################################
### :::::: end of experimental :::::: ###
##################################################################################################################################################



# :::::: Enable Terra Repo :::::: 
RUN sed -i 's/^enabled=0$/enabled=1/' /etc/yum.repos.d/terra*

# :::::: install additional stuff :::::: 
RUN dnf5 -y install --allowerasing python3-pygame
RUN dnf5 -y install --allowerasing tlp
  RUN systemctl enable tlp.service
RUN dnf5 -y install --allowerasing zcfan


# :::::: Replace Malfunctioning SELinux With Apparmor Profiles & Stage Kargs :::::: 

RUN dnf5 install -y apparmor-parser apparmor-utils
RUN dnf5 install -y apparmor-profiles || true

RUN mkdir -p /etc/apparmor.d /usr/lib64 /etc/systemd/system /var/lib

COPY --from=cachyos /usr/bin/apparmor_parser /usr/bin/apparmor_parser
COPY --from=cachyos /usr/lib/libapparmor.so* /usr/lib64/
COPY --from=cachyos /etc/apparmor.d/ /etc/apparmor.d/

RUN echo '[Unit]' > /etc/systemd/system/apparmor-activator.service
RUN echo 'Description=AppArmor Argument and Profile Activator' >> /etc/systemd/system/apparmor-activator.service
RUN echo 'ConditionPathExists=!/var/.apparmor_activated' >> /etc/systemd/system/apparmor-activator.service
RUN echo 'After=multi-user.target' >> /etc/systemd/system/apparmor-activator.service
RUN echo '' >> /etc/systemd/system/apparmor-activator.service
RUN echo '[Service]' >> /etc/systemd/system/apparmor-activator.service
RUN echo 'Type=oneshot' >> /etc/systemd/system/apparmor-activator.service
RUN echo 'ExecStart=/usr/bin/bash -c "if ! grep -q \"security=apparmor\" /proc/cmdline; then rpm-ostree kargs --append-if-missing=\"security=apparmor\" --append-if-missing=\"lsm=landlock,lockdown,yama,integrity,apparmor,bpf\"; fi; touch /var/.apparmor_activated"' >> /etc/systemd/system/apparmor-activator.service
RUN echo 'ExecStartPost=/usr/bin/bash -c "if [ -d /etc/apparmor.d ]; then /usr/bin/apparmor_parser -r -W /etc/apparmor.d/; fi"' >> /etc/systemd/system/apparmor-activator.service
RUN echo 'ExecStartPost=/usr/bin/bash -c "for i in {1..30}; do TARGET_UID=\$(loginctl list-users | awk \"NR==2 {print \\\$1}\"); if [ -n \"\$TARGET_UID\" ] && [ -S /run/user/\"\$TARGET_UID\"/bus ]; then sudo -u \"#\$TARGET_UID\" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/\"\$TARGET_UID\"/bus kdialog --title \"System Security Update\" --passivepopup \"AppArmor configuration has been staged. Please reboot your system to apply changes.\" 10 || true; break; fi; sleep 2; done &"' >> /etc/systemd/system/apparmor-activator.service
RUN echo '' >> /etc/systemd/system/apparmor-activator.service
RUN echo '[Install]' >> /etc/systemd/system/apparmor-activator.service
RUN echo 'WantedBy=multi-user.target' >> /etc/systemd/system/apparmor-activator.service

RUN systemctl enable apparmor-activator.service


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
