# codegraph-auto-init

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

Un installateur en une ligne qui intègre [codegraph](https://github.com/colbymchenry/codegraph) à l'ensemble de votre machine de développement.
Voyez-le comme `codegraph install` / `codegraph uninstall`, mais pour votre environnement shell.

## Ce qu'il fait

1. **Ajoute `.codegraph/` au git ignore global** (optionnel — désactivable avec `--no-ignore`)
   `.codegraph/` est exclu du suivi git dans tous les dépôts — existants et futurs.
2. **Installe un wrapper `git` pour zsh**
   La création d'un dépôt avec `git init` / `git clone` lance automatiquement `codegraph init` en arrière-plan.
3. **Indexe en masse les dépôts existants**
   Exécute `codegraph init` dans chaque dépôt git sous `DEV_DIR` (par défaut : `~/dev`) qui n'a pas encore de répertoire `.codegraph`.

## Installation

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh
```

Options :

```sh
# Ignorer le scan en masse des dépôts existants (appliquer uniquement la configuration)
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh -s -- --no-scan

# Changer le répertoire cible du scan (par défaut : ~/dev)
DEV_DIR=~/src sh -c "$(curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh)"

# Ne pas toucher au git ignore global (pour ceux qui veulent suivre .codegraph dans git)
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh -s -- --no-ignore
```

Peut être exécuté plusieurs fois sans risque (idempotent). Les éléments déjà configurés sont ignorés.

## Désinstallation

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh
```

Supprime l'entrée du ignore global, la ligne de source dans `.zshrc`, le wrapper, le CLI et sa configuration.
Les index de chaque dépôt (`.codegraph/`) sont conservés par défaut. Pour les supprimer également :

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh -s -- --purge
```

## Changer les répertoires de scan après l'installation

L'installateur place aussi la commande `codegraph-auto-init` dans `~/.local/bin`, vous n'êtes donc pas lié au `DEV_DIR` choisi à l'installation :

```sh
codegraph-auto-init scan ~/work        # indexer immédiatement les dépôts sous ~/work
codegraph-auto-init add-dir ~/work     # ajouter ~/work aux répertoires configurés
codegraph-auto-init scan               # rescanner tous les répertoires configurés
codegraph-auto-init dirs               # lister les répertoires configurés
codegraph-auto-init remove-dir ~/work  # retirer un répertoire de la configuration
```

Les répertoires configurés sont stockés dans `~/.config/codegraph-auto-init/dirs` (un par ligne). Le `DEV_DIR` de l'installation ne fait qu'initialiser ce fichier.

## Fonctionnement

| Cible | Ce qui se passe |
|---|---|
| `~/.config/git/ignore` | Une ligne `.codegraph/` est ajoutée (ou au fichier défini dans `core.excludesFile` s'il est configuré) |
| `~/.config/codegraph-auto-init/git-wrapper.zsh` | Le wrapper lui-même. Après un `git init` / `git clone` réussi, il détecte le nouveau dépôt et exécute `codegraph init` en arrière-plan |
| `~/.zshrc` | Une ligne qui source le fichier ci-dessus est ajoutée (marquée par `# codegraph-auto-init`) |
| `~/.local/bin/codegraph-auto-init` | CLI de gestion (`scan` / `dirs` / `add-dir` / `remove-dir`) |

Le wrapper ne fait rien dans les cas suivants (conception à sécurité intégrée) :

- le CLI `codegraph` n'est pas dans le `PATH`
- le répertoire cible contient déjà `.codegraph/`
- dépôts bare (`git init --bare`)
- la détection de la sous-commande échoue avec des options globales à valeur, comme `git -C dir init`

## Prérequis

- zsh (le wrapper est réservé à zsh ; la configuration du ignore et le scan en masse sont indépendants du shell)
- CLI [codegraph](https://github.com/colbymchenry/codegraph)
- macOS / Linux

## Licence

MIT
