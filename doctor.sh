#!/usr/bin/env bash
# Verifica herramientas, enlaces y configuración.
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail=0
ok()  { printf '\033[32m ok \033[0m %s\n' "$*"; }
bad() { printf '\033[31mFALLA\033[0m %s\n' "$*"; fail=1; }

for t in git gh jq cargo rg fd ast-grep tgrep claude; do
    command -v "$t" >/dev/null && ok "$t" || bad "$t no está en PATH"
done
check_link() {
    [ "$(readlink -f "$CLAUDE_DIR/$1" 2>/dev/null)" = "$(readlink -f "$REPO/$2")" ] \
        && ok "enlace $1" || bad "enlace $1 no apunta al repo"
}
check_link CLAUDE.md claude/CLAUDE.md
for f in "$REPO"/rules/*.md; do check_link "rules/$(basename "$f")" "rules/$(basename "$f")"; done
lines=$(wc -l < "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null | tr -d ' ' || echo 0)
if [ "$lines" -gt 200 ]; then bad "CLAUDE.md tiene $lines líneas (recomendado: menos de 200)"; else ok "CLAUDE.md: $lines líneas (< 200)"; fi
jq -e . "$CLAUDE_DIR/settings.json" >/dev/null 2>&1 && ok "settings.json válido" || bad "settings.json inválido"
[ "$fail" -eq 0 ] || printf '\nSi faltan herramientas, ejecuta ./tools/install-tools.sh y abre una shell nueva (o: . "$HOME/.cargo/env").\n'
exit $fail
