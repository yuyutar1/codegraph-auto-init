# codegraph-auto-init

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

[codegraph](https://github.com/colbymchenry/codegraph) 설정을 개발 머신 전체에 한 번에 적용하는 인스톨러입니다.
`codegraph install` / `codegraph uninstall`과 같은 감각으로 셸 환경에 설치하고 제거할 수 있습니다.

## 하는 일

1. **글로벌 git ignore에 `.codegraph/` 추가**(선택 사항 — `--no-ignore`로 건너뛰기 가능)
   모든 저장소(기존 및 향후)에서 `.codegraph/`가 git 추적 대상에서 제외됩니다.
2. **zsh / bash / fish의 `git` 래퍼 설치**
   `git init` / `git clone`으로 저장소를 만들면 백그라운드에서 `codegraph init`이 자동으로 실행됩니다.
3. **기존 저장소 일괄 인덱싱**
   `DEV_DIR`(기본값: `~/dev`) 아래의 모든 git 저장소에서 `codegraph init`을 실행합니다(`.codegraph`가 없는 저장소만).

## 설치

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh
```

옵션:

```sh
# 기존 저장소 일괄 스캔 건너뛰기(설정만 적용)
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh -s -- --no-scan

# 스캔 대상 디렉터리 변경(기본값: ~/dev)
DEV_DIR=~/src sh -c "$(curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh)"

# 글로벌 git ignore를 건드리지 않음(.codegraph를 git으로 관리하고 싶은 경우)
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh -s -- --no-ignore
```

여러 번 실행해도 안전합니다(멱등성). 이미 설정된 항목은 건너뜁니다.

## 제거

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh
```

글로벌 ignore 항목, `.zshrc`의 source 줄, 래퍼 본체, CLI와 설정을 삭제합니다.
각 저장소의 인덱스(`.codegraph/`)는 기본적으로 유지됩니다. 인덱스까지 삭제하려면:

```sh
curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh -s -- --purge
```

## 설치 후 스캔 디렉터리 변경

인스톨러는 `~/.local/bin`에 `codegraph-auto-init` 명령도 설치하므로, 설치 시점에 선택한 `DEV_DIR`에 묶이지 않습니다:

```sh
codegraph-auto-init scan ~/work        # ~/work 아래 저장소를 지금 바로 일괄 인덱싱
codegraph-auto-init add-dir ~/work     # 스캔 디렉터리 설정에 ~/work 추가
codegraph-auto-init scan               # 설정된 모든 디렉터리 재스캔
codegraph-auto-init dirs               # 설정된 디렉터리 목록 표시
codegraph-auto-init remove-dir ~/work  # 설정에서 디렉터리 제거
```

스캔 디렉터리는 `~/.config/codegraph-auto-init/dirs`(한 줄에 하나)에 저장됩니다. 설치 시의 `DEV_DIR`은 이 파일의 초기값일 뿐입니다.

## 동작 방식

| 대상 | 내용 |
|---|---|
| `~/.config/git/ignore` | `.codegraph/` 한 줄 추가(`core.excludesFile`이 설정된 경우 해당 파일에 추가) |
| `~/.config/codegraph-auto-init/git-wrapper.sh` | zsh / bash용 래퍼 본체. `git init` / `git clone` 성공 후 새 저장소를 감지하여 백그라운드에서 `codegraph init` 실행 |
| `~/.zshrc` / `~/.bashrc` | 위 파일을 source하는 줄을 각각 한 줄 추가(`# codegraph-auto-init` 마커 포함. 해당 셸이 있을 때만) |
| `~/.config/fish/conf.d/codegraph-auto-init.fish` | fish용 래퍼. fish가 자동 로드(fish 사용 시에만 설치) |
| `~/.local/bin/codegraph-auto-init` | 관리 CLI(`scan` / `dirs` / `add-dir` / `remove-dir`) |

래퍼는 다음 경우에 아무 동작도 하지 않습니다(안전 우선 설계):

- `codegraph` CLI가 PATH에 없는 경우
- 대상 디렉터리에 이미 `.codegraph/`가 있는 경우
- bare 저장소(`git init --bare`)
- `git -C dir init`처럼 값을 갖는 글로벌 옵션으로 하위 명령 감지에 실패한 경우

## 요구 사항

| 요구 사항 | 필요한 경우 | 비고 |
|---|---|---|
| macOS / Linux | 전체 | POSIX sh와 `find` / `grep` 사용. Windows는 지원하지 않음 |
| git 1.7.12+ | 전체 | 기본 글로벌 ignore 경로 `~/.config/git/ignore`는 1.7.12 이상 필요. 최신 git이면 문제 없음 |
| curl | 설치 / 제거 | 원라이너 실행 시에만 필요. 로컬 checkout에서 실행할 때는 불필요 |
| zsh / bash / fish | `git init` / `git clone` 시 자동 init | 머신에 있는 셸마다 래퍼를 설치. ignore 설정·CLI·일괄 스캔은 어떤 셸에서도 동작 |
| [codegraph](https://github.com/colbymchenry/codegraph) CLI | 인덱싱(래퍼와 `scan`) | 없어도 설치 자체는 완료(초기 스캔은 건너뜀). 나중에 설치 후 `codegraph-auto-init scan` 실행 |
| `~/.local/bin`이 `PATH`에 포함 | `codegraph-auto-init` 명령 사용 | 없으면 인스톨러가 경고 표시 |

## 라이선스

MIT
