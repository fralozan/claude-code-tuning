#!/usr/bin/env bash
# Aplica la configuración del repositorio sobre ~/.claude (idempotente).
#   ./install.sh                      configuración base
#   ./install.sh --profile servidor   además, fusiona profiles/servidor.json
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"
PROFILES=()

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

while [ $# -gt 0 ]; do
    case "$1" in
        --profile) [ -f "$REPO/profiles/${2:-}.json" ] || { warn "Perfil inexistente: ${2:-}"; exit 1; }
                   PROFILES+=("$REPO/profiles/$2.json"); shift 2 ;;
        *) warn "Argumento desconocido: $1"; exit 1 ;;
    esac
done

command -v jq >/dev/null || { warn "Falta jq: instálalo (sudo apt install jq / sudo dnf install jq / brew install jq) o ejecuta ./tools/install-tools.sh"; exit 1; }
mkdir -p "$CLAUDE_DIR/rules"

# Enlaza un archivo del repo; respalda lo existente si no es ya el enlace correcto.
link() {
    local src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then return; fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then mv "$dst" "$dst.bak-$STAMP"; warn "Respaldo: $dst.bak-$STAMP"; fi
    ln -s "$src" "$dst"
    log "Enlazado $dst"
}

link "$REPO/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
for f in "$REPO"/rules/*.md; do link "$f" "$CLAUDE_DIR/rules/$(basename "$f")"; done

# Mods incluidos en el repo (copia revisada y fijada; ver mods/*/ORIGEN.md)
mkdir -p "$CLAUDE_DIR/skills"
for m in "$REPO"/mods/*/; do link "${m%/}" "$CLAUDE_DIR/skills/$(basename "$m")"; done

# Fusión de settings.json: el repo gana en claves comunes; las listas de permisos se unen.
SETTINGS="$CLAUDE_DIR/settings.json"
merge_settings() {
    local tmp; tmp="$(mktemp "${TMPDIR:-/tmp}/claude-tuning.XXXXXX")"
    jq -s '
        .[0] as $a | .[1] as $b
        | ($a * $b)
        | .permissions.allow = ((($a.permissions.allow // []) + ($b.permissions.allow // [])) | unique)
        | .permissions.deny  = ((($a.permissions.deny  // []) + ($b.permissions.deny  // [])) | unique)
    ' "$SETTINGS" "$1" > "$tmp"
    mv "$tmp" "$SETTINGS"
}

if [ -f "$SETTINGS" ]; then
    cp "$SETTINGS" "$SETTINGS.bak-$STAMP"
    merge_settings "$REPO/claude/settings.json"
    log "settings.json fusionado (respaldo: settings.json.bak-$STAMP)"
else
    cp "$REPO/claude/settings.json" "$SETTINGS"
    log "settings.json creado"
fi
for p in ${PROFILES[@]+"${PROFILES[@]}"}; do merge_settings "$p"; log "Perfil aplicado: $(basename "$p" .json)"; done

# Plugins (requiere el binario claude)
if command -v claude >/dev/null; then
    claude plugin marketplace add midudev/better-claude >/dev/null 2>&1 \
        || warn "No se pudo añadir el marketplace better-claude (¿sin clave SSH de GitHub?). Prueba: claude plugin marketplace add https://github.com/midudev/better-claude.git"
    jq -r '.enabledPlugins | to_entries[] | select(.value) | .key | select(endswith("@better-claude"))' \
        "$REPO/claude/settings.json" | while read -r p; do
        claude plugin install "$p" >/dev/null 2>&1 && log "Plugin $p" || warn "No se pudo instalar $p"
    done
else
    warn "claude no está instalado: omitiendo plugins"
fi
log "Configuración aplicada."

# Siguientes pasos según lo que falte
missing=()
for t in gh cargo rg fd ast-grep tgrep; do command -v "$t" >/dev/null || missing+=("$t"); done
if [ "${#missing[@]}" -gt 0 ]; then
    warn "Faltan herramientas: ${missing[*]}"
    printf '   Siguiente paso: %s/tools/install-tools.sh  (luego abre una shell nueva o ejecuta: . "$HOME/.cargo/env")\n' "$REPO"
fi
if [ "${#PROFILES[@]}" -eq 0 ] && [ "$(uname -s)" = "Linux" ] && [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    printf '   Parece un entorno sin interfaz gráfica: considera %s/install.sh --profile servidor\n' "$REPO"
fi
printf '   Para verificar: %s/doctor.sh\n' "$REPO"
