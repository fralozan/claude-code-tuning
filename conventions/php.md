# Convenciones PHP

Base: **PSR-12** (que extiende PSR-1) y PSR-4 para autoload. Sin dependencia de ningún framework.

## Estilo

- `<?php` sin cierre `?>` en archivos que solo contienen PHP.
- `declare(strict_types=1);` en la línea siguiente a la apertura, en todo archivo.
- Sangría de 4 espacios, sin tabuladores; líneas de hasta 120 caracteres (límite blando).
- Una clase por archivo; `StudlyCaps` para clases, `camelCase` para métodos y propiedades, `UPPER_SNAKE_CASE` para constantes.
- Llaves de clases y métodos en línea propia; las de estructuras de control en la misma línea.
- Arrays con sintaxis corta `[]` y coma final en listas multilínea.
- Importar con `use` (sin nombres completamente calificados en el cuerpo), ordenados alfabéticamente.

## Tipado y diseño

- Tipar parámetros, retornos y propiedades; usar `?T`/uniones en lugar de `mixed` cuando sea posible.
- `final` por defecto en clases que no estén pensadas para heredarse; `readonly` cuando aplique.
- Preferir inyección de dependencias por constructor; evitar estado global y singletons.
- Excepciones específicas; no silenciar errores con `@`.
- PHPDoc solo cuando aporte información que el tipo no expresa (p. ej. `@param list<int>`).

## Verificación

Configuración lista en `templates/php/` (copiar al proyecto):

| Herramienta | Archivo | Comando |
|---|---|---|
| php-cs-fixer | `.php-cs-fixer.dist.php` | `vendor/bin/php-cs-fixer fix --dry-run --diff` |
| phpcs | `phpcs.xml` | `vendor/bin/phpcs` |
| phpstan | `phpstan.neon` | `vendor/bin/phpstan analyse` |

Tras modificar PHP: `php -l` en los archivos tocados y ejecutar las tres herramientas si el proyecto las tiene.
