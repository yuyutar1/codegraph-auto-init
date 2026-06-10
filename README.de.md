# codegraph-auto-init

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

Ein Einzeiler-Installer, der [codegraph](https://github.com/colbymchenry/codegraph) auf der gesamten Entwicklungsmaschine einrichtet.
Stellen Sie es sich wie `codegraph install` / `codegraph uninstall` vor — nur für Ihre Shell-Umgebung.

## Was es macht

1. **Fügt `.codegraph/` zur globalen git ignore hinzu** (optional — mit `--no-ignore` überspringbar)
   `.codegraph/` wird in allen Repositories — bestehenden und zukünftigen — vom git-Tracking ausgeschlossen.
2. **Installiert einen `git`-Wrapper für zsh**
   Beim Erstellen eines Repositories mit `git init` / `git clone` wird automatisch `codegraph init` im Hintergrund ausgeführt.
3. **Indexiert bestehende Repositories im Stapel**
   Führt `codegraph init` in jedem git-Repository unter `DEV_DIR` (Standard: `~/dev`) aus, das noch kein `.codegraph`-Verzeichnis hat.

## Installation

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh
```

Optionen:

```sh
# Stapel-Scan bestehender Repositories überspringen (nur Konfiguration einrichten)
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh -s -- --no-scan

# Zielverzeichnis des Scans ändern (Standard: ~/dev)
DEV_DIR=~/src sh -c "$(curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh)"

# Die globale git ignore nicht anfassen (für alle, die .codegraph mit git versionieren möchten)
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh -s -- --no-ignore
```

Mehrfache Ausführung ist sicher (idempotent). Bereits konfigurierte Punkte werden übersprungen.

## Deinstallation

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh
```

Entfernt den Eintrag aus der globalen ignore, die source-Zeile in `.zshrc`, den Wrapper selbst, das CLI und seine Konfiguration.
Die Indizes der einzelnen Repositories (`.codegraph/`) bleiben standardmäßig erhalten. Um sie ebenfalls zu löschen:

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh -s -- --purge
```

## Scan-Verzeichnisse nach der Installation ändern

Der Installer legt zusätzlich den Befehl `codegraph-auto-init` in `~/.local/bin` ab — Sie sind also nicht an das bei der Installation gewählte `DEV_DIR` gebunden:

```sh
codegraph-auto-init scan ~/work        # Repositories unter ~/work sofort indexieren
codegraph-auto-init add-dir ~/work     # ~/work zu den konfigurierten Verzeichnissen hinzufügen
codegraph-auto-init scan               # alle konfigurierten Verzeichnisse erneut scannen
codegraph-auto-init dirs               # konfigurierte Verzeichnisse auflisten
codegraph-auto-init remove-dir ~/work  # Verzeichnis aus der Konfiguration entfernen
```

Die konfigurierten Verzeichnisse liegen in `~/.config/codegraph-auto-init/dirs` (eines pro Zeile). Das `DEV_DIR` bei der Installation setzt nur den Anfangswert dieser Datei.

## Funktionsweise

| Ziel | Was passiert |
|---|---|
| `~/.config/git/ignore` | Eine Zeile `.codegraph/` wird angehängt (bzw. an die in `core.excludesFile` konfigurierte Datei) |
| `~/.config/codegraph-auto-init/git-wrapper.zsh` | Der Wrapper selbst. Nach einem erfolgreichen `git init` / `git clone` erkennt er das neue Repository und führt `codegraph init` im Hintergrund aus |
| `~/.zshrc` | Eine Zeile, die die obige Datei sourct (markiert mit `# codegraph-auto-init`) |
| `~/.local/bin/codegraph-auto-init` | Verwaltungs-CLI (`scan` / `dirs` / `add-dir` / `remove-dir`) |

Der Wrapper tut in folgenden Fällen nichts (Fail-safe-Design):

- das `codegraph`-CLI ist nicht im `PATH`
- das Zielverzeichnis enthält bereits `.codegraph/`
- Bare-Repositories (`git init --bare`)
- die Erkennung des Unterbefehls schlägt bei wertnehmenden globalen Optionen wie `git -C dir init` fehl

## Voraussetzungen

- zsh (der Wrapper ist zsh-spezifisch; die ignore-Konfiguration und der Stapel-Scan sind Shell-unabhängig)
- [codegraph](https://github.com/colbymchenry/codegraph) CLI
- macOS / Linux

## Lizenz

MIT
