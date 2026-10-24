#!/usr/bin/env bash
# Aplica la configuración del repositorio sobre ~/.claude (idempotente).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

command -v jq >/dev/null || { warn "Falta jq (ver tools/install-tools.sh)"; exit 1; }
mkdir -p "$CLAUDE_DIR"

# Enlaza un archivo/directorio del repo; respalda lo existente si no es ya el enlace correcto.
link() {
    local src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then return; fi
    [ -e "$dst" ] || [ -L "$dst" ] && mv "$dst" "$dst.bak-$STAMP" && warn "Respaldo: $dst.bak-$STAMP"
    ln -s "$src" "$dst"
    log "Enlazado $dst"
}

link "$REPO/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
link "$REPO/conventions" "$CLAUDE_DIR/conventions"

# settings.json: fusión (el repo gana en claves comunes; permisos se unen). No se pisa lo local.
SETTINGS="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS" ]; then
    cp "$SETTINGS" "$SETTINGS.bak-$STAMP"
    tmp="$(mktemp)"
    jq -s '
        .[0] as $a | .[1] as $b
        | ($a * $b)
        | .permissions.allow = ((($a.permissions.allow // []) + ($b.permissions.allow // [])) | unique)
        | .permissions.deny  = ((($a.permissions.deny  // []) + ($b.permissions.deny  // [])) | unique)
    ' "$SETTINGS" "$REPO/claude/settings.json" > "$tmp"
    mv "$tmp" "$SETTINGS"
    log "settings.json fusionado (respaldo: settings.json.bak-$STAMP)"
else
    cp "$REPO/claude/settings.json" "$SETTINGS"
    log "settings.json creado"
fi

# Plugins (requiere el binario claude)
if command -v claude >/dev/null; then
    claude plugin marketplace add midudev/better-claude 2>/dev/null || true
    jq -r '.enabledPlugins | to_entries[] | select(.value) | .key | select(endswith("@better-claude"))' \
        "$REPO/claude/settings.json" | while read -r p; do
        claude plugin install "$p" >/dev/null 2>&1 && log "Plugin $p" || warn "No se pudo instalar $p"
    done
else
    warn "claude no está instalado: omitiendo plugins"
fi
log "Hecho. Ejecutar ./doctor.sh para verificar."
