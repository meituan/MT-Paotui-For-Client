#!/bin/sh
# 美团跑腿下单工具启动脚本（混淆打包版）
# 用法：sh dist/run.sh <command> [args...]
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export CLIGUARD_JS_PATH="$SCRIPT_DIR/vendor/cliguard/js/cliguard.js"
cd "$SCRIPT_DIR"
exec node "$SCRIPT_DIR/paotui.js" "$@"
