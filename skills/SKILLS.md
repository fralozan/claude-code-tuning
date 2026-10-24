# Skills y plugins

La fuente de verdad es `claude/settings.json` (`enabledPlugins`). Este archivo explica el criterio.

## Activos

| Plugin | Para qué |
|---|---|
| `commit` | `/commit` en commits convencionales |
| `sub-meter` | uso de la suscripción (5 h / semanal) |
| `token-meter` | tokens por turno y total |
| `context-meter` | llenado del contexto; avisa cuándo `/compact` |
| `after` | `/after <tarea>` encola un prompt |
| `use-haiku` | prefijo `_` ejecuta el turno en Haiku (más barato) |
| `think-hard` | prefijo `+` ejecuta el turno con esfuerzo máximo |

Origen: <https://betterclaude.dev/> (repositorio `midudev/better-claude`).

## Inactivos

| Plugin / skill | Motivo |
|---|---|
| `image-preview`, `narrator` | no aportan a programar |
| `time-machine` | snapshots git por turno; ya existen los checkpoints integrados |
| `cc-plugin-telemetry` (builtin) | telemetría desactivada |
| Conectores de Calendar, Drive y similares | no son útiles al programar y consumen contexto |
| Skills de AWS (`aws-*`, `amazon-bedrock`, …) | solo activarlas en proyectos que usen AWS |

Los conectores (Calendar, Drive…) se gestionan en la cuenta de claude.ai (Ajustes → Conectores).
En una máquina concreta se pueden dejar de cargar con `disableClaudeAiConnectors: true`, y las
skills/plugins sincronizados con `syncClaudeAiSkills: false` y `syncClaudeAiPlugins: false`
(perfil `profiles/servidor.json`).

## AWS: Agent Toolkit

Las skills `aws-*` y `amazon-bedrock` forman parte del
[Agent Toolkit for AWS](https://aws.amazon.com/es/products/developer-tools/agent-toolkit-for-aws/)
(servidor MCP gestionado, skills, plugins y archivos de reglas). Para usarlo solo donde haga falta,
instalar el plugin **por proyecto** en lugar de globalmente:

```bash
claude plugin install aws-core@claude-plugins-official --scope project
```

Requiere `uv` y, para llamadas a la API, credenciales de AWS. Las 18 skills sueltas de
`~/.claude/skills/` suman ~3 900 tokens de descripciones (medido con `/context`) en cada sesión; moverlas fuera evita ese coste.

## Criterio

Cada skill o conector activo añade su descripción al contexto de **todas** las sesiones. Mantener
activo solo lo que se use a diario y habilitar el resto por proyecto.
