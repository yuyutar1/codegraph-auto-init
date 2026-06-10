# codegraph-auto-init

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

Un instalador de una sola línea que integra [codegraph](https://github.com/colbymchenry/codegraph) en toda tu máquina de desarrollo.
Piénsalo como `codegraph install` / `codegraph uninstall`, pero para tu entorno de shell.

## Qué hace

1. **Añade `.codegraph/` al git ignore global** (opcional — se puede omitir con `--no-ignore`)
   `.codegraph/` queda excluido del seguimiento de git en todos los repositorios, existentes y futuros.
2. **Instala un wrapper de `git` para zsh**
   Al crear un repositorio con `git init` / `git clone`, se ejecuta automáticamente `codegraph init` en segundo plano.
3. **Indexa los repositorios existentes en bloque**
   Ejecuta `codegraph init` en cada repositorio git bajo `DEV_DIR` (por defecto: `~/dev`) que aún no tenga un directorio `.codegraph`.

## Instalación

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh
```

Opciones:

```sh
# Omitir el escaneo en bloque de repositorios existentes (solo aplicar la configuración)
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh -s -- --no-scan

# Cambiar el directorio objetivo del escaneo (por defecto: ~/dev)
DEV_DIR=~/src sh -c "$(curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh)"

# No tocar el git ignore global (para quienes quieren que git rastree .codegraph)
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh -s -- --no-ignore
```

Es seguro ejecutarlo varias veces (idempotente). Los elementos ya configurados se omiten.

## Desinstalación

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh
```

Elimina la entrada del ignore global, la línea de source en `.zshrc`, el wrapper, el CLI y su configuración.
Los índices de cada repositorio (`.codegraph/`) se conservan por defecto. Para eliminarlos también:

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh -s -- --purge
```

## Cambiar los directorios de escaneo después de instalar

El instalador también coloca el comando `codegraph-auto-init` en `~/.local/bin`, por lo que no quedas atado al `DEV_DIR` elegido durante la instalación:

```sh
codegraph-auto-init scan ~/work        # indexar ya los repositorios bajo ~/work
codegraph-auto-init add-dir ~/work     # añadir ~/work a los directorios configurados
codegraph-auto-init scan               # volver a escanear todos los directorios configurados
codegraph-auto-init dirs               # listar los directorios configurados
codegraph-auto-init remove-dir ~/work  # eliminar un directorio de la configuración
```

Los directorios configurados se guardan en `~/.config/codegraph-auto-init/dirs` (uno por línea). El `DEV_DIR` de la instalación solo define el valor inicial de este archivo.

## Cómo funciona

| Objetivo | Qué ocurre |
|---|---|
| `~/.config/git/ignore` | Se añade una línea `.codegraph/` (o al archivo definido en `core.excludesFile` si está configurado) |
| `~/.config/codegraph-auto-init/git-wrapper.zsh` | El wrapper en sí. Tras un `git init` / `git clone` exitoso, detecta el nuevo repositorio y ejecuta `codegraph init` en segundo plano |
| `~/.zshrc` | Se añade una línea que hace source del archivo anterior (marcada con `# codegraph-auto-init`) |
| `~/.local/bin/codegraph-auto-init` | CLI de gestión (`scan` / `dirs` / `add-dir` / `remove-dir`) |

El wrapper no hace nada en los siguientes casos (diseño a prueba de fallos):

- el CLI `codegraph` no está en el `PATH`
- el directorio objetivo ya tiene `.codegraph/`
- repositorios bare (`git init --bare`)
- la detección del subcomando falla con opciones globales que llevan valor, como `git -C dir init`

## Requisitos

- zsh (el wrapper es solo para zsh; la configuración del ignore y el escaneo en bloque no dependen del shell)
- CLI de [codegraph](https://github.com/colbymchenry/codegraph)
- macOS / Linux

## Licencia

MIT
