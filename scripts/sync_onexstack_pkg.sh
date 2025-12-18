#!/usr/bin/env bash
# 若被 sh 调用，先友好提示并退出，避免因数组语法等 bash 特性报错
if [ -z "${BASH_VERSION:-}" ]; then
  echo "请使用 bash 运行本脚本：bash $0 或直接 ./$(basename "$0")" >&2
  exit 1
fi
# 同步 github.com/onexstack/onexstack/pkg 到本仓库 pkg 目录的辅助脚本。
# 版本选择优先取 go.mod 中声明的 github.com/onexstack/onexstack 版本，
# 如需覆盖可通过参数或 ONEXSTACK_REF 环境变量指定。
# 同步后自动将 import 路径从 github.com/onexstack/onexstack/pkg
# 替换为当前项目 module 名（go.mod 的 module 值）下的 pkg，保持风格一致。
# 会将上游 pkg 的内容直接平铺到本仓库 pkg/ 下，并排除上游的 .gitignore、go.mod、go.sum。
# 同步到目标时默认采用“增量合并”（不删除本地已有的额外内容，例如自定义目录），
# 如需完全对齐上游可设置 CLEAN=1 启用删除缺失项。
# 可在下方 USER_IGNORE_DIRS 配置要忽略的上游 pkg 子目录；即便项目引用到，也会被排除。
# 默认只同步项目实际引用到的子目录：扫描 cmd/ 与 internal/ 中的 import
# `github.com/onexstack/onexstack/pkg/<dir>`，只保留对应的顶层目录；若无引用则同步全部。
# 支持在同步前自动备份现有 pkg 目录（默认开启），避免误覆盖。

set -euo pipefail

REF="${1:-${ONEXSTACK_REF:-}}"
REPO_URL="${ONEXSTACK_REPO:-github.com/onexstack/onexstack}"
NEED_BACKUP="${BACKUP:-1}" # 设为 0 可跳过备份
CLEAN="${CLEAN:-0}"        # 设为 1 则对目标执行 delete，同步成上游精确镜像
USER_IGNORE_DIRS=(
  # 在此添加需要忽略的上游 pkg 子目录名，如 "flux" "examples"
  "flux",
  "polaris",
  "distlock",
  "cli"
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${REPO_ROOT}/pkg"

TMP_DIR="$(mktemp -d)"
ARCHIVE_PATH="${TMP_DIR}/onexstack.tar.gz"

cleanup() {
  chmod -R u+w "${TMP_DIR}" 2>/dev/null || true
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "缺少依赖: $1" >&2
    exit 1
  }
}

require_cmd go
require_cmd jq
require_cmd curl
require_cmd tar
require_cmd rsync

MODULE_PATH="$(awk '/^module /{print $2; exit}' "${REPO_ROOT}/go.mod")"

detect_ref() {
  # 优先使用 go list -m -json，兼容 replace 场景
  local ver
  ver="$(GO111MODULE=on go list -m -json github.com/onexstack/onexstack 2>/dev/null | jq -r '.Version // empty')"
  if [ -z "${ver}" ]; then
    # 回退：直接读取 go.mod require
    ver="$(awk '$1 == "github.com/onexstack/onexstack" {print $2; exit}' "${REPO_ROOT}/go.mod")"
  fi
  echo "${ver:-master}"
}

if [ -z "${REF}" ]; then
  REF="$(detect_ref)"
fi

echo ">>> 解析版本: ${REF}"

SRC_DIR=""
STAGE_DIR="${TMP_DIR}/pkg_stage"

download_with_go() {
  echo ">>> go mod download github.com/onexstack/onexstack@${REF}"
  local meta
  set +e
  meta="$(GO111MODULE=on go mod download -json github.com/onexstack/onexstack@${REF} 2>/dev/null)"
  local status=$?
  set -e
  if [ ${status} -eq 0 ] && [ -n "${meta}" ]; then
    local dir
    dir="$(echo "${meta}" | jq -r '.Dir // ""')"
    if [ -n "${dir}" ] && [ -d "${dir}/pkg" ]; then
      SRC_DIR="${dir}/pkg" # 仅取上游 pkg 子目录，避免整仓库
    fi
  fi
}

list_dirs() {
  # 兼容 macOS/BSD find
  find "$1" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;
}

collect_used_dirs() {
  # 从 cmd/ 与 internal/ 的 Go 源码中提取 onexstack/pkg/<dir> 的顶层目录名
  local dirs
  dirs="$(
    (
      set +e
      grep -Rho "github.com/onexstack/onexstack/pkg/[A-Za-z0-9_.-]*" \
        "${REPO_ROOT}/cmd" "${REPO_ROOT}/internal" 2>/dev/null
      # grep 无匹配返回 1，不应中断流程
      set -e
    ) | sed 's|.*github.com/onexstack/onexstack/pkg/||' |
      cut -d/ -f1 |
      sort -u
  )"
  echo "${dirs}"
}

in_list() {
  local needle="$1"; shift
  printf '%s\n' "$@" | grep -Fxq "${needle}"
}

download_with_archive() {
  local ref_type="heads"
  [[ "${REF}" =~ ^v?[0-9] ]] && ref_type="tags"
  local url="https://${REPO_URL}/archive/refs/${ref_type}/${REF}.tar.gz"
  echo ">>> 使用归档下载: ${url}"
  curl -L "${url}" -o "${ARCHIVE_PATH}"
  echo ">>> 解压归档..."
  tar -xzf "${ARCHIVE_PATH}" -C "${TMP_DIR}"
  SRC_DIR="$(find "${TMP_DIR}" -maxdepth 2 -type d -name 'pkg' | head -n 1)"
}

download_with_go

if [ -z "${SRC_DIR}" ] || [ ! -d "${SRC_DIR}" ]; then
  download_with_archive
fi

if [ -z "${SRC_DIR}" ] || [ ! -d "${SRC_DIR}" ]; then
  echo "未在下载源中找到 pkg 目录，请检查引用的分支/标签是否正确。" >&2
  exit 1
fi

echo ">>> 准备临时工作区，排除上游的 git/module 元数据"
mkdir -p "${STAGE_DIR}"
rsync -a --delete \
  --exclude='.gitignore' \
  --exclude='go.mod' \
  --exclude='go.sum' \
  --exclude='README*' \
  "${SRC_DIR}/" "${STAGE_DIR}/"
# 赋予可写权限，避免后续替换或清理时因上游只读权限失败
chmod -R u+w "${STAGE_DIR}" || true

echo ">>> 根据项目引用筛选需要同步的 pkg 子目录（默认扫描 cmd/ 与 internal/）"
ALL_DIRS="$(list_dirs "${STAGE_DIR}")"
USED_DIRS="$(collect_used_dirs)"
if [ -z "${USED_DIRS}" ]; then
  USED_DIRS="${ALL_DIRS}"
fi

# 应用忽略列表（容忍结尾逗号）
ALL_IGNORES="$(
  printf '%s\n' "${USER_IGNORE_DIRS[@]}" |
    sed 's/,$//' |        # 去掉行末逗号，兼容 "flux," 写法
    sed '/^[[:space:]]*$/d' |
    sort -u
)"

for dir in ${ALL_DIRS}; do
  if in_list "${dir}" ${ALL_IGNORES}; then
    echo "    忽略目录: ${dir}"
    rm -rf "${STAGE_DIR}/${dir}"
    continue
  fi

  if ! in_list "${dir}" ${USED_DIRS}; then
    echo "    项目未引用，跳过目录: ${dir}"
    rm -rf "${STAGE_DIR}/${dir}"
  fi
done

echo ">>> 清理文件头版权块（删除 package 之前的内容）"
find "${STAGE_DIR}" -name '*.go' -print0 | while IFS= read -r -d '' file; do
  # 移除文件开头到第一个 package 声明之间的所有内容
  perl -0777 -pi -e 's/\A.*?\n(package\s+)/$1/s' "$file"
done

if [ "${NEED_BACKUP}" -ne 0 ] && [ -d "${TARGET_DIR}" ]; then
  BACKUP_DIR="${REPO_ROOT}/.pkg.backup.$(date +%Y%m%d%H%M%S)" # 隐藏目录，避免 go list/tidy 扫描
  echo ">>> 备份现有 pkg 到 ${BACKUP_DIR}"
  cp -a "${TARGET_DIR}" "${BACKUP_DIR}"
fi

echo ">>> 同步到 ${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"
RSYNC_OPTS=(-a --ignore-existing) # 不覆盖本地已有文件
if [ "${CLEAN}" -eq 1 ]; then
  RSYNC_OPTS+=("--delete")
fi

# 检测潜在冲突（目标已存在同名文件）
echo ">>> 检查与本地的文件冲突（不会覆盖，需人工确认）"
CONFLICTS=()
while IFS= read -r -d '' file; do
  rel="${file#${STAGE_DIR}/}"
  if [ -e "${TARGET_DIR}/${rel}" ]; then
    CONFLICTS+=("${rel}")
  fi
done < <(find "${STAGE_DIR}" -type f -print0)

if [ ${#CONFLICTS[@]} -gt 0 ]; then
  echo "发现以下已存在的本地文件，将跳过覆盖："
  printf '  %s\n' "${CONFLICTS[@]}"
fi

rsync "${RSYNC_OPTS[@]}" "${STAGE_DIR}/" "${TARGET_DIR}/"

OLD_IMPORT="github.com/onexstack/onexstack/pkg"
NEW_IMPORT="${MODULE_PATH}/pkg"

echo ">>> 执行 import 路径替换: ${OLD_IMPORT} -> ${NEW_IMPORT}"
set +e
FILES_WITH_OLD_IMPORT="$(
  find "${REPO_ROOT}" \
    -path "${REPO_ROOT}/.git" -prune -o \
    -path "${REPO_ROOT}/vendor" -prune -o \
    -path "${REPO_ROOT}/pkg.backup.*" -prune -o \
    -path "${TMP_DIR}" -prune -o \
    \( -name '*.go' -o -name 'Makefile' \) -print \
    | xargs grep -l "${OLD_IMPORT}" 2>/dev/null
)"
set -e
if [ -n "${FILES_WITH_OLD_IMPORT}" ]; then
  echo "${FILES_WITH_OLD_IMPORT}" | xargs perl -pi -e "s|${OLD_IMPORT}|${NEW_IMPORT}|g"
else
  echo "未发现需要替换的 import 路径。"
fi

echo ">>> 完成。同名环境变量:"
echo "    ONEXSTACK_REF=<分支|标签> 选择版本 (默认 master)"
echo "    ONEXSTACK_REPO=<repo url>  自定义远程仓库"
echo "    BACKUP=0                  关闭备份"
echo "    CLEAN=1                   对齐上游并删除本地缺失项"

