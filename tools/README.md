# Herramientas

| Herramienta | Binario | Para qué | Instalación |
|---|---|---|---|
| ripgrep | `rg` | búsqueda textual/regex | cargo |
| fd | `fd` | búsqueda de archivos | cargo (`fd-find`) |
| ast-grep | `ast-grep`, `sg` | búsqueda estructural (AST) | cargo |
| tgrep | `tgrep` | regex con índice de trigramas ([microsoft/tgrep](https://github.com/microsoft/tgrep)) | cargo `--git` |
| typescript-language-server | `typescript-language-server` | servidor de lenguaje para el plugin `typescript-lsp` (opcional) | npm global |
| jq | `jq` | filtrar JSON | apt / dnf |
| gh | `gh` | GitHub desde CLI | apt / repo oficial en CentOS |
| git | `git` | control de versiones | apt / dnf |
| Claude Code | `claude` | el agente | instalador oficial |

## Instalación

```bash
./tools/install-tools.sh
. "$HOME/.cargo/env"
```

El script detecta `apt` (Ubuntu/Debian) o `dnf`/`yum` (CentOS/RHEL), instala las dependencias de
compilación, `rustup`, los crates y Claude Code. Es idempotente. Si cargo ya existe, no lo reinstala.

## macOS

Requiere [Homebrew](https://brew.sh) y las Command Line Tools (`xcode-select --install`). El script
instala con `brew` `jq`, `gh`, `git`, `ripgrep`, `fd` y `ast-grep`, y solo compila `tgrep` con `cargo`.
`USE_BINSTALL` no aplica en macOS. Pensado para macOS 12.3 o superior (necesita `readlink -f`).

## Opciones

| Variable | Efecto |
|---|---|
| `USE_BINSTALL=1` | Usa [`cargo-binstall`](https://github.com/cargo-bins/cargo-binstall) para descargar binarios precompilados (segundos en vez de minutos). Si falla un crate, compila. Descarga código de terceros: revisa el script antes |
| `SKIP_SYSTEM_PACKAGES=1` | No ejecuta `apt`/`dnf`; útil en distribuciones no soportadas o si ya tienes las dependencias |
| `TGREP_GIT`, `TGREP_CRATE` | Origen alternativo de `tgrep` (por defecto, `microsoft/tgrep`) |

## Notas

- Se instalan con `cargo --locked` para builds reproducibles. La primera compilación tarda varios minutos.
- Añadir `$HOME/.cargo/bin` al `PATH` (rustup lo hace en `~/.profile`/`~/.bashrc`).
- CentOS: `jq` y `git` vienen en los repos base; `gh` se añade desde el repositorio RPM oficial.

## Uso de tgrep

`tgrep` **no es semántico**: es una búsqueda regex acelerada con un índice de trigramas.

```bash
tgrep index .          # construye el índice en .tgrep/
tgrep -- "patrón" .    # busca (usa servidor, índice o escaneo según disponibilidad)
tgrep serve .          # opcional: servidor que mantiene el índice al día
```

Añadir `.tgrep/` al `.gitignore` de cada proyecto. El índice puede ir por detrás de los cambios;
usar `--no-index` cuando importe leer los archivos actuales.
