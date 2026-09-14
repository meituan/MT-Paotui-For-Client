#!/usr/bin/env bash
# QR code generator — PNG image output
# Usage: bash qrcode-image.sh "<url>" "<client_id>"
# Output on success: QRCODE_IMAGE:<png_file_path>
# Output on failure: QRCODE_SKIP
set -euo pipefail

URL="${1:-}"
CLIENT_ID="${2:-}"

if [ -z "$URL" ]; then
  echo "QRCODE_SKIP"
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
RAND_FILE=0
if [ -n "$CLIENT_ID" ]; then
  IMGFILE="$SCRIPT_DIR/qrcode_${CLIENT_ID}.png"
else
  RAND=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom 2>/dev/null | head -c8; true)
  IMGFILE="$SCRIPT_DIR/qrcode_${RAND}.png"
  RAND_FILE=1
fi

cleanup() {
  if [ "$RAND_FILE" = "1" ]; then
    rm -f "$IMGFILE"
  fi
}
trap cleanup EXIT

if ! command -v node &>/dev/null; then
  echo "QRCODE_SKIP"
  exit 0
fi

NODE_GLOBAL_MODULES=""
if command -v npm &>/dev/null; then
  NODE_GLOBAL_MODULES="$(npm root -g 2>/dev/null)"
fi

if [ -z "$NODE_GLOBAL_MODULES" ]; then
  echo "QRCODE_SKIP"
  exit 0
fi

if ! NODE_PATH="$NODE_GLOBAL_MODULES" node -e "require('qrcode')" 2>/dev/null; then
  echo "[qrcode-image.sh] qrcode 模块未安装，正在自动安装..." >&2
  if ! npm install -g qrcode 2>&1 >&2; then
    echo "QRCODE_SKIP"
    exit 0
  fi
  NODE_GLOBAL_MODULES="$(npm root -g 2>/dev/null)"
  if ! NODE_PATH="$NODE_GLOBAL_MODULES" node -e "require('qrcode')" 2>/dev/null; then
    echo "QRCODE_SKIP"
    exit 0
  fi
fi

RESULT=$(NODE_PATH="$NODE_GLOBAL_MODULES" node -e "
const qr = require('qrcode');
const file = process.argv[1];
const url = process.argv[2];
qr.toFile(file, url, {
  type: 'png',
  width: 300,
  margin: 2,
  errorCorrectionLevel: 'M'
}, (err) => {
  if (!err) { process.stdout.write('QRCODE_IMAGE:' + file); }
  else { process.stdout.write('QRCODE_SKIP'); }
});
" -- "$IMGFILE" "$URL" 2>/dev/null)

echo "$RESULT"
