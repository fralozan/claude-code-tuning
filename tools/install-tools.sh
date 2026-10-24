#!/usr/bin/env bash
# Instala las herramientas de línea de comandos. Soporta Ubuntu/Debian (apt) y CentOS/RHEL (dnf/yum).
set -euo pipefail

# tgrep (Microsoft) no está en crates.io con este propósito: se instala desde Git.
TGREP_GIT="${TGREP_GIT:-https://github.com/microsoft/tgrep}"
TGREP_CRATE="${TGREP_CRATE:-tgrep-cli}"

# Crates instalados con cargo (binarios: rg, fd, ast-grep/sg, sg)
CARGO_CRATES=(ripgrep fd-find ast-grep)

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"

install_system_packages() {
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
        warn "Gestor de paquetes no soportado: instalar manualmente gcc, make, openssl-devel, curl, git, jq y gh"
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
    for c in "${CARGO_CRATES[@]}"; do
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
