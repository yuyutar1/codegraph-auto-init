# codegraph-auto-init

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

A one-liner installer that wires [codegraph](https://www.npmjs.com/package/@codegraph-dev/codegraph) into your entire development machine.
Think of it as `codegraph install` / `codegraph uninstall`, but for your shell environment.

## What it does

1. **Adds `.codegraph/` to the global git ignore**
   `.codegraph/` is excluded from git tracking in every repository — existing and future.
2. **Installs a zsh `git` wrapper**
   Creating a repository with `git init` / `git clone` automatically runs `codegraph init` in the background.
3. **Indexes existing repositories in bulk**
   Runs `codegraph init` in every git repository under `DEV_DIR` (default: `~/dev`) that doesn't have a `.codegraph` directory yet.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh
```

Options:

```sh
# Skip the bulk scan of existing repositories (wire up the settings only)
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh -s -- --no-scan

# Change the scan target directory (default: ~/dev)
DEV_DIR=~/src sh -c "$(curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh)"
```

Safe to run repeatedly (idempotent). Already-configured items are skipped.

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh
```

Removes the global ignore entry, the source line in `.zshrc`, and the wrapper itself.
Per-repository indexes (`.codegraph/`) are kept by default. To delete them as well:

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh -s -- --purge
```

## How it works

| Target | What happens |
|---|---|
| `~/.config/git/ignore` | One `.codegraph/` line is appended (or to the file set in `core.excludesFile` if configured) |
| `~/.config/codegraph-auto-init/git-wrapper.zsh` | The wrapper itself. After a successful `git init` / `git clone`, it detects the new repository and runs `codegraph init` in the background |
| `~/.zshrc` | One line that sources the file above (tagged with a `# codegraph-auto-init` marker) |

The wrapper does nothing in the following cases (fails safe):

- the `codegraph` CLI is not on `PATH`
- the target directory already has `.codegraph/`
- bare repositories (`git init --bare`)
- subcommand detection fails on value-taking global options such as `git -C dir init`

## Requirements

- zsh (the wrapper is zsh-only; the ignore setting and the bulk scan are shell-agnostic)
- [codegraph](https://www.npmjs.com/package/@codegraph-dev/codegraph) CLI
- macOS / Linux

## License

MIT
