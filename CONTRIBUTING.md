# Cómo contribuir

¡Gracias por el interés! Este repositorio es una configuración de Claude Code, así que los cambios
se evalúan con un criterio concreto.

## Criterio

Toda propuesta (añadir una herramienta, activar o desactivar un plugin, cambiar una directiva) debe
justificarse en términos de **contexto y tokens, rendimiento, reproducibilidad o seguridad**. Si es
posible, aporta mediciones (por ejemplo, la salida de `/context` antes y después).

Principios del repositorio: preferir CLI antes que MCP, instalar por proyecto lo que no se use
siempre, y no versionar nada personal.

## Qué ayuda especialmente

- **Probar en CentOS/RHEL y macOS**, que están escritos pero sin verificar (ver el README y la plantilla
  de issue "Prueba en una plataforma sin verificar").
- Convenciones para otros lenguajes en `rules/` (con `paths:` en la cabecera).
- Correcciones a cifras o afirmaciones del README que no se sostengan.

## Antes de enviar un pull request

```bash
bash -n install.sh doctor.sh tools/install-tools.sh
shellcheck --severity=warning install.sh doctor.sh tools/install-tools.sh
jq -e . claude/settings.json profiles/*.json
CLAUDE_DIR="$(mktemp -d)" ./install.sh && echo ok
```

La integración continua ejecuta estas mismas comprobaciones.

## Reglas básicas

- Documentación y comentarios en español.
- Scripts en bash compatible con la 3.2 de macOS: sin `mapfile` ni arrays asociativos, y con cuidado al
  expandir arrays vacíos bajo `set -u`.
- No incluir credenciales, rutas privadas, dominios internos ni datos personales.
- Commits en formato convencional (`feat:`, `fix:`, `docs:`…).
