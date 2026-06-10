# codegraph-auto-init

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

[codegraph](https://www.npmjs.com/package/@codegraph-dev/codegraph) のセットアップを開発マシン全体に一発で適用するインストーラです。
`codegraph install` / `codegraph uninstall` のような感覚で、シェル環境への組み込みと解除ができます。

## やること

1. **グローバル git ignore に `.codegraph/` を追加**(任意 — `--no-ignore` でスキップ可)
   すべてのリポジトリ(既存・将来)で `.codegraph/` が git の追跡対象外になります。
2. **zsh の `git` ラッパーを設置**
   `git init` / `git clone` でリポジトリを作ると、自動でバックグラウンドの `codegraph init` が走ります。
3. **既存リポジトリの一括インデックス**
   `DEV_DIR`(デフォルト: `~/dev`)以下のすべての git リポジトリで `codegraph init` を実行します(`.codegraph` がないリポジトリのみ)。

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh
```

オプション:

```sh
# 既存リポジトリの一括スキャンをスキップ(設定の組み込みのみ)
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh -s -- --no-scan

# スキャン対象ディレクトリを変更(デフォルト: ~/dev)
DEV_DIR=~/src sh -c "$(curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh)"

# グローバル git ignore に手を加えない(.codegraph を git 管理したい人向け)
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh -s -- --no-ignore
```

何度実行しても安全です(冪等)。設定済みの項目はスキップされます。

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh
```

グローバル ignore のエントリ・`.zshrc` の source 行・ラッパー本体・CLI と設定を削除します。
各リポジトリのインデックス(`.codegraph/`)はデフォルトで残します。インデックスごと消す場合:

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh -s -- --purge
```

## インストール後のスキャン対象変更

インストーラは `~/.local/bin` に `codegraph-auto-init` コマンドも設置するため、install 時の `DEV_DIR` に縛られません:

```sh
codegraph-auto-init scan ~/work        # ~/work 以下を今すぐ一括インデックス
codegraph-auto-init add-dir ~/work     # スキャン対象ディレクトリに ~/work を追加
codegraph-auto-init scan               # 設定済みディレクトリすべてを再スキャン
codegraph-auto-init dirs               # 設定済みディレクトリの一覧
codegraph-auto-init remove-dir ~/work  # 設定から削除
```

スキャン対象は `~/.config/codegraph-auto-init/dirs`(1行1ディレクトリ)に保存されます。install 時の `DEV_DIR` はこのファイルの初期値になるだけです。

## 仕組み

| 対象 | 内容 |
|---|---|
| `~/.config/git/ignore` | `.codegraph/` を1行追加(`core.excludesFile` 設定済みの場合はそのファイル) |
| `~/.config/codegraph-auto-init/git-wrapper.zsh` | ラッパー本体。`git init` / `git clone` 成功後に新リポジトリを検出して `codegraph init` をバックグラウンド実行 |
| `~/.zshrc` | 上記ファイルを source する行を1行追加(`# codegraph-auto-init` マーカー付き) |
| `~/.local/bin/codegraph-auto-init` | 管理 CLI(`scan` / `dirs` / `add-dir` / `remove-dir`) |

ラッパーは以下の場合は何もしません(安全側に倒れる設計):

- `codegraph` CLI が PATH にない
- 対象ディレクトリに既に `.codegraph/` がある
- bare リポジトリ(`git init --bare`)
- `git -C dir init` のような値付きグローバルオプションでサブコマンド検出に失敗した場合

## Requirements

- zsh(ラッパーは zsh 専用。ignore 設定と一括スキャンはシェル非依存)
- [codegraph](https://www.npmjs.com/package/@codegraph-dev/codegraph) CLI
- macOS / Linux

## License

MIT
