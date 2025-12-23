FROM docker.io/cachyos/cachyos-v3:latest AS final

ENV DRACUT_NO_XATTR=1


########################################################################################################################################
# Section 1 - Package Installs | We grab every package we can from official arch repo/set up all non-flatpak apps for user ^^ ##########
########################################################################################################################################

# Move everything from `/var` to `/usr/lib/sysimage` so behavior around pacman remains the same on `bootc usroverlay`'d systems
RUN grep "= */var" /etc/pacman.conf | sed "/= *\/var/s/.*=// ; s/ //" | xargs -n1 sh -c 'mkdir -p "/usr/lib/sysimage/$(dirname $(echo $1 | sed "s@/var/@@"))" && \
mv -v "$1" "/usr/lib/sysimage/$(echo "$1" | sed "s@/var/@@")"' '' && \
    sed -i -e "/= *\/var/ s/^#//" -e "s@= */var@= /usr/lib/sysimage@g" -e "/DownloadUser/d" /etc/pacman.conf

# Set it up such that pacman is always cleaned after installs
RUN echo -e "[Trigger]\n\
Operation = Install\n\
Operation = Upgrade\n\
Type = Package\n\
Target = *\n\
\n\
[Action]\n\
Description = Cleaning up package cache...\n\
Depends = coreutils\n\
When = PostTransaction\n\
Exec = /usr/bin/rm -rf /var/cache/pacman/pkg" > /usr/share/libalpm/hooks/package-cleanup.hook

# FIXME | Fix an issue with Cachy's docker, pacman -syu fails otherwise https://discuss.cachyos.org/t/cant-update-because-of-linux-firmware-notice/19835
RUN mkdir /usr/lib/sysimage/lib/pacmanlocal -p

# Initialize the database
RUN pacman -Syu --noconfirm

# Use the Arch mirrorlist that will be best at the moment for both the containerfile and user too! Fox will help!
RUN pacman -S --noconfirm reflector

# Base packages \ Linux Foundation \ Foss is love, foss is life! We split up packages by category for readability, debug ease, and less dependency trouble
RUN pacman -S --noconfirm base linux-firmware dracut ostree systemd btrfs-progs e2fsprogs xfsprogs binutils dosfstools skopeo dbus dbus-glib glib2 shadow

# Fonts
#RUN pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji unicode-emoji noto-fonts-extra \
#    ttf-ibm-plex otf-font-awesome ttf-jetbrains-mono wqy-microhei ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-common \
#    ttf-nerd-fonts-symbols-mono ttf-croscore ttf-dejavu ttf-droid gsfonts ttf-arphic-uming ttf-baekmuk gnu-free-fonts otf-monaspace

# CLI Utilities
#RUN pacman -S --noconfirm sudo bash bash-completion fastfetch btop jq less lsof nano openssh powertop man-db wget yt-dlp \
#      tree usbutils vim wl-clip-persist cliphist unzip ptyxis glibc-locales tar udev starship tuned-ppd tuned hyfetch curl patchelf 

# Virtualization \ Containerization
RUN pacman -S --noconfirm distrobox docker podman

# Network / VPN / SMB / storage
#RUN pacman -S --noconfirm libmtp nss-mdns samba smbclient networkmanager firewalld udiskie udisks2

# User frontend programs/apps
RUN pacman -S --noconfirm scx-scheds scx-manager gnome-disk-utility

##############################################################################################################################################
# Section 3 - Chaotic AUR / AUR # We grab some precompiled packages from the Chaotic AUR for things not on Arch repos/better updated~ ovo ####
##############################################################################################################################################

# Chaotic AUR repo
RUN pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
RUN pacman-key --init && pacman-key --lsign-key 3056513887B78AEB
RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
RUN echo -e '[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
# Heck's Bootc repo
RUN pacman-key --recv-key 5DE6BF3EBC86402E7A5C5D241FA48C960F9604CB --keyserver keyserver.ubuntu.com
RUN pacman-key --lsign-key 5DE6BF3EBC86402E7A5C5D241FA48C960F9604CB
RUN echo -e '[bootc]\nSigLevel = Required\nServer=https://github.com/hecknt/arch-bootc-pkgs/releases/download/$repo' >> /etc/pacman.conf

RUN pacman -Sy --noconfirm

RUN pacman -S --noconfirm \
    chaotic-aur/flatpak-git \
    chaotic-aur/opentabletdriver \
    chaotic-aur/bootc 

RUN pacman -S --noconfirm \
  bootc/uupd && \
  systemctl enable uupd.timer


#RUN pacman -S --noconfirm --overwrite="*" --ask=4 \
a52dec \
aalib \
abseil-cpp \
accounts-qml-module \
accountsservice \
acl \
adobe-source-han-sans-cn-fonts \
adobe-source-han-sans-jp-fonts \
adobe-source-han-sans-kr-fonts \
adwaita-cursors \
adwaita-fonts \
adwaita-icon-theme \
adwaita-icon-theme-legacy \
aha \
alacritty \
alsa-card-profiles \
alsa-firmware \
alsa-lib \
alsa-plugins \
alsa-topology-conf \
alsa-ucm-conf \
alsa-utils \
amd-ucode \
ananicy-cpp \
aom \
appstream \
appstream-qt \
archlinux-keyring \
aribb24 \
aribb25 \
ark \
at-spi2-core \
atkmm \
attica \
attr \
audit \
aurorae \
autoconf \
automake \
avahi \
awesome-terminal-fonts \
baloo \
baloo-widgets \
base \
base-devel \
bash \
bash-completion \
bat \
bind \
binutils \
bison \
blas \
bluedevil \
bluez \
bluez-hid2hci \
bluez-libs \
bluez-qt \
bluez-utils \
bolt \
bpf \
breeze \
breeze-gtk \
breeze-icons \
brotli \
btop \
btrfs-progs \
bubblewrap \
bzip2 \
ca-certificates \
ca-certificates-mozilla \
ca-certificates-utils \
cachyos-alacritty-config \
cachyos-ananicy-rules \
cachyos-emerald-kde-theme-git \
cachyos-fish-config \
cachyos-grub-theme \
cachyos-hello \
cachyos-hooks \
cachyos-iridescent-kde \
cachyos-kde-settings \
cachyos-kernel-manager \
cachyos-keyring \
cachyos-micro-settings \
cachyos-mirrorlist \
cachyos-nord-kde-theme-git \
cachyos-packageinstaller \
cachyos-plymouth-bootanimation \
cachyos-rate-mirrors \
cachyos-settings \
cachyos-themes-sddm \
cachyos-v3-mirrorlist \
cachyos-v4-mirrorlist \
cachyos-wallpapers \
cachyos-zsh-config \
cairo \
cairomm \
cairomm-1.16 \
cantarell-fonts \
capitaine-cursors \
cblas \
cdparanoia \
cfitsio \
char-white \
chromaprint \
chwd \
cifs-utils \
clang \
clinfo \
compiler-rt \
confuse \
convertlit \
coreutils \
cpupower \
cryptsetup \
curl \
dav1d \
db5.3 \
dbus \
dbus-broker \
dbus-broker-units \
dbus-units \
dconf \
ddcutil \
debugedit \
default-cursors \
desktop-file-utils \
device-mapper \
dhclient \
diffutils \
ding-libs \
dmidecode \
dmraid \
dnsmasq \
dnssec-anchors \
dolphin \
dosfstools \
double-conversion \
duf \
duktape \
e2fsprogs \
ebook-tools \
editorconfig-core-c \
efibootmgr \
efitools \
efivar \
egl-wayland \
eglexternalplatform \
ell \
ethtool \
exfatprogs \
exiv2 \
expac \
expat \
eza \
f2fs-tools \
faac \
faad2 \
fakeroot \
fastfetch \
fd \
ffmpeg \
ffmpeg4.4 \
ffmpegthumbnailer \
ffmpegthumbs \
fftw \
file \
filelight \
filesystem \
findutils \
firefox \
fish \
fish-autopair \
fish-pure-prompt \
fisher \
flac \
flashrom \
flex \
fluidsynth \
fmt \
fontconfig \
frameworkintegration \
freeglut \
freetype2 \
fribidi \
fsarchiver \
ftgl \
fuse-common \
fuse3 \
fwupd \
fwupd-efi \
fzf \
gawk \
gc \
gcc \
gcc-libs \
gcr-4 \
gdbm \
gdk-pixbuf2 \
gettext \
ghostscript \
giflib \
git \
glances \
glew \
glib-networking \
glib2 \
glibc \
glibmm \
glibmm-2.68 \
glm \
glslang \
glu \
glycin \
gmp \
gnulib-l10n \
gnupg \
gnutls \
gobject-introspection-runtime \
gperftools \
gpgme \
gpgmepp \
gpm \
graphene \
graphite \
grep \
groff \
grub \
grub-hook \
gsettings-desktop-schemas \
gsettings-system-schemas \
gsm \
gssdp \
gssproxy \
gst-libav \
gst-plugin-pipewire \
gst-plugins-bad \
gst-plugins-bad-libs \
gst-plugins-base \
gst-plugins-base-libs \
gst-plugins-ugly \
gstreamer \
gtest \
gtk-update-icon-cache \
gtk3 \
gtk4 \
gtkmm-4.0 \
gtkmm3 \
gtksourceview4 \
guile \
gupnp \
gupnp-igd \
gwenview \
gzip \
harfbuzz \
haruna \
haveged \
hdparm \
hicolor-icon-theme \
hidapi \
highway \
hunspell \
hwdata \
hwdetect \
hwinfo \
hwloc \
i2c-tools \
iana-etc \
icu \
ijs \
imagemagick \
imath \
imlib2 \
inetutils \
inxi \
iproute2 \
iptables-nft \
iputils \
iso-codes \
iw \
iwd \
jack2 \
jansson \
jasper \
jbig2dec \
jbigkit \
jemalloc \
jfsutils \
jq \
json-c \
json-glib \
jsoncpp \
kaccounts-integration \
kactivitymanagerd \
karchive \
kate \
kauth \
kbd \
kbookmarks \
kcalc \
kcmutils \
kcodecs \
kcolorpicker \
kcolorscheme \
kcompletion \
kconfig \
kconfigwidgets \
kcontacts \
kcoreaddons \
kcrash \
kdbusaddons \
kde-cli-tools \
kde-gtk-config \
kdeclarative \
kdeconnect \
kdecoration \
kded \
kdegraphics-mobipocket \
kdegraphics-thumbnailers \
kdeplasma-addons \
kdesu \
kdialog \
kdnssd \
kdsingleapplication \
kdsoap-qt6 \
kdsoap-ws-discovery-client \
keyutils \
kfilemetadata \
kglobalaccel \
kglobalacceld \
kguiaddons \
kholidays \
ki18n \
kiconthemes \
kidletime \
kimageannotator \
kinfocenter \
kio \
kio-admin \
kio-extras \
kio-fuse \
kirigami \
kirigami-addons \
kitemmodels \
kitemviews \
kjobwidgets \
kmenuedit \
kmod \
knewstuff \
knotifications \
knotifyconfig \
konsole \
kpackage \
kparts \
kpeople \
kpipewire \
kpty \
kquickcharts \
krb5 \
krunner \
kscreen \
kscreenlocker \
kservice \
kstatusnotifieritem \
ksvg \
ksystemstats \
ktexteditor \
ktextwidgets \
kunitconversion \
kuserfeedback \
kwallet \
kwallet-pam \
kwalletmanager \
kwayland \
kwidgetsaddons \
kwin \
kwindowsystem \
kxmlgui \
l-smash \
lame \
lapack \
layer-shell-qt \
layer-shell-qt5 \
lcms2 \
ldb \
leancrypto \
less \
libaccounts-glib \
libaccounts-qt \
libaio \
libarchive \
libass \
libassuan \
libasyncns \
libatasmart \
libavc1394 \
libavtp \
libb2 \
libblockdev \
libblockdev-crypto \
libblockdev-fs \
libblockdev-loop \
libblockdev-mdraid \
libblockdev-nvme \
libblockdev-part \
libblockdev-swap \
libbluray \
libbpf \
libbs2b \
libbsd \
libbytesize \
libcaca \
libcanberra \
libcap \
libcap-ng \
libcbor \
libcddb \
libcdio \
libcdio-paranoia \
libcloudproviders \
libcolord \
libcups \
libdaemon \
libdatrie \
libdc1394 \
libdca \
libde265 \
libdecor \
libdeflate \
libdisplay-info \
libdmtx \
libdnet \
libdovi \
libdrm \
libdv \
libdvbpsi \
libdvdcss \
libdvdnav \
libdvdread \
libebml \
libebur128 \
libedit \
libei \
libelf \
libepoxy \
libevdev \
libevent \
libfakekey \
libfdk-aac \
libffi \
libfontenc \
libfreeaptx \
libftdi \
libfyaml \
libgcrypt \
libgirepository \
libgit2 \
libglvnd \
libgme \
libgoom2 \
libgpg-error \
libgsf \
libgudev \
libice \
libidn \
libidn2 \
libiec61883 \
libimobiledevice \
libimobiledevice-glue \
libinih \
libinput \
libisl \
libjcat \
libjpeg-turbo \
libjxl \
libkate \
libkdcraw \
libkexiv2 \
libksba \
libkscreen \
liblc3 \
libldac \
liblqr \
liblrdf \
libltc \
libmad \
libmatroska \
libmaxminddb \
libmbim \
libmd \
libmfx \
libmicrodns \
libmm-glib \
libmng \
libmnl \
libmodplug \
libmpc \
libmpcdec \
libmpeg2 \
libmspack \
libmtp \
libmysofa \
libndp \
libnetfilter_conntrack \
libnewt \
libnfnetlink \
libnfs \
libnftnl \
libnghttp2 \
libnghttp3 \
libnice \
libnl \
libnm \
libnma-common \
libnma-gtk4 \
libnotify \
libnsl \
libnvme \
libogg \
liboggz \
libopenmpt \
libopenraw \
libp11-kit \
libpaper \
libpcap \
libpciaccess \
libpgm \
libpipeline \
libpipewire \
libplacebo \
libplasma \
libplist \
libpng \
libproxy \
libpsl \
libpulse \
libqaccessibilityclient-qt6 \
libqalculate \
libqmi \
libqrtr-glib \
libraqm \
libraw \
libraw1394 \
librsvg \
libsamplerate \
libsasl \
libseccomp \
libsecret \
libshout \
libsigc++ \
libsigc++-3.0 \
libsixel \
libsm \
libsndfile \
libsodium \
libsoup3 \
libsoxr \
libsrtp \
libssh \
libssh2 \
libstemmer \
libsysprof-capture \
libtasn1 \
libtatsu \
libteam \
libthai \
libtheora \
libtiff \
libtiger \
libtirpc \
libtommath \
libtool \
libunibreak \
libunistring \
libunwind \
libupnp \
liburcu \
liburing \
libusb \
libusb-compat \
libusbmuxd \
libutempter \
libuv \
libva \
libvdpau \
libverto \
libvlc \
libvorbis \
libvpl \
libvpx \
libwacom \
libwbclient \
libwebp \
libwireplumber \
libwnck3 \
libx11 \
libx86emu \
libxau \
libxaw \
libxcb \
libxcomposite \
libxcrypt \
libxcursor \
libxcvt \
libxdamage \
libxdmcp \
libxext \
libxfixes \
libxfont2 \
libxft \
libxi \
libxinerama \
libxkbcommon \
libxkbcommon-x11 \
libxkbfile \
libxml2 \
libxmlb \
libxmu \
libxpm \
libxpresent \
libxrandr \
libxrender \
libxres \
libxshmfence \
libxslt \
libxss \
libxt \
libxtst \
libxv \
libxxf86vm \
libzip \
licenses \
lilv \
linux-api-headers \
linux-cachyos-deckify \
linux-cachyos-deckify-headers \
linux-firmware \
linux-firmware-amdgpu \
linux-firmware-atheros \
linux-firmware-broadcom \
linux-firmware-cirrus \
linux-firmware-intel \
linux-firmware-mediatek \
linux-firmware-nvidia \
linux-firmware-other \
linux-firmware-radeon \
linux-firmware-realtek \
linux-firmware-whence \
lirc \
live-media \
lld \
llhttp \
llvm \
llvm-libs \
lm_sensors \
lmdb \
logrotate \
lsb-release \
lsscsi \
lua \
luajit \
lv2 \
lvm2 \
lz4 \
lzo \
m4 \
mailcap \
make \
man-db \
man-pages \
md4c \
mdadm \
media-player-info \
meld \
mesa \
mesa-utils \
micro \
milou \
minizip \
mjpegtools \
mkinitcpio \
mkinitcpio-busybox \
mobile-broadband-provider-info \
modemmanager \
modemmanager-qt \
mpdecimal \
mpfr \
mpg123 \
mpv \
mpvqt \
mtdev \
mtools \
mujs \
nano \
nano-syntax-highlighting \
ncurses \
neon \
netctl \
nettle \
networkmanager \
networkmanager-openvpn \
networkmanager-qt \
networkmanager-vpn-plugin-openvpn \
nfs-utils \
nfsidmap \
nftables \
nilfs-utils \
noto-color-emoji-fontconfig \
noto-fonts \
noto-fonts-cjk \
noto-fonts-emoji \
npth \
nspr \
nss \
nss-mdns \
ntp \
numactl \
ocean-sound-theme \
ocl-icd \
octopi \
oh-my-zsh-git \
onetbb \
oniguruma \
open-vm-tools \
openal \
opencore-amr \
opencv \
opendesktop-fonts \
openexr \
openh264 \
openjpeg2 \
openssh \
openssl \
openvpn \
openxr \
opus \
orc \
os-prober \
p11-kit \
pacman \
pacman-contrib \
pacman-mirrorlist \
pacutils \
pahole \
pam \
pambase \
pango \
pangomm \
pangomm-2.48 \
parallel \
parted \
paru \
passim \
patch \
pavucontrol \
pciutils \
pcre \
pcre2 \
pcsclite \
perl \
perl-clone \
perl-encode-locale \
perl-error \
perl-file-listing \
perl-html-parser \
perl-html-tagset \
perl-http-cookiejar \
perl-http-cookies \
perl-http-daemon \
perl-http-date \
perl-http-message \
perl-http-negotiate \
perl-io-html \
perl-libwww \
perl-lwp-mediatypes \
perl-mailtools \
perl-net-http \
perl-timedate \
perl-try-tiny \
perl-uri \
perl-www-robotrules \
perl-xml-parser \
perl-xml-writer \
phonon-qt6 \
phonon-qt6-vlc \
pinentry \
pipewire \
pipewire-alsa \
pipewire-audio \
pipewire-pulse \
pixman \
pkcs11-helper \
pkgconf \
pkgfile \
plasma-activities \
plasma-activities-stats \
plasma-browser-integration \
plasma-desktop \
plasma-firewall \
plasma-integration \
plasma-nm \
plasma-pa \
plasma-systemmonitor \
plasma-thunderbolt \
plasma-workspace \
plasma5support \
plocate \
plymouth \
plymouth-kcm \
polkit \
polkit-kde-agent \
polkit-qt6 \
poppler \
poppler-data \
poppler-glib \
poppler-qt6 \
popt \
portaudio \
power-profiles-daemon \
powerdevil \
powerline-fonts \
ppp \
prison \
procps-ng \
projectm \
protobuf \
protobuf-c \
psmisc \
pulseaudio-qt \
purpose \
pv \
python \
python-annotated-types \
python-cairo \
python-defusedxml \
python-gobject \
python-orjson \
python-packaging \
python-psutil \
python-pydantic \
python-pydantic-core \
python-typing-inspection \
python-typing_extensions \
python-wxpython \
qca-qt6 \
qcoro \
qemu-guest-agent \
qqc2-breeze-style \
qqc2-desktop-style \
qrencode \
qt-sudo \
qt5-base \
qt5-declarative \
qt5-translations \
qt5-wayland \
qt6-5compat \
qt6-base \
qt6-connectivity \
qt6-declarative \
qt6-imageformats \
qt6-location \
qt6-multimedia \
qt6-multimedia-ffmpeg \
qt6-positioning \
qt6-quick3d \
qt6-quicktimeline \
qt6-sensors \
qt6-shadertools \
qt6-speech \
qt6-svg \
qt6-tools \
qt6-translations \
qt6-virtualkeyboard \
qt6-wayland \
qt6-webchannel \
qt6-webengine \
qt6-websockets \
qtermwidget \
raptor \
rate-mirrors \
rav1e \
re2 \
readline \
rebuild-detector \
reflector \
ripgrep \
ripgrep-all \
rpcbind \
rsync \
rtkit \
rtmpdump \
rubberband \
run-parts \
s-nail \
sbc \
scx-manager \
scx-scheds \
sd \
sddm \
sddm-kcm \
sdl12-compat \
sdl2-compat \
sdl3 \
sdl_image \
sed \
serd \
sg3_utils \
shaderc \
shadow \
shared-mime-info \
signon-kwallet-extension \
signon-plugin-oauth2 \
signon-ui \
signond \
slang \
smartmontools \
smbclient \
snappy \
socat \
sof-firmware \
solid \
sonnet \
sord \
sound-theme-freedesktop \
soundtouch \
spandsp \
spdlog \
spectacle \
speex \
speexdsp \
spice-vdagent \
spirv-tools \
sqlite \
sratom \
srt \
startup-notification \
sudo \
svt-av1 \
svt-hevc \
syndication \
syntax-highlighting \
sysfsutils \
systemd \
systemd-libs \
systemd-resolvconf \
systemd-sysvcompat \
systemsettings \
taglib \
talloc \
tar \
tcl \
tdb \
tealdeer \
tevent \
texinfo \
thin-provisioning-tools \
tinysparql \
tpm2-tss \
tslib \
ttf-bitstream-vera \
ttf-dejavu \
ttf-fantasque-nerd \
ttf-fira-sans \
ttf-hack \
ttf-liberation \
ttf-meslo-nerd \
ttf-opensans \
twolame \
tzdata \
uchardet \
udisks2 \
ufw \
unrar \
unzip \
upower \
uriparser \
usb_modeswitch \
usbutils \
util-linux \
util-linux-libs \
v4l-utils \
vapoursynth \
verdict \
vi \
vid.stab \
vim \
vim-runtime \
virtualbox-guest-utils \
vlc-plugin-a52dec \
vlc-plugin-aalib \
vlc-plugin-alsa \
vlc-plugin-aom \
vlc-plugin-archive \
vlc-plugin-aribb24 \
vlc-plugin-aribb25 \
vlc-plugin-ass \
vlc-plugin-avahi \
vlc-plugin-bluray \
vlc-plugin-caca \
vlc-plugin-cddb \
vlc-plugin-chromecast \
vlc-plugin-dav1d \
vlc-plugin-dbus \
vlc-plugin-dbus-screensaver \
vlc-plugin-dca \
vlc-plugin-dvb \
vlc-plugin-dvd \
vlc-plugin-faad2 \
vlc-plugin-ffmpeg \
vlc-plugin-firewire \
vlc-plugin-flac \
vlc-plugin-fluidsynth \
vlc-plugin-freetype \
vlc-plugin-gme \
vlc-plugin-gnutls \
vlc-plugin-gstreamer \
vlc-plugin-inflate \
vlc-plugin-jack \
vlc-plugin-journal \
vlc-plugin-jpeg \
vlc-plugin-kate \
vlc-plugin-kwallet \
vlc-plugin-libsecret \
vlc-plugin-lirc \
vlc-plugin-live555 \
vlc-plugin-lua \
vlc-plugin-mad \
vlc-plugin-matroska \
vlc-plugin-mdns \
vlc-plugin-modplug \
vlc-plugin-mpeg2 \
vlc-plugin-mpg123 \
vlc-plugin-mtp \
vlc-plugin-musepack \
vlc-plugin-nfs \
vlc-plugin-notify \
vlc-plugin-ogg \
vlc-plugin-opus \
vlc-plugin-png \
vlc-plugin-pulse \
vlc-plugin-quicksync \
vlc-plugin-samplerate \
vlc-plugin-sdl \
vlc-plugin-sftp \
vlc-plugin-shout \
vlc-plugin-smb \
vlc-plugin-soxr \
vlc-plugin-speex \
vlc-plugin-srt \
vlc-plugin-svg \
vlc-plugin-tag \
vlc-plugin-theora \
vlc-plugin-twolame \
vlc-plugin-udev \
vlc-plugin-upnp \
vlc-plugin-vorbis \
vlc-plugin-vpx \
vlc-plugin-x264 \
vlc-plugin-x265 \
vlc-plugin-xml \
vlc-plugin-zvbi \
vlc-plugins-all \
vlc-plugins-base \
vlc-plugins-extra \
vlc-plugins-video-output \
vlc-plugins-visualization \
vmaf \
volume_key \
vulkan-icd-loader \
vulkan-mesa-device-select \
vulkan-tools \
vulkan-virtio \
wayland \
wayland-utils \
webrtc-audio-processing-1 \
wget \
which \
wildmidi \
wireless-regdb \
wireplumber \
wpa_supplicant \
wxwidgets-common \
wxwidgets-gtk3 \
x264 \
x265 \
xcb-proto \
xcb-util \
xcb-util-cursor \
xcb-util-image \
xcb-util-keysyms \
xcb-util-renderutil \
xcb-util-wm \
xdg-desktop-portal \
xdg-desktop-portal-gtk \
xdg-desktop-portal-kde \
xdg-user-dirs \
xdg-utils \
xf86-input-libinput \
xf86-input-vmmouse \
xfsprogs \
xkeyboard-config \
xl2tpd \
xmlsec \
xorg-fonts-encodings \
xorg-server \
xorg-server-common \
xorg-setxkbmap \
xorg-xauth \
xorg-xdpyinfo \
xorg-xinit \
xorg-xinput \
xorg-xkbcomp \
xorg-xkill \
xorg-xmessage \
xorg-xmodmap \
xorg-xprop \
xorg-xrandr \
xorg-xrdb \
xorg-xset \
xorg-xwayland \
xorgproto \
xsettingsd \
xvidcore \
xxhash \
xz \
yyjson \
zbar \
zeromq \
zimg \
zix \
zlib-ng \
zlib-ng-compat \
zram-generator \
zsh \
zsh-autosuggestions \
zsh-completions \
zsh-history-substring-search \
zsh-syntax-highlighting \
zsh-theme-powerlevel10k \
zstd \
zvbi \
zxing-cpp


RUN pacman -S --noconfirm --overwrite="*" --ask=4 linux-cachyos-deckify
#RUN pacman -S --noconfirm --overwrite="*" --ask=4 plasma-meta sddm
RUN pacman -S --noconfirm --overwrite="*" --ask=4 cachyos-handheld
RUN pacman -S --noconfirm --overwrite="*" --ask=4 sudo
RUN pacman -S --noconfirm --overwrite="*" --ask=4 fastfetch
#RUN pacman -S --noconfirm --overwrite="*" --ask=4 podman-compose
RUN pacman -S --noconfirm --overwrite="*" --ask=4 tuned tuned-ppd



#######################################################################################################################################################
# Section 4 - Flatpaks preinstalls | Don't forget. Always, somewhere, someone is fighting for you. You are not alone. -Madoka Magica ##################
#######################################################################################################################################################

RUN mkdir -p /usr/share/flatpak/preinstall.d/

# Bazaar | Get most of your software here, flatpaks that are easy to install and use~
RUN echo -e "[Flatpak Preinstall io.github.kolunmi.Bazaar]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Bazaar.preinstall

########################################################################################################################################
# Section 5 - Linux OS stuffs | "I'd decide for myself whether his teachings are right or wrong." Near, Death Note #####################
########################################################################################################################################

# Place XeniaOS logo at plymouth folder location to appear on boot and shutdown.
#RUN mkdir -p /etc/plymouth && \
#      echo -e '[Daemon]\nTheme=spinner' | tee /etc/plymouth/plymouthd.conf && \
#      wget --tries=5 -O /usr/share/plymouth/themes/spinner/watermark.png \
#      https://raw.githubusercontent.com/XeniaMeraki/XeniaOS-G-Euphoria/refs/heads/main/xeniaos_textlogo_plymouth_delphic_melody.png

# All kindsa Sudo changes for ease and flavor
RUN echo -e '%wheel ALL=(ALL:ALL) ALL\n\
\n\
Defaults insults\n\
Defaults pwfeedback\n\
Defaults secure_path="/usr/local/bin:/usr/bin:/bin:/home/linuxbrew/.linuxbrew/bin"\n\
Defaults env_keep += "EDITOR VISUAL PATH"\n\
Defaults timestamp_timeout=0' > /etc/sudoers.d/xenias-sudo-quiver && \
    chmod 440 /etc/sudoers.d/xenias-sudo-quiver

RUN git clone --depth=1 https://github.com/vinceliuice/Colloid-icon-theme /tmp/colloid-icons && \
    cd /tmp/colloid-icons && \
    ./install.sh \
      -s catppuccin \
      -t orange \
      -d /usr/share/icons && \
    rm -rf /tmp/colloid-icons

# Set up zram, this will help users not run out of memory. Fox will fix!
RUN echo -e '[zram0]\nzram-size = min(ram, 8192)' > /usr/lib/systemd/zram-generator.conf
RUN echo -e 'enable systemd-resolved.service' > /usr/lib/systemd/system-preset/91-resolved-default.preset
RUN echo -e 'L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf' > /usr/lib/tmpfiles.d/resolved-default.conf
RUN systemctl preset systemd-resolved.service

# Symlink Vi to Vim / Make it to where a user can use vi in terminal command to use vim automatically | Thanks Tulip
#RUN ln -s ./vim /usr/bin/vi

# System-wide default application associations for filetype calls
RUN mkdir -p /etc/xdg/

RUN echo -e '[Default Applications]\n\
text/plain=org.kde.kate.desktop\n\
application/json=org.kde.kate.desktop\n\
\n\
text/html=floorp.desktop\n\
\n\
video/mp4=haruna.desktop\n\
video/x-matroska=haruna.desktop\n\
video/webm=haruna.desktop\n\
video/quicktime=haruna.desktop\n\
\n\
audio/mpeg=org.kde.elisa.desktop\n\
audio/flac=org.kde.elisa.desktop\n\
audio/ogg=org.kde.elisa.desktop\n\
audio/wav=org.kde.elisa.desktop\n\
\n\
image/png=pinta.desktop\n\
image/jpeg=pinta.desktop\n\
image/gif=org.kde.gwenview.desktop\n\
\n\
application/zip=org.kde.ark.desktop\n\
application/x-rar=org.kde.ark.desktop\n\
application/x-tar=org.kde.ark.desktop\n\
\n\
[Added Associations]' > /etc/xdg/mimeapps.list

# ENV default exports, QT theming 
# Load shared objects immediately for better first time latency
# Apply OBS_VK to all vulkan instances for better OBS game capture, some other windows may come along for the ride
# Auto dark mode everywhere
RUN echo -e 'QT_QPA_PLATFORMTHEME=qt6ct\n\
LD_BIND_NOW=1\n\
OBS_VKCAPTURE=1\n\
#GTK_THEME=Colloid-Orange-Dark-Catppuccin\n\
#QT_STYLE_OVERRIDE=Colloid-Orange-Dark-Catppuccin\n\
XDG_MENU_PREFIX=arch-\n\
XDG_MENU_PREFIX=plasma-' > /etc/environment

RUN kbuildsycoca6

# Set vm.max_map_count for stability/improved gaming performance
# https://wiki.archlinux.org/title/Gaming#Increase_vm.max_map_count
RUN echo -e "vm.max_map_count = 2147483642" > /etc/sysctl.d/80-gamecompatibility.conf

# Automount ext4/btrfs drives, feel free to mount your own in fstab if you understand how to do so
# To turn off, run sudo ln -s /dev/null /etc/media-automount.d/_all.conf
RUN git clone --depth=1 https://github.com/Zeglius/media-automount-generator /tmp/media-automount-generator && \
    cd /tmp/media-automount-generator && \
    ./install.sh && \
    rm -rf /tmp/media-automount-generator

########################################################################################################################################
# Section 6 - Set up brew | terminal packages manager utility | https://brew.sh/ | Foxy witch will mix up a brew for you! ##############
########################################################################################################################################

RUN curl -s --variable '%AUTH_HEADER' --expand-header '{{AUTH_HEADER}}' https://api.github.com/repos/ublue-os/packages/releases/latest \
    | jq -r '.assets[] | select(.name | test("homebrew-x86_64.*\\.tar\\.zst")) | .browser_download_url' \
    | xargs -I {} wget -O /usr/share/homebrew.tar.zst {}

RUN echo '[[ -d /home/linuxbrew/.linuxbrew && $- == *i* ]] && \
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' > /etc/profile.d/brew.sh

RUN echo -e "[Unit]\n\
Description=Setup Homebrew from tarball\n\
After=local-fs.target\n\
ConditionPathExists=!/var/home/linuxbrew/.linuxbrew\n\
ConditionPathExists=/usr/share/homebrew.tar.zst\n\
\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/bin/mkdir -p /tmp/homebrew\n\
ExecStart=/usr/bin/mkdir -p /var/home/linuxbrew\n\
ExecStart=/usr/bin/tar --zstd -xf /usr/share/homebrew.tar.zst -C /tmp/homebrew\n\
ExecStart=/usr/bin/cp -R -n /tmp/homebrew/linuxbrew/.linuxbrew /var/home/linuxbrew\n\
ExecStart=/usr/bin/chown -R 1000:1000 /var/home/linuxbrew\n\
ExecStart=/usr/bin/rm -rf /tmp/homebrew\n\
ExecStart=/usr/bin/touch /etc/.linuxbrew\n\
\n\
[Install]\n\
WantedBy=multi-user.target" > /usr/lib/systemd/system/brew-setup.service

RUN systemctl enable brew-setup.service

##############################################################################################################################################################################
# Section 7 - Systemd n Services | Hope is just like every other kind of work you do on your body, it's cyclical, and needs to be refreshed every day -Harpy #################
##############################################################################################################################################################################

# Systemd flatpak preinstall service, thanks Aurora
RUN echo -e '[Unit]\n\
Description=Preinstall Flatpaks\n\
After=network-online.target\n\
Wants=network-online.target\n\
ConditionPathExists=/usr/bin/flatpak\n\
Documentation=man:flatpak-preinstall(1)\n\
\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/bin/flatpak preinstall -y\n\
RemainAfterExit=true\n\
Restart=on-failure\n\
RestartSec=30\n\
\n\
StartLimitIntervalSec=600\n\
StartLimitBurst=3\n\
\n\
[Install]\n\
WantedBy=multi-user.target' > /usr/lib/systemd/system/flatpak-preinstall.service

# This fixes a user/groups error with rebasing from other problematic images.
# FIXME Do NOT remove until fixed upstream or fixed universally. Updating with new fix also fine. Script created by Tulip.
RUN mkdir -p /usr/lib/systemd/system-preset /usr/lib/systemd/system

RUN echo -e '#!/bin/sh\ncat /usr/lib/sysusers.d/*.conf | grep -e "^g" | grep -v -e "^#" | awk "NF" | awk '\''{print $2}'\'' | grep -v -e "wheel" -e "root" -e "sudo" | xargs -I{} sed -i "/{}/d" $1' > /usr/libexec/xeniaos-group-fix
RUN chmod +x /usr/libexec/xeniaos-group-fix
RUN echo -e '[Unit]\n\
Description=Fix groups\n\
Wants=local-fs.target\n\
After=local-fs.target\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/libexec/xeniaos-group-fix /etc/group\n\
ExecStart=/usr/libexec/xeniaos-group-fix /etc/gshadow\n\
ExecStart=systemd-sysusers\n\
[Install]\n\
WantedBy=default.target multi-user.target' > /usr/lib/systemd/system/os-group-fix.service

RUN echo -e "enable os-group-fix.service" > /usr/lib/systemd/system-preset/01-xeniaos-group-fix.preset

# System services (Machine Boot level)
RUN systemctl enable polkit.service \
    NetworkManager.service \
    tuned.service \
    tuned-ppd.service \
    firewalld.service \
    flatpak-preinstall.service \
    os-group-fix.service \
    sddm.service

########################################################################################################################################
# Section 8 - CachyOS settings | Since we have the CachyOS kernel, we gotta put it to good use ≽^•⩊•^≼ ################################
########################################################################################################################################

# Activate NTSync, wags my tail in your general direction
RUN echo -e 'ntsync' > /etc/modules-load.d/ntsync.conf

# CachyOS bbr3 Config Option
RUN echo -e 'net.core.default_qdisc=fq \n\
net.ipv4.tcp_congestion_control=bbr' > /etc/sysctl.d/99-bbr3.conf

########################################################################################################################################
# Section 9 - Niri/Chezmoi/DMS | Everything to do with the desktop/visual look of your taskbar/ config files (⸝⸝>w<⸝⸝) #################
########################################################################################################################################

# Add Maple Mono font, it's so cute! It's a pain to download! You'll love it.
RUN mkdir -p "/usr/share/fonts/Maple Mono" && \
    curl --retry 5 --retry-all-errors -fsSL \
      https://github.com/subframe7536/maple-font/releases/download/v7.9/MapleMono-Variable.zip \
      -o /tmp/maple.zip && \
    unzip -q /tmp/maple.zip -d "/usr/share/fonts/Maple Mono" && \
    rm -f /tmp/maple.zip && \
    fc-cache -f || true

########################################################################################################################################
# Section 10 - Final Bootc Setup | The horrors are endless. but we stay silly :3c -junoinfernal -maia arson crimew #####################
########################################################################################################################################

RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-fix-bootc-module.conf && \
      printf 'hostonly=no\nadd_dracutmodules+=" ostree bootc "' | tee /usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-modules.conf && \
      sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
      dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

RUN rm -rf /home/build/.cache/* && \
    rm -rf \
        /tmp/* \
        /var/cache/pacman/pkg/*


# Necessary for general behavior expected by image-based systems
RUN sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd" && \
    rm -rf /boot /home /root /usr/local /srv /var /usr/lib/sysimage/log /usr/lib/sysimage/cache/pacman/pkg && \
    mkdir -p /sysroot /boot /usr/lib/ostree /var && \
    ln -s sysroot/ostree /ostree && ln -s var/roothome /root && ln -s var/srv /srv && ln -s var/opt /opt && ln -s var/mnt /mnt && ln -s var/home /home && \
    echo "$(for dir in opt home srv mnt usrlocal ; do echo "d /var/$dir 0755 root root -" ; done)" | tee -a "/usr/lib/tmpfiles.d/bootc-base-dirs.conf" && \
    printf "d /var/roothome 0700 root root -\nd /run/media 0755 root root -" | tee -a "/usr/lib/tmpfiles.d/bootc-base-dirs.conf" && \
    printf '[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n' | tee "/usr/lib/ostree/prepare-root.conf"

RUN bootc container lint
