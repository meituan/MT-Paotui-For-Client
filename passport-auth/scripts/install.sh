#!/usr/bin/env bash
# pt-passport CLI install/update script
# Installs from local tgz bundle. Skips if installed version == bundle version.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"

if ! command -v npm &>/dev/null; then
  echo "npm: command not found. Please install Node.js >=18" >&2
  exit 2
fi

# 找到 scripts 目录下的本地安装包（取版本最新的一个）
TGZ_FILE=$(for f in "$SCRIPT_DIR"/mtuser-pt-passport-*.tgz; do [ -f "$f" ] && echo "$f"; done | sort -V | tail -1)
if [ -z "$TGZ_FILE" ]; then
  echo "No local tgz bundle found in $SCRIPT_DIR" >&2
  exit 3
fi

# 从文件名中提取版本号，如 mtuser-pt-passport-0.1.0.tgz -> 0.1.0
BUNDLE_VERSION=$(basename "$TGZ_FILE" | sed 's/mtuser-pt-passport-//;s/\.tgz$//')
if [ -z "$BUNDLE_VERSION" ]; then
  echo "Failed to parse version from bundle filename: $(basename "$TGZ_FILE")" >&2
  exit 3
fi

# 获取已安装版本（直接用 pt-passport --version，取最后一行以跳过 CLIGuard Wrapper 前缀行）
LOCAL=$(pt-passport --version 2>/dev/null | tail -1 || true)

# 版本一致则跳过
if [ "$LOCAL" = "$BUNDLE_VERSION" ]; then
  echo "Already up-to-date (pt-passport@$LOCAL), skipping."
  exit 0
fi

# 安装本地包
echo "Installing pt-passport@$BUNDLE_VERSION from local bundle..."
npm install -g "$TGZ_FILE" --save-exact --force || {
  echo "Install failed." >&2; exit 1
}
