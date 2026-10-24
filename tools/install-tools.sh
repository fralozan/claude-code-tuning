#!/usr/bin/env bash
# Instala las herramientas de línea de comandos. Soporta Ubuntu/Debian (apt) y CentOS/RHEL (dnf/yum).
set -euo pipefail

# tgrep (Microsoft) no está en crates.io con este propósito: se instala desde Git.
TGREP_GIT="${TGREP_GIT:-https://github.com/microsoft/tgrep}"
TGREP_CRATE="${TGREP_CRATE:-tgrep-cli}"

# Crates instalados con cargo (binarios: rg, fd, ast-grep y sg)
CARGO_CRATES=(ripgrep fd-find ast-grep)

#   USE_BINSTALL=1                 descarga binarios precompilados (cargo-binstall) en vez de compilar
#   SKIP_SYSTEM_PACKAGES=1         omite apt/dnf (si ya tienes gcc, make, openssl-dev, curl, git, jq y gh)
USE_BINSTALL="${USE_BINSTALL:-0}"
SKIP_SYSTEM_PACKAGES="${SKIP_SYSTEM_PACKAGES:-0}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

die() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = "Linux" ] || die "Solo Linux está soportado (detectado: $(uname -s))."

SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"

install_system_packages() {
    if [ "$SKIP_SYSTEM_PACKAGES" = "1" ]; then log "Paquetes del sistema omitidos"; return; fi
    if command -v apt-get >/dev/null; then
        log "Paquetes del sistema (apt)"
        $SUDO apt-get update
        $SUDO apt-get install -y build-essential pkg-config libssl-dev curl git jq gh
    elif command -v dnf >/dev/null || command -v yum >/dev/null; then
        local pm; pm=$(command -v dnf || command -v yum)
        log "Paquetes del sistema ($(basename "$pm"))"
        $SUDO "$pm" install -y gcc gcc-c++ make pkgconf-pkg-config openssl-devel curl git jq
        # gh no viene en los repos base de CentOS
        if ! command -v gh >/dev/null; then
            $SUDO "$pm" install -y 'dnf-command(config-manager)' 2>/dev/null || true
            $SUDO "$pm" config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null || true
            $SUDO "$pm" install -y gh || warn "No se pudo instalar gh; ver https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
        fi
    else
        die "Sin apt, dnf ni yum (¿Arch, Alpine…?). Instala a mano gcc, make, openssl-dev, curl, git, jq y gh y ejecuta con SKIP_SYSTEM_PACKAGES=1."
    fi
}

install_rust() {
    if ! command -v cargo >/dev/null; then
        log "Instalando Rust (rustup)"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
    fi
    # shellcheck disable=SC1091
    [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
}

install_crates() {
    if [ "$USE_BINSTALL" = "1" ] && ! command -v cargo-binstall >/dev/null; then
        log "Instalando cargo-binstall"
        curl -L --proto '=https' --tlsv1.2 -sSf \
            https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
    fi
    for c in "${CARGO_CRATES[@]}"; do
        if [ "$USE_BINSTALL" = "1" ] && cargo binstall -y --locked "$c"; then continue; fi
        log "cargo install $c"
        cargo install --locked "$c"
    done
    if [ -n "$TGREP_GIT" ]; then
        log "cargo install tgrep ($TGREP_GIT)"
        cargo install --locked --git "$TGREP_GIT" "$TGREP_CRATE"
    else
        warn "TGREP_GIT no definido: se omite tgrep"
    fi
}

install_claude() {
    if ! command -v claude >/dev/null; then
        log "Instalando Claude Code (instalador oficial)"
        curl -fsSL https://claude.ai/install.sh | bash
    fi
}

install_system_packages
install_rust
install_crates
install_claude
log "Listo. Abrir una shell nueva o ejecutar: . \$HOME/.cargo/env  (luego ./doctor.sh)"
