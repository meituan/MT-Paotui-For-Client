#!/bin/sh
# 美团跑腿下单工具启动脚本（技术开放平台版 - 混淆打包版）
# 用法：sh dist/run.sh <command> [args...]
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec node "$SCRIPT_DIR/paotui.js" "$@"
