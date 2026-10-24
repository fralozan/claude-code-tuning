# claude-code-tuning

Una configuración base, reproducible y comentada para usar [Claude Code](https://claude.com/claude-code)
en varias máquinas Linux **con los mismos criterios en todas**: qué herramientas usa el agente para
buscar código, qué skills y plugins están activos (y cuáles no), cómo se ahorran tokens y qué estilo
de código se espera.

Está pensado para quien usa Claude Code a diario para programar y quiere:

- que el agente **gaste menos contexto y menos tokens** sin perder precisión;
- **saber exactamente qué hay activo** en su instalación (a veces es bastante más de lo que parece);
- poder **montar una máquina nueva en minutos** y obtener el mismo comportamiento.

Es un punto de partida: haz un fork, quita lo que no te sirva y ajusta el resto a tu gusto.

> Desarrollado en Ubuntu (principal). El soporte de CentOS/RHEL (`dnf`/`yum`) está escrito pero aún
> sin probar en una máquina limpia. WSL2 con Ubuntu debería funcionar igual que Ubuntu. macOS, Arch y
> Alpine no están soportados: el instalador se detiene con un mensaje claro.

## Inicio rápido

```bash
git clone https://github.com/fralozan/claude-code-tuning.git ~/claude-code-tuning
cd ~/claude-code-tuning
./tools/install-tools.sh     # herramientas: git, jq, gh, rust, rg, fd, ast-grep, tgrep, Claude Code
. "$HOME/.cargo/env"
./install.sh                 # aplica CLAUDE.md, settings.json y plugins
./doctor.sh                  # verifica que todo quedó bien
```

Para actualizar una máquina ya configurada: `git pull && ./install.sh`.

Opciones útiles:

```bash
USE_BINSTALL=1 ./tools/install-tools.sh   # descarga binarios precompilados en vez de compilar (más rápido)
./install.sh --profile servidor           # además, desactiva skills y conectores de escritorio (ver abajo)
```

Antes de ejecutar nada, **lee los scripts** (son cortos): instalan paquetes del sistema, descargan
`rustup` y el instalador oficial de Claude Code, y modifican `~/.claude`.

## Qué incluye

| Ruta | Descripción |
|---|---|
| `claude/CLAUDE.md` | Directivas globales: cómo buscar, qué comandos preferir, cómo ahorrar tokens |
| `claude/settings.json` | Idioma, modo vim, plugins, permisos de solo lectura y `deny` para secretos |
| `rules/php.md` | Estilo PHP (PSR-12); **se carga solo al tocar archivos `.php`** (regla con `paths`) |
| `profiles/` | Ajustes opcionales por entorno, p. ej. `servidor.json` |
| `templates/ignore.example` | Plantilla de `.ignore` para que `rg`/`fd` omitan lockfiles y minificados |
| `templates/php/` | `.php-cs-fixer.dist.php`, `phpcs.xml` y `phpstan.neon` para copiar a tus proyectos |
| `skills/SKILLS.md` | Plugins y skills activos e inactivos, con el motivo de cada decisión |
| `tools/` | Instalador y guía de las herramientas de línea de comandos |
| `install.sh` / `doctor.sh` | Aplicar y verificar la configuración |

## Herramientas recomendadas y por qué

Por defecto un agente explora un proyecto con `grep`, `find` y `cat`, que devuelven mucho texto,
incluyendo archivos ignorados, y obligan a leer archivos enteros. Cada línea que entra en el
contexto cuesta tokens y desplaza información útil. Estas herramientas devuelven menos y más
relevante; `CLAUDE.md` indica al agente que las prefiera.

| Herramienta | Sustituye a | Por qué se recomienda |
|---|---|---|
| [`rg`](https://github.com/BurntSushi/ripgrep) (ripgrep) | `grep -r` | Respeta `.gitignore`, ignora binarios y `node_modules`, es muy rápido y su salida es compacta |
| [`fd`](https://github.com/sharkdp/fd) | `find` | Sintaxis simple y, como `rg`, ignora lo que está en `.gitignore` |
| [`ast-grep`](https://ast-grep.github.io/) | regex sobre código | Busca por **estructura sintáctica** (p. ej. "llamadas a esta función con 2 argumentos"), con menos falsos positivos y menos lecturas |
| [`tgrep`](https://github.com/microsoft/tgrep) | `rg` en repos grandes | Regex acelerada con un índice de trigramas; compensa en repositorios muy grandes |
| [`jq`](https://jqlang.github.io/jq/) | leer JSON a ojo | Reduce una respuesta JSON a los campos necesarios antes de que llegue al contexto |
| [`gh`](https://cli.github.com/) | navegar por la web | Issues, PRs y diffs de GitHub directamente desde la terminal |
| `git` | — | `git diff --stat`, `log`, `blame`: entender cambios sin releer archivos |
| `cargo` (Rust) | — | Es el medio de instalación de `rg`, `fd`, `ast-grep` y `tgrep` con versiones recientes y builds reproducibles (`--locked`) |

Notas honestas:

- `tgrep` **no es semántico**: es búsqueda por regex con índice. Hay que construirlo (`tgrep index .`)
  y puede ir por detrás de los cambios; en proyectos pequeños `rg` basta.
- La primera instalación con `cargo` compila y tarda unos minutos.
- Detalles de instalación, CentOS y uso de `tgrep` en [`tools/README.md`](tools/README.md).

## Qué puede estar activo en tu Claude Code sin que lo sepas

Esta es la parte que más sorprende. Lo que consume contexto **en cada sesión**, uses o no la
función, son: las descripciones de skills y comandos, las definiciones de herramientas de servidores
MCP/conectores, el contenido de `CLAUDE.md` y los hooks que inyectan texto.

Es fácil acumular cosas sin darse cuenta, por ejemplo:

- **Skills de documentos** (Word `.docx`, PowerPoint `.pptx`, Excel `.xlsx`, PDF) que vienen con la
  cuenta o con plugins.
- **Skills y conectores de Google Workspace** (Drive, Docs, Sheets, Slides) y **Calendar**.
- **Skills de proveedores cloud** instaladas por un toolkit o plugin: por ejemplo, 18 skills de AWS
  suman ~3 900 tokens de descripciones en cada sesión (medido con `/context`).
- **Servidores MCP** configurados una vez y olvidados; algunos ni siquiera conectan pero siguen
  apareciendo en la configuración.

Ninguna de estas cosas es mala. Lo que sí es un problema es tenerlas activas para trabajo que no las
usa: ocupan contexto, compiten con otras skills al decidir cuál aplicar y, en el caso de conectores,
añaden permisos y superficie de acceso a datos (correo, calendario, documentos) que no necesitas
para programar.

### Cómo auditar tu instalación

Dentro de Claude Code:

- `/context` — desglose de qué ocupa el contexto (skills, herramientas MCP, memoria, mensajes).
- `/plugin` — plugins instalados y su estado; permite desactivarlos.
- `/mcp` — servidores MCP configurados y si conectan.
- Conectores de la cuenta (Drive, Calendar, etc.) — se gestionan en **claude.ai → Ajustes → Conectores**
  para la cuenta entera; en una máquina concreta se pueden dejar de cargar con
  `"disableClaudeAiConnectors": true` en `settings.json` (ver el perfil `servidor`).
- Skills en `~/.claude/skills/` y `.claude/skills/` del proyecto — revisa qué carpetas hay.

### Criterio que aplica este repo

| Elemento | ¿Consume contexto? | Decisión |
|---|---|---|
| Skills de un proveedor cloud (p. ej. AWS) | Sí, en cada sesión | Instalar por proyecto, no globalmente |
| Conectores de Calendar, Drive, Google Workspace | Sí (herramientas y permisos) | Desactivar si no programas con ellos |
| Skills de documentos (docx/pptx/xlsx/pdf) | Sí (descripciones) | Revisar; mantener solo si las usas |
| Plugins de interfaz de better-claude | No (ver abajo) | Activos los útiles |

La conclusión práctica: **los mayores ahorros no vienen de los plugins, sino de los hábitos** de
`claude/CLAUDE.md` (buscar antes de leer, leer por rango, filtrar salidas, compactar a tiempo) y de
mantener activo solo lo que usas. Más detalle en [`skills/SKILLS.md`](skills/SKILLS.md).

## Perfiles por entorno

Qué conviene tener activo depende de **dónde** ejecutas Claude Code y de **en qué** trabajas. Las
cifras son las que muestra `/context` (aproximadas, por sesión):

| Grupo | Skills | Tokens | Perfil recomendado |
|---|---|---|---|
| **Escritorio** (necesitan la app de escritorio de Claude o un navegador con interfaz) | `computer-use` ~320, `built-in-browser` ~290, `chrome-browser` ~260, `claude-in-chrome` ~180 | ~1 050 | Útiles en tu portátil o PC; **inútiles en un VPS, EC2 o contenedor** sin pantalla |
| **Documentos y Workspace** (funcionan en cualquier entorno, pero no son de programación) | `docs` ~340, `pptx` ~330, `google-workspace` ~330, `xlsx` ~320, `docx` ~320, `pdf` ~150 | ~1 800 | Activar solo si generas o editas documentos con Claude |
| **Utilidades de cuenta** | `deep-research` ~200, `morning` ~120, `skill-creator` ~120, `import-memory` ~60 | ~500 | Según uso |
| **Proveedor cloud** (AWS: 18 skills) | `amazon-bedrock`, `aws-*`, `launch-with-aws`… | ~3 900 | **Por proyecto**, no globalmente (ver abajo) |

Resumen por entorno:

- **Portátil o escritorio de desarrollo:** todo lo que uses; el grupo "Escritorio" tiene sentido.
- **VPS, instancia EC2, contenedor o sesión por SSH:** quitar el grupo "Escritorio" sin dudar; revisar
  documentos y Workspace; cloud solo si el proyecto lo requiere.
- **Proyecto concreto con una arquitectura cloud:** activar las skills de ese proveedor solo ahí.

Para ponerlo en perspectiva: todas las skills de una instalación típica suman ~10 000 tokens, un 1 %
de una ventana de 1M (un 5 % de una de 200k). La ganancia por turno es modesta; el valor principal es
la higiene: menos ruido al elegir qué skill aplicar y menos acceso a datos que no necesitas.

> Las skills marcadas como "claude.ai sync" provienen de **tu cuenta**. En una máquina concreta puedes
> dejar de cargarlas con `"syncClaudeAiSkills": false` (y `"syncClaudeAiPlugins": false` para los
> plugins) en `~/.claude/settings.json`: es lo que hace `./install.sh --profile servidor`. La clave
> desactiva **todas** las skills sincronizadas, no una a una.

### AWS: muy útil cuando el proyecto lo requiere, no para tenerlo siempre

Las skills de AWS son de gran valor si vas a **construir o desplegar sobre AWS**: guían CDK,
CloudFormation, Lambda y serverless, contenedores (ECS/EKS), Bedrock, seguridad, costes y
observabilidad con buenas prácticas, y evitan que el agente invente comandos o configuraciones. Ese es
justamente su contexto de uso. El problema no es que existan, sino tenerlas **cargadas en cada sesión**
(~3 900 tokens) de proyectos que no usan AWS.

Se distribuyen como parte del
[Agent Toolkit for AWS](https://aws.amazon.com/es/products/developer-tools/agent-toolkit-for-aws/)
(servidor MCP gestionado, skills, plugins y archivos de reglas, gratuito: solo pagas los recursos de AWS
que se usen). Enfoque recomendado: **instalarlo por proyecto**.

```bash
# En la raíz del proyecto que usa AWS (requiere uv; credenciales de AWS solo para llamadas a la API)
claude plugin install aws-core@claude-plugins-official --scope project
# Dentro de Claude Code, recargar: /reload-plugins
```

Con `--scope project` el plugin queda ligado a ese proyecto y el resto de tus sesiones no pagan su
contexto. Para quitarlo cuando termines: `claude plugin uninstall aws-core@claude-plugins-official`.

Notas:

- Esos comandos siguen la documentación de AWS; no los he validado en todas las versiones de Claude
  Code. Si el marketplace `claude-plugins-official` no lista el plugin en tu instalación, actualízalo
  desde `/plugin`.
- AWS también ofrece `aws configure agent-toolkit` (requiere AWS CLI 2.35 o superior), que detecta los
  agentes instalados y configura skills y servidor MCP. Úsalo sabiendo que puede dejarlos activos
  de forma global; si lo ejecutaste, revisa `~/.claude/skills/` y mueve fuera lo que no quieras siempre.
- Hay más plugins en el toolkit (`aws-agents`, `aws-data-analytics`, `aws-agents-for-devsecops`) con
  el mismo criterio: instalar solo en proyectos que los necesiten.

El mismo razonamiento aplica a cualquier otro proveedor (GCP, Azure…) o framework con skills propias.

## Criterio: CLI antes que MCP

Un servidor MCP (o un plugin que lo empaqueta) carga las definiciones de **todas** sus herramientas en
el contexto, las uses o no, y suele pedir acceso a servicios externos. Si ya existe una herramienta
de línea de comandos que hace el mismo trabajo, el repositorio prefiere esa:

| En lugar de un MCP/plugin para… | Se usa | Motivo |
|---|---|---|
| GitHub (issues, PRs, diffs) | `gh` y `git` | Sin herramientas MCP en el contexto; salida filtrable con `jq` |
| Buscar o navegar el código | `rg`, `ast-grep`, `tgrep` | Locales, sin servicios externos |

Esto no significa que los MCP sean malos: son la mejor opción cuando no existe alternativa de CLI o
cuando un proyecto concreto los necesita (navegador para pruebas E2E, un servicio sin CLI…). La
regla es **añadirlos por proyecto y medirlos con `/context`**, no dejarlos activos globalmente.

## Plugins de terceros: better-claude

[`better-claude`](https://github.com/midudev/better-claude) es un marketplace de plugins de terceros
(de [midudev](https://github.com/midudev), **no es de Anthropic**) que se descubre en
<https://betterclaude.dev/>. Los plugins de este grupo que activa el repo son de interfaz y flujo:

| Plugin | Qué hace |
|---|---|
| `commit` | `/commit` divide los cambios en commits convencionales |
| `sub-meter` | Muestra el uso de la suscripción (ventana de 5 h y semanal) |
| `token-meter` | Tokens de cada turno y total de la sesión |
| `context-meter` | Cuánto contexto llevas usado; avisa cuándo `/compact` |
| `after` | `/after <tarea>` encola un prompt para cuando termine el actual |
| `use-haiku` | Un prompt que empieza por `_` se ejecuta en Haiku (más barato) |
| `think-hard` | Un prompt que empieza por `+` se ejecuta con esfuerzo máximo |

Desactivados a propósito: `image-preview` y `narrator` (no aportan al programar). Estos plugins
**no inyectan texto en el contexto** (son módulos de interfaz por hooks), así que activarlos no
cuesta tokens; los medidores ayudan a vigilar el consumo y `use-haiku` lo reduce.

Seguridad: un plugin ejecuta código en tu máquina. Revisa su código antes de instalarlo, igual que
harías con cualquier dependencia. Si prefieres no usar terceros, borra `better-claude` de
`extraKnownMarketplaces` y los `@better-claude` de `enabledPlugins` en `claude/settings.json`.

## Cómo funciona `install.sh`

- `CLAUDE.md` y cada archivo de `rules/` se **enlazan** (symlink) en `~/.claude/`: un `git pull` los
  actualiza al instante. Tus propias reglas en `~/.claude/rules/` no se tocan.
- `settings.json` se **fusiona** con `jq`: el repo gana en las claves que define, los permisos se
  unen y lo propio de cada máquina se conserva. Siempre se deja un respaldo `settings.json.bak-<fecha>`.
- Si ya tenías un `CLAUDE.md` propio, se renombra a `CLAUDE.md.bak-<fecha>`, no se pierde.
- Lo propio de una máquina se conserva porque la fusión no borra claves que el repo no define. Los
  ajustes personales de **un proyecto** van en `.claude/settings.local.json` de ese proyecto (capa
  oficial de Claude Code, fuera de git). No existe una capa `settings.local.json` a nivel de usuario.
- `--profile <nombre>` fusiona además `profiles/<nombre>.json`.
- Es idempotente: puedes ejecutarlo varias veces.

**Para deshacer:** borra los enlaces `~/.claude/CLAUDE.md` y `~/.claude/rules/php.md` y restaura los
`.bak-<fecha>` correspondientes.

### Perfil `servidor`

Para un VPS, EC2 o contenedor sin interfaz gráfica, `./install.sh --profile servidor` añade a
`settings.json`:

```json
{ "syncClaudeAiSkills": false, "syncClaudeAiPlugins": false, "disableClaudeAiConnectors": true }
```

Según la documentación de Claude Code, esto deja de cargar las skills y plugins que tu cuenta de
claude.ai sincroniza (documentos, navegador, computer-use…) y los conectores (Drive, Calendar…).
Es opcional y no se aplica por defecto. Si tu versión de Claude Code rechaza alguna clave, `claude doctor`
lo indicará.

### Cómo se combinan las instrucciones

Los `CLAUDE.md` (global, del proyecto y de subdirectorios) y las reglas de `rules/` **se concatenan**:
ninguno anula a otro. Los más cercanos al directorio de trabajo se leen al final, pero si dos
instrucciones se contradicen Claude puede seguir cualquiera. Por eso:

- Mantén cada `CLAUDE.md` por debajo de ~200 líneas (`doctor.sh` lo comprueba).
- No repitas en un proyecto lo que ya dice el global; añade solo lo específico.
- `/doctor prompt-audit` detecta instrucciones obsoletas o contradictorias.

### Archivos que no aportan al agente

Claude Code no tiene un `.claudeignore`. Para que las búsquedas no devuelvan ruido de lockfiles o
archivos minificados que sí están en git, copia la plantilla a la raíz del proyecto:

```bash
cp ~/claude-code-tuning/templates/ignore.example .ignore
```

`rg` y `fd` respetan `.ignore` (no afecta a git). Para impedir que Claude **lea** un archivo, usa
`permissions.deny`, p. ej. `"Read(./.env)"`; ten en cuenta que bloquear también impide leer cuando
sí hace falta (por ejemplo, depurar un conflicto en `composer.lock`).

## Adáptalo a tu caso

1. Haz un fork.
2. Edita `claude/CLAUDE.md`: es tu criterio de trabajo (el idioma de respuesta, qué herramientas
   preferir, cuánto detalle).
3. Edita `enabledPlugins` en `claude/settings.json` según lo que decidas tras auditar tu instalación.
4. Sustituye `rules/php.md` por las convenciones de tus lenguajes; el patrón es: un archivo por
   lenguaje con `paths:` en su cabecera (p. ej. `"**/*.py"`), para que **solo se cargue al trabajar con
   esos archivos**.
5. Ejecuta `./doctor.sh` para comprobar el resultado.

## Seguridad y privacidad

- No se versionan credenciales, historial ni sesiones (ver `.gitignore`). Si adaptas el repo, revisa
  que `settings.json` no contenga tokens, rutas privadas ni dominios internos antes de publicar tu fork.
- Cualquier plugin o marketplace (de este repo o de otro) es código que se ejecuta con tus privilegios
  y puede tocar tus archivos y credenciales. Antes de instalar uno, revisa quién lo mantiene, qué
  permisos y hooks declara y a qué servicios externos se conecta. Desconfía especialmente de los que
  ejecutan comandos de shell.
- `settings.json` incluye reglas `deny` para `.env`, `*.pem` y `*.key`.
- Los permisos `allow` son de solo lectura (búsquedas, `git diff/log`, `gh ... view`); ampliarlos es
  una decisión tuya.

## Preguntas frecuentes

**¿Sobrescribe mi configuración?** No: fusiona `settings.json` y respalda lo que reemplaza.

**¿Funciona en macOS o WSL?** WSL2 con Ubuntu debería funcionar (usa `apt`). macOS, Arch y Alpine no
están soportados: `install-tools.sh` se detiene con un mensaje claro; con `SKIP_SYSTEM_PACKAGES=1`
puedes instalar a mano las dependencias y que el script haga solo lo demás.

**¿Por qué todo está en español?** Es el idioma de trabajo de quien mantiene el repo; `claude/CLAUDE.md`
y `settings.json` (`"language": "Español"`) son lo primero que querrás cambiar si no es el tuyo.

**¿`tgrep` es obligatorio?** No. Si no lo quieres, quítalo de `install-tools.sh` y de `doctor.sh`;
`rg` cubre la mayoría de los casos.

## Contribuciones

Sugerencias e issues son bienvenidos. Si propones añadir una herramienta o desactivar un plugin,
explica el motivo en términos de **contexto, tokens, rendimiento o seguridad**; ese es el criterio
del repositorio.

## Licencia

MIT. Ver [LICENSE](LICENSE).
