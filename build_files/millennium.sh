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
