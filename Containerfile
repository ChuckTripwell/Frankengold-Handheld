##################################################################################################################################################
### :::::: pull cachyos :::::: ###
##################################################################################################################################################
FROM docker.io/cachyos/cachyos-v3:latest AS cachyos

# :::::: prepare the kernel :::::: 
RUN rm -rf /lib/modules/*
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

# :::::: install additional stuff :::::: 
RUN dnf5 -y install --allowerasing python3-pygame
RUN dnf5 -y install --allowerasing tlp
  RUN systemctl enable tlp.service
RUN dnf5 -y install --allowerasing zcfan

RUN cat << 'EOF' > /tmp/millennium_v235_installer.sh
#!/usr/bin/env bash

readonly GITHUB_ACCOUNT="SteamClientHomebrew/Millennium"
readonly RELEASES_URI="https://api.github.com/repos/${GITHUB_ACCOUNT}/releases"
readonly DOWNLOAD_URI="https://github.com/${GITHUB_ACCOUNT}/releases/download"
readonly INSTALL_DIR="/tmp/millennium"
DRY_RUN=0
ALLOW_BETA=0

log() { printf "%b\n" "$1"; }
is_root() { [ "$(id -u)" -eq 0 ]; }
format_size() {
    echo "$1" | awk '{ split("B KB MB GB TB PB", v); s=1; while ($1 > 1024) { $1 /= 1024; s++ } printf "%.2f %s\n", $1, v[s] }'
}

verify_platform() {
    case $(uname -sm) in
        "Linux x86_64") echo "linux-x86_64" ;;
        *) log "Unsupported platform $(uname -sm). x86_64 is the only available platform."; exit 1 ;;
    esac
}

check_dependencies() {
    log "resolving dependencies..."
    for cmd in curl tar jq sudo; do
        command -v "${cmd}" >/dev/null || {
            log "${cmd} isn't installed. Install it from your package manager." >&2
            exit 1
        }
    done
}

fetch_release_info() {
    echo "2.35.0:35546112"
    return 0
}

remove_old_installation() {
    log ":: Cleaning up previous Millennium installations..."
    sudo rm -rf /usr/lib/millennium \
                /usr/share/millennium \
                "${XDG_CONFIG_HOME:-$HOME/.config}/millennium" \
                "${XDG_DATA_HOME:-$HOME/.local/share}/millennium"

    if [ -f "/usr/bin/steam.millennium.bak" ]; then
        log "   Restoring original steam executable..."
        sudo mv /usr/bin/steam.millennium.bak /usr/bin/steam
    fi
}

download_package() {
    local url="$1"
    local dest="$2"
    curl --fail --location --output "${dest}" "${url}"
}

extract_package() {
    local tar_file="$1"
    local extract_dir="$2"
    mkdir -p "${extract_dir}"
    tar xzf "${tar_file}" -C "${extract_dir}"
}

install_millennium() {
    local extract_path="$1"
    sudo cp -r "${extract_path}"/* / || true
}

post_install() {
    [ -f /opt/python-i686-3.11.8/bin/python3.11 ] && sudo chmod +x /opt/python-i686-3.11.8/bin/python3.11
    log "installing for '${USER}'"
    beta_file="${HOME}/.steam/steam/package/beta"
    target="${HOME}/.steam/steam/ubuntu12_32/libXtst.so.6"
    if [ -f "${beta_file}" ]; then
        log "removing beta '$(cat "${beta_file}")' in favor for stable."
        rm "${beta_file}"
    fi
    [ -d "${HOME}/.steam/steam/ubuntu12_32" ] && ln -sf /usr/lib/millennium/libmillennium_bootstrap_86x.so "${target}"
}

cleanup() {
    local dir="$1"
    log "cleaning up temporary files..."
    rm -rf "${dir}"
}

main() {
    local target release_info tag size download_uri install_dir extract_path tar_file
    if is_root; then log "Do not run as root!"; exit 1; fi
    target=$(verify_platform)
    check_dependencies
    release_info=$(fetch_release_info)
    tag="${release_info%%:*}"
    download_uri="${DOWNLOAD_URI}/v${tag}/millennium-v${tag}-${target}.tar.gz"
    remove_old_installation
    install_dir="${INSTALL_DIR}"
    extract_path="${install_dir}/files"
    tar_file="${install_dir}/millennium-v${tag}-${target}.tar.gz"
    rm -rf "${install_dir}"
    mkdir -p "${install_dir}"
    log "Downloading package..."
    download_package "${download_uri}" "${tar_file}"
    log "Unpacking..."
    extract_package "${tar_file}" "${extract_path}"
    log "Installing..."
    install_millennium "${extract_path}"
    log "Post-install..."
    post_install
    cleanup "${install_dir}"
    log "Millennium 2.35.0 base install done.\n"
}
main "$@"
EOF

RUN	bash /tmp/millennium_v235_installer.sh
RUN	rm /tmp/millennium_v235_installer.sh

##################################################################################################################################################
### :::::: end of experimental :::::: ###
##################################################################################################################################################

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
