# codegraph-auto-init

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

一条命令即可将 [codegraph](https://www.npmjs.com/package/@codegraph-dev/codegraph) 配置应用到整台开发机器的安装器。
就像 `codegraph install` / `codegraph uninstall` 一样,可以一键接入或移除 shell 环境配置。

## 功能

1. **将 `.codegraph/` 添加到全局 git ignore**(可选 — 可用 `--no-ignore` 跳过)
   所有仓库(现有的和未来的)中,`.codegraph/` 都不会被 git 跟踪。
2. **安装 zsh 的 `git` 包装函数**
   使用 `git init` / `git clone` 创建仓库时,会自动在后台运行 `codegraph init`。
3. **批量索引现有仓库**
   对 `DEV_DIR`(默认: `~/dev`)下所有 git 仓库运行 `codegraph init`(仅限尚无 `.codegraph` 目录的仓库)。

## 安装

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh
```

选项:

```sh
# 跳过对现有仓库的批量扫描(仅接入配置)
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh -s -- --no-scan

# 更改扫描目标目录(默认: ~/dev)
DEV_DIR=~/src sh -c "$(curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh)"

# 不修改全局 git ignore(适合想让 git 跟踪 .codegraph 的用户)
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh -s -- --no-ignore
```

可以安全地重复执行(幂等)。已配置的项目会被跳过。

## 卸载

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh
```

删除全局 ignore 条目、`.zshrc` 中的 source 行、包装函数本体、CLI 及其配置。
各仓库的索引(`.codegraph/`)默认保留。如需一并删除:

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh -s -- --purge
```

## 安装后更改扫描目录

安装器还会将 `codegraph-auto-init` 命令安装到 `~/.local/bin`,因此你不会被安装时选择的 `DEV_DIR` 所限制:

```sh
codegraph-auto-init scan ~/work        # 立即批量索引 ~/work 下的仓库
codegraph-auto-init add-dir ~/work     # 将 ~/work 添加到扫描目录配置
codegraph-auto-init scan               # 重新扫描所有已配置的目录
codegraph-auto-init dirs               # 列出已配置的目录
codegraph-auto-init remove-dir ~/work  # 从配置中移除目录
```

扫描目录保存在 `~/.config/codegraph-auto-init/dirs`(每行一个目录)。安装时的 `DEV_DIR` 只是该文件的初始值。

## 工作原理

| 目标 | 内容 |
|---|---|
| `~/.config/git/ignore` | 追加一行 `.codegraph/`(如已配置 `core.excludesFile`,则写入该文件) |
| `~/.config/codegraph-auto-init/git-wrapper.zsh` | 包装函数本体。`git init` / `git clone` 成功后,检测新仓库并在后台运行 `codegraph init` |
| `~/.zshrc` | 追加一行 source 上述文件的语句(带 `# codegraph-auto-init` 标记) |
| `~/.local/bin/codegraph-auto-init` | 管理 CLI(`scan` / `dirs` / `add-dir` / `remove-dir`) |

以下情况包装函数不做任何操作(故障安全设计):

- `PATH` 中没有 `codegraph` CLI
- 目标目录已存在 `.codegraph/`
- bare 仓库(`git init --bare`)
- 遇到 `git -C dir init` 这类带值的全局选项导致子命令检测失败时

## 环境要求

- zsh(包装函数仅支持 zsh;ignore 配置和批量扫描与 shell 无关)
- [codegraph](https://www.npmjs.com/package/@codegraph-dev/codegraph) CLI
- macOS / Linux

## 许可证

MIT
