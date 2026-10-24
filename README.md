# claude-code-tuning

Base reproducible para usar [Claude Code](https://claude.com/claude-code) en varias máquinas Linux
(Ubuntu como principal, CentOS como alternativa) con los mismos criterios: directivas globales,
comandos alternativos, plugins activos/inactivos, estilo de código PHP y herramientas de apoyo.

## Inicio rápido (máquina nueva)

```bash
git clone git@github.com:fralozan/claude-code-tuning.git ~/claude-code-tuning
cd ~/claude-code-tuning
./tools/install-tools.sh     # git, jq, gh, rust, rg, fd, ast-grep, tgrep (Microsoft), Claude Code
. "$HOME/.cargo/env"
./install.sh                 # enlaza CLAUDE.md, fusiona settings.json, instala plugins
./doctor.sh                  # verifica todo
```

Para actualizar una máquina: `git pull && ./install.sh`.

## Contenido

| Ruta | Descripción |
|---|---|
| `claude/CLAUDE.md` | directivas globales (búsqueda, comandos alternativos, ahorro de tokens) |
| `claude/settings.json` | idioma, modo vim, plugins, permisos (se **fusiona**, no se sobrescribe) |
| `conventions/php.md` | estilo PHP: PSR-12 y verificación |
| `templates/php/` | `.php-cs-fixer.dist.php`, `phpcs.xml`, `phpstan.neon` para copiar a los proyectos |
| `skills/SKILLS.md` | plugins/skills activos, inactivos y criterio |
| `tools/` | instalación y descripción de herramientas (cargo, rg, fd, ast-grep, tgrep…) |
| `install.sh` / `doctor.sh` | aplicar y verificar la configuración |

## Cómo funciona `install.sh`

- `CLAUDE.md` y `conventions/` se **enlazan** (symlink): un `git pull` los actualiza al instante.
- `settings.json` se **fusiona** con `jq`: el repo gana en las claves que define y los permisos se unen,
  de modo que lo propio de cada máquina se conserva. Siempre se deja un respaldo `.bak-<fecha>`.
- Los ajustes exclusivos de una máquina van en `~/.claude/settings.local.json` (nunca se versiona).

## Qué activar y qué no (y por qué)

No todo lo que se desactiva ahorra tokens. Lo que realmente ocupa contexto en **cada** sesión son:
las descripciones de skills y comandos, las definiciones de herramientas MCP, el `CLAUDE.md` y los
hooks que inyectan texto. Criterio aplicado, con lo medido:

| Elemento | ¿Consume contexto? | Decisión |
|---|---|---|
| 18 skills de AWS en `~/.claude/skills/` | Sí: ~12 600 caracteres de descripciones (~3 100 tokens) en cada sesión, se use AWS o no. Además compiten con otras skills al decidir cuál aplicar | No instalar globalmente; activar por proyecto (ver `skills/SKILLS.md`) |
| Conectores (Calendar, Drive…) | Añaden herramientas y permisos ajenos a programar | Desactivar en claude.ai; no medido aquí |
| Plugins de better-claude (`*-meter`, `after`, `use-haiku`, `think-hard`) | **No**: son módulos de interfaz por hooks y ninguno inyecta contexto (verificado: sin `additionalContext`) | Activos; los medidores ayudan a vigilar el consumo y `use-haiku` lo reduce |
| `commit` | Mínimo: una descripción de comando | Activo |
| `image-preview`, `narrator` | No consumen tokens; solo CPU/ruido | Inactivos por preferencia |
| `time-machine` | No consume tokens; escribe snapshots git por turno | Inactivo: Claude Code ya incluye checkpoints propios |

Los mayores ahorros no vienen de los plugins sino de los hábitos de `claude/CLAUDE.md`: buscar antes
de leer, leer por rango, filtrar salidas y compactar.

## Seguridad

El repositorio es público: no incluir tokens, rutas privadas, dominios internos ni
`settings.local.json`. El `.gitignore` excluye historial, sesiones y credenciales.

## Licencia

MIT. Ver [LICENSE](LICENSE).
