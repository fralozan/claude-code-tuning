# Herramientas

| Herramienta | Binario | Para qué | Instalación |
|---|---|---|---|
| ripgrep | `rg` | búsqueda textual/regex | cargo |
| fd | `fd` | búsqueda de archivos | cargo (`fd-find`) |
| ast-grep | `ast-grep`, `sg` | búsqueda estructural (AST) | cargo |
| tgrep | `tgrep` | regex con índice de trigramas ([microsoft/tgrep](https://github.com/microsoft/tgrep)) | cargo `--git` |
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
