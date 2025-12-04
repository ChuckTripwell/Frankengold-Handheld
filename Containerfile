##################################################################################
##################################################################################
####this is just a template###
###   please go down to the "Changes go here" section to add your stuff!   ###
##################################################################################
### a complete image will be published every week. ###
##################################################################################
##################################################################################

FROM docker.io/cachyos/cachyos-v3:latest AS builder

pacman -Syy --needed --overwrite "*" --noconfirm rsync

RUN mkdir -p /rootfs  && \  
rsync -aHAX --exclude=/rootfs / /rootfs  && \  
\
curl https://raw.githubusercontent.com/CachyOS/CachyOS-PKGBUILDS/master/cachyos-mirrorlist/cachyos-mirrorlist -o /etc/pacman.d/cachyos-mirrorlist  && \  
pacman -Sy --needed --overwrite "*" --noconfirm cachyos-keyring cachyos-mirrorlist cachyos-v3-mirrorlist cachyos-v4-mirrorlist cachyos-hooks archlinux-keyring pacman-mirrorlist  && \  
pacman -Syy --noconfirm  && \  
\
pacman -Syy --overwrite="*" --noconfirm --ask=4 --root /rootfs/ base dracut linux-firmware ostree systemd btrfs-progs e2fsprogs xfsprogs binutils  && \  
dosfstools skopeo dbus dbus-glib glib2 shadow udev wget crun librsvg libglvnd qt6-multimedia-ffmpeg  && \  
plymouth acpid ddcutil dmidecode mesa-utils ntfs-3g vulkan-tools wayland-utils playerctl curl cosign distrobox  && \  
podman shim networkmanager firewalld flatpak gamescope scx-scheds scx-manager sudo bash bash-completion  && \  
fastfetch unzip linux-cachyos-deckify linux-cachyos-deckify-headers steamos-manager steamos-powerbuttond  && \  
jupiter-fan-control steamdeck-dsp cachyos-handheld amd-ucode intel-ucode efibootmgr shim mesa lib32-mesa  && \  
libva-intel-driver libva-mesa-driver vpl-gpu-rt vulkan-icd-loader vulkan-intel vulkan-radeon apparmor  && \  
xf86-video-amdgpu lib32-vulkan-radeon  && \  
opencl-mesa lib32-opencl-mesa rocm-opencl-runtime  && \  
plasma-desktop konsole plasma-nm plasma-pa sddm  && \  
\
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com  && \  
pacman-key --init && pacman-key --lsign-key 3056513887B78AEB  && \  
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm  && \  
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm  && \  
echo -e '[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf  && \  
pacman -Syy --overwrite="*" --noconfirm --ask=4 --root /rootfs/ chaotic-aur/bootc  && \  
\
rm -rf /*!(rootfs)  && \  
\
FROM scratch AS output  && \  
\
ENV DRACUT_NO_XATTR=1  && \  
\
COPY --from="builder" /rootfs /  && \  
\
# Move everything from `/var` to `/usr/lib/sysimage` so behavior around pacman remains the same on `bootc usroverlay`'d systems  && \  
grep "= */var" /etc/pacman.conf | sed "/= *\/var/s/.*=// ; s/ //" | xargs -n1 sh -c 'mkdir -p "/usr/lib/sysimage/$(dirname $(echo $1 | sed "s@/var/@@"))"  && \  
mv -v "$1" "/usr/lib/sysimage/$(echo "$1" | sed "s@/var/@@")"' ''  && \  
sed -i -e "/= *\/var/ s/^#//" -e "s@= */var@= /usr/lib/sysimage@g" -e "/DownloadUser/d" /etc/pacman.conf  && \  
\
###  && \  
\
# Create pacman hook to make it ephemeral  && \  
mkdir -p /etc/pacman.d/hooks  && \  
echo '[Trigger]' > /etc/pacman.d/hooks/ephemeral-cache.hook  && \  
echo 'Operation = Install' >> /etc/pacman.d/hooks/ephemeral-cache.hook  && \  
echo 'Operation = Upgrade' >> /etc/pacman.d/hooks/ephemeral-cache.hook  && \  
echo 'Operation = Remove' >> /etc/pacman.d/hooks/ephemeral-cache.hook  && \  
echo 'Type = Package' >> /etc/pacman.d/hooks/ephemeral-cache.hook  && \  
echo 'Target = *' >> /etc/pacman.d/hooks/ephemeral-cache.hook  && \  
echo '' >> /etc/pacman.d/hooks/ephemeral-cache.hook  && \  
echo '[Action]' >> /etc/pacman.d/hooks/ephemeral-cache.hook  && \  
echo 'Description = Cleaning ephemeral pacman cache and DB...' >> /etc/pacman.d/hooks/ephemeral-cache.hook  && \  
echo 'When = PostTransaction' >> /etc/pacman.d/hooks/ephemeral-cache.hook  && \  
echo 'Exec = /bin/sh -c "rm -rf /tmp/pman/db /tmp/pman/cache"' >> /etc/pacman.d/hooks/ephemeral-cache.hook  && \  
\
###  && \  
\
# force-refresh and add the chaotic-aur (where we get 'bootc' from)  && \  
curl https://raw.githubusercontent.com/CachyOS/CachyOS-PKGBUILDS/master/cachyos-mirrorlist/cachyos-mirrorlist -o /etc/pacman.d/cachyos-mirrorlist  && \  
pacman -Syy --needed --overwrite "*" --noconfirm cachyos-keyring cachyos-mirrorlist cachyos-v3-mirrorlist cachyos-v4-mirrorlist cachyos-hooks archlinux-keyring pacman-mirrorlist  && \  
pacman -Syy --noconfirm  && \  
\
# install basic stuff  && \  
#pacman -S --noconfirm base dracut linux-firmware ostree systemd btrfs-progs e2fsprogs xfsprogs binutils dosfstools skopeo dbus dbus-glib glib2 shadow udev wget crun  && \  
#pacman -S --noconfirm librsvg libglvnd qt6-multimedia-ffmpeg plymouth acpid ddcutil dmidecode mesa-utils ntfs-3g vulkan-tools wayland-utils playerctl curl cosign  && \  
#pacman -S --noconfirm distrobox podman shim networkmanager firewalld flatpak gamescope scx-scheds scx-manager sudo bash bash-completion fastfetch unzip  && \  
\
#pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com  && \  
#pacman-key --init && pacman-key --lsign-key 3056513887B78AEB  && \  
#pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm  && \  
#pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm  && \  
#echo -e '[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf  && \  
#pacman -Sy --noconfirm chaotic-aur/bootc  && \  
\
# add post-transaction flatpsks  && \  
mkdir -p /usr/share/flatpak/preinstall.d/  && \  
\
# Systemd flatpak preinstall service  && \  
echo -e '[Unit]  && \  
Description=Preinstall Flatpaks  && \  
After=network-online.target  && \  
Wants=network-online.target  && \  
ConditionPathExists=/usr/bin/flatpak  && \  
Documentation=man:flatpak-preinstall(1)  && \  
\
[Service]  && \  
Type=oneshot  && \  
ExecStart=/usr/bin/flatpak preinstall -y  && \  
RemainAfterExit=true  && \  
Restart=on-failure  && \  
RestartSec=30  && \  
\
StartLimitIntervalSec=600  && \  
StartLimitBurst=3  && \  
\
[Install]  && \  
WantedBy=multi-user.target' > /usr/lib/systemd/system/flatpak-preinstall.service  && \  
\
# Set up zram, this will help users not run out of memory.  && \  
echo -e '[zram0]\nzram-size = min(ram, 8192)' >> /usr/lib/systemd/zram-generator.conf  && \  
echo -e 'enable systemd-resolved.service' >> usr/lib/systemd/system-preset/91-resolved-default.preset  && \  
echo -e 'L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf' >> /usr/lib/tmpfiles.d/resolved-default.conf  && \  
systemctl preset systemd-resolved.service  && \  
\
# brew setup   && \  
curl -s https://api.github.com/repos/ublue-os/packages/releases/latest  && \  
| jq -r '.assets[] | select(.name | test("homebrew-x86_64.*\\.tar\\.zst")) | .browser_download_url'  && \  
| xargs -I {} wget -O /usr/share/homebrew.tar.zst {}  && \  
\
echo '[[ -d /home/linuxbrew/.linuxbrew && $- == *i* ]]  && \  
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' > /etc/profile.d/brew.sh  && \  
\
echo -e "[Unit]  && \  
Description=Setup Homebrew from tarball  && \  
After=local-fs.target  && \  
ConditionPathExists=!/var/home/linuxbrew/.linuxbrew  && \  
ConditionPathExists=/usr/share/homebrew.tar.zst  && \  
\
[Service]  && \  
Type=oneshot  && \  
ExecStart=/usr/bin/mkdir -p /tmp/homebrew  && \  
ExecStart=/usr/bin/mkdir -p /var/home/linuxbrew  && \  
ExecStart=/usr/bin/tar --zstd -xf /usr/share/homebrew.tar.zst -C /tmp/homebrew  && \  
ExecStart=/usr/bin/cp -R -n /tmp/homebrew/linuxbrew/.linuxbrew /var/home/linuxbrew  && \  
ExecStart=/usr/bin/chown -R 1000:1000 /var/home/linuxbrew  && \  
ExecStart=/usr/bin/rm -rf /tmp/homebrew  && \  
ExecStart=/usr/bin/touch /etc/.linuxbrew  && \  
\
[Install]  && \  
WantedBy=multi-user.target" > /usr/lib/systemd/system/brew-setup.service  && \  
\
systemctl enable brew-setup.service  && \  
\
# This fixes a user/groups error with rebasing from other problematic images.  && \  
# FIXME Do NOT remove until fixed upstream or fixed universally.  && \  
mkdir -p /usr/lib/systemd/system-preset /usr/lib/systemd/system  && \  
\  
echo -e '#!/bin/sh\ncat /usr/lib/sysusers.d/*.conf | grep -e "^g" | grep -v -e "^#" | awk "NF" | awk '\''{print $2}'\'' | grep -v -e "wheel" -e "root" -e "sudo" | xargs -I{} sed -i "/{}/d" $1' > /usr/libexec/os-group-fix  && \  
chmod +x /usr/libexec/os-group-fix  && \  
echo -e '[Unit]  && \  
Description=Fix groups  && \  
Wants=local-fs.target  && \  
After=local-fs.target  && \  
[Service]  && \  
Type=oneshot  && \  
ExecStart=/usr/libexec/os-group-fix /etc/group  && \  
ExecStart=/usr/libexec/os-group-fix /etc/gshadow  && \  
ExecStart=systemd-sysusers  && \  
[Install]  && \  
WantedBy=default.target multi-user.target' > /usr/lib/systemd/system/os-group-fix.service  && \  
\
echo -e "enable os-group-fix.service" > /usr/lib/systemd/system-preset/01-os-group-fix.preset  && \  
\
# fix sudo  && \  
echo -e '%wheel ALL=(ALL:ALL) ALL'  && \  
\
# System services (Machine Boot level)  && \  
systemctl enable polkit.service  && \  
NetworkManager.service  && \  
firewalld.service  && \  
flatpak-preinstall.service  && \  
os-group-fix.service  && \  
\
# Activate NTSync  && \  
echo -e 'ntsync' > /etc/modules-load.d/ntsync.conf  && \  
\
# CachyOS bbr3 Config Option  && \  
echo -e 'net.core.default_qdisc=fqn\  && \  
net.ipv4.tcp_congestion_control=bbr' > /etc/sysctl.d/99-bbr3.conf  && \  
\
########################################################################################################################################  && \  
# Changes go here:  && \  
# (for stability, it is recommended not to use the AUR - that's what distrobox is for.)  && \  
########################################################################################################################################  && \  
\
# ONLY ADD ONE KERNEL!!!  && \  
#  && \  
#pacman -Sy --noconfirm linux-cachyos-deckify linux-cachyos-deckify-headers  && \  
\
#
#bash -c 'BASE="https://build.cachyos.org/ISO/handheld";  && \  
#DATE=$(date +%y%m%d);  && \  
#while ! curl --head --silent --fail "$BASE/$DATE/" >/dev/null 2>&1; do  && \  
#  DATE=$(date -d "$DATE - 1 day" +%y%m%d);  && \  
#done;  && \  
#pacman -Sy --noconfirm --overwrite "*" --ask=4 $(curl -s "$BASE/$DATE/cachyos-handheld-linux-$DATE.pkgs.txt" | awk "{print$1}" | grep -v firefox | grep -v cachyos-calamares-qt6-next-deckify | grep -v vim | grep -v vim-runtime | grep -v paru )'  && \  
\
#pacman -S --noconfirm --overwrite "*" --ask=4  && \  
#steamos-manager steamos-powerbuttond jupiter-fan-control steamdeck-dsp cachyos-handheld  && \  
#amd-ucode intel-ucode efibootmgr shim mesa lib32-mesa libva-intel-driver libva-mesa-driver  && \  
#vpl-gpu-rt vulkan-icd-loader vulkan-intel vulkan-radeon apparmor xf86-video-amdgpu lib32-vulkan-radeon  && \  
#opencl-mesa lib32-opencl-mesa rocm-opencl-runtime  && \  
#plasma-desktop konsole plasma-nm plasma-pa sddm  && \  
\
#pacman -S --noconfirm chaotic-aur/all-repository-fonts  && \  
\
###########_____________________________________________________________________________________________________________________________  && \  
# bazzite scripts need grub2-editenv  && \  
#  && \  
ln -s /usr/bin/grub-editenv /usr/bin/grub2-editenv  && \  
#_______________________________________________________________________________________________________________________________________  && \  
\
###########_____________________________________________________________________________________________________________________________  && \  
# create a /boot/grub to use bazzite scripts  && \  
#
mkdir -p /usr/lib/systemd/system  && \  
touch /usr/lib/systemd/system/fix-grub-link.service  && \  
echo "[Unit]" > /usr/lib/systemd/system/fix-grub-link.service  && \  
echo "Description=Create /boot/grub symlink if missing" >> /usr/lib/systemd/system/fix-grub-link.service  && \  
echo "ConditionPathExists=!/boot/grub" >> /usr/lib/systemd/system/fix-grub-link.service  && \  
echo "" >> /usr/lib/systemd/system/fix-grub-link.service  && \  
echo "[Service]" >> /usr/lib/systemd/system/fix-grub-link.service  && \  
echo "Type=oneshot" >> /usr/lib/systemd/system/fix-grub-link.service  && \  
echo "ExecStart=/bin/ln -s /boot/grub2 /boot/grub" >> /usr/lib/systemd/system/fix-grub-link.service  && \  
echo "" >> /usr/lib/systemd/system/fix-grub-link.service  && \  
echo "[Install]" >> /usr/lib/systemd/system/fix-grub-link.service  && \  
echo "WantedBy=multi-user.target" >> /usr/lib/systemd/system/fix-grub-link.service  && \  
\
systemctl enable /usr/lib/systemd/system/fix-grub-link.service  && \  
#_______________________________________________________________________________________________________________________________________  && \  
\
\
###########_____________________________________________________________________________________________________________________________  && \  
# services from bazzite  && \  
pacman -S --noconfirm --needed rsync   && \  
WORKDIR /tmp  && \  
git clone --depth 1 https://github.com/ublue-os/bazzite.git  && \  
rsync -a /tmp/bazzite/system_files/deck/kinoite/ /  && \  
rsync -a /tmp/bazzite/system_files/deck/shared/ /  && \  
WORKDIR /  && \  
rm -rf /tmp/bazzite  && \  
#_______________________________________________________________________________________________________________________________________  && \  
\
## enable your services  && \  
#
systemctl enable sddm  && \  
systemctl enable jupiter-fan-control  && \  
systemctl enable podman  && \  
systemctl enable bazzite-grub-boot-success.timer  && \  
systemctl enable bazzite-grub-boot-success.service  && \  
systemctl enable bazzite-autologin.service  && \  
\
# add flatpaks  && \  
echo -e "[Flatpak Preinstall io.github.kolunmi.Bazaar]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Bazaar.preinstall  && \  
\
# Place logo at plymouth folder location to appear on boot and shutdown.  && \  
#
mkdir -p /etc/plymouth  && \  
  echo -e '[Daemon]\nTheme=spinner' | tee /etc/plymouth/plymouthd.conf  && \  
  wget --tries=5 -O /usr/share/plymouth/themes/spinner/watermark.png  && \  
https://raw.githubusercontent.com/ChuckTripwell/cachyos-bootc-template/refs/heads/main/Text_Logo.png # this URL above leads to the logo shown on boot. you can use ours, or upload yours.  && \  
  && \  
  && \  
########################################################################################################################################  && \  
# end of changes  && \  
########################################################################################################################################  && \  
\
# finalize  && \  
printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf  && \  
  printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf  && \  
  sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")"  && \  
  dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'  && \  
\
yes | pacman -Scc  && \  
yes | pacman -Scc  && \  
yes | paccache -ruk0  && \  
\
rm -rf /home/build/.cache/*  && \  
rm -rf  && \  
/tmp/*  && \  
/var/cache/pacman/pkg/*  && \  
/var/lib/pacman/sync/*  && \  
/var/log/*  && \  
/var/cache/*  && \  
/var/log/*  && \  
/var/db/*  && \  
/var/lib/*  && \  
\
# Necessary for general behavior expected by image-based systems  && \  
sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd"  && \  
rm -rf /boot /home /root /usr/local /srv /var /usr/lib/sysimage/log /usr/lib/sysimage/cache/pacman/pkg  && \  
mkdir -p /sysroot /boot /usr/lib/ostree /var  && \  
ln -s sysroot/ostree /ostree && ln -s var/roothome /root && ln -s var/srv /srv && ln -s var/opt /opt && ln -s var/mnt /mnt && ln -s var/home /home  && \  
echo "$(for dir in opt home srv mnt usrlocal ; do echo "d /var/$dir 0755 root root -" ; done)" | tee -a "/usr/lib/tmpfiles.d/bootc-base-dirs.conf"  && \  
printf "d /var/roothome 0700 root root -\nd /run/media 0755 root root -" | tee -a "/usr/lib/tmpfiles.d/bootc-base-dirs.conf"  && \  
printf '[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n' | tee "/usr/lib/ostree/prepare-root.conf"  && \  
\
bootc container lint
