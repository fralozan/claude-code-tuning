# Directivas globales

## Principios

- Priorizar precisión y eficiencia de contexto.
- Buscar antes de leer.
- Leer únicamente los archivos y fragmentos necesarios.
- Evitar cargar directorios o archivos completos cuando una búsqueda pueda identificar primero el contexto relevante.
- No repetir información que ya esté disponible en el contexto.
- Antes de modificar código, localizar primero la implementación existente y sus referencias.
- Después de modificar código, ejecutar las verificaciones relevantes.

## Herramientas disponibles

El entorno dispone de:

- `tgrep`: búsqueda regex indexada por trigramas (rápida en repositorios grandes; requiere `tgrep index .` o `tgrep serve .`).
- `rg`: búsqueda textual y expresiones regulares.
- `ast-grep`: búsqueda estructural mediante AST.
- `git`: estado, diferencias e historial.
- `gh`: interacción con GitHub.
- `jq`: filtrado y reducción de JSON.

Estas herramientas deben estar disponibles en `PATH`. Verificar su existencia si fuese necesario.

## Estrategia de búsqueda

Seleccionar la herramienta más apropiada según la consulta:

1. `tgrep` para búsquedas regex en repositorios grandes (más rápido que `rg` con índice construido; si el índice puede estar desactualizado, usar `--no-index`).
2. `rg` para nombres, cadenas, referencias y patrones textuales conocidos.
3. `ast-grep` para patrones que dependan de la estructura sintáctica.
4. `git` para comprender cambios, historial y evolución del código.
5. `gh` para consultar información disponible en GitHub.
6. `jq` para reducir respuestas JSON antes de procesarlas.

No ejecutar búsquedas redundantes con varias herramientas si una sola puede resolver la consulta.

## Minimización de contexto

Evitar inspeccionar salvo que sea estrictamente necesario:

- `.git/`
- `node_modules/`
- `vendor/`
- `cache/`
- `tmp/`
- `logs/`
- archivos generados
- archivos binarios
- dependencias externas
- directorios de compilación
- archivos no relacionados con la tarea

Cuando una herramienta produzca una salida extensa, filtrarla antes de incorporarla al contexto.

Preferir:

```text
buscar → identificar → inspeccionar → modificar → verificar
```

sobre:

```text
leer → leer → leer → intentar comprender
```

## Git y GitHub

Utilizar `git diff` para comprender cambios existentes antes de volver a leer archivos completos.

Utilizar `git log`, `git show` y `git blame` cuando el historial pueda proporcionar contexto relevante.

Utilizar `gh` para información de GitHub que pueda obtenerse directamente mediante CLI, evitando navegación web innecesaria.

## Cambios de código

Antes de modificar un archivo:

1. Localizar la implementación relevante.
2. Identificar dependencias y referencias importantes.
3. Comprender el patrón existente.
4. Realizar el cambio mínimo necesario.

No modificar archivos no relacionados con la tarea.

No introducir dependencias, abstracciones o archivos adicionales sin necesidad.

## Verificación

Después de modificar código:

1. Revisar el diff.
2. Ejecutar validaciones, pruebas o linters relevantes.
3. Corregir los problemas encontrados.
4. Informar únicamente los resultados relevantes.

## Instrucciones específicas

Las instrucciones de este archivo son globales.

Las instrucciones encontradas en `CLAUDE.md` o `AGENTS.md` dentro del proyecto o de un subdirectorio pueden añadir o especializar estas directivas.

Las reglas específicas del proyecto tienen prioridad cuando exista una diferencia contextual.

## Comandos alternativos

Preferir siempre la herramienta moderna; usar la clásica solo si la primera no puede hacer el trabajo.

| En lugar de | Usar | Motivo |
|---|---|---|
| `grep -r` | `rg` | respeta `.gitignore`, salida compacta |
| `find` | `fd` | sintaxis simple, ignora ruido |
| `cat` de un archivo grande | `rg -n patrón archivo` o lectura por rango | evita cargar el archivo completo |
| `git diff` completo | `git diff --stat` primero, luego por archivo | ver el alcance antes del detalle |
| respuesta JSON completa | `jq` con filtro | solo los campos necesarios |
| regex repetidas en repos grandes | `tgrep` | índice de trigramas |
| regex para encontrar código por forma | `ast-grep` | coincide por estructura, no por texto |

## Ahorro de tokens y memoria

- Limitar la salida: `rg -m`, `head`, `--stat`, `jq` con filtros; nunca volcar salidas largas completas.
- Leer por rango (`offset`/`limit`) en lugar de archivos enteros.
- No releer lo que ya está en el contexto ni lo que `git diff` ya mostró.
- Delegar exploraciones amplias a subagentes para no contaminar el contexto principal.
- Sugerir `/compact` o una sesión nueva cuando el contexto esté saturado o cambie la tarea.
- Respuestas breves: resultados y decisiones, sin narrar cada paso.

## PHP

Al trabajar en proyectos PHP, seguir `~/.claude/conventions/php.md` (PSR-12, `strict_types`, herramientas de verificación). No cargarlo en proyectos que no sean PHP.
