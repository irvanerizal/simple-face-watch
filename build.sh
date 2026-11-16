#!/usr/bin/env bash
# Build watch face untuk satu device.
# Pemakaian: ./build.sh [device]
# Contoh:    ./build.sh fr265
set -euo pipefail

DEVICE="${1:-fr265}"
OUT_DIR="bin"
PRG="$OUT_DIR/MinimalLines-$DEVICE.prg"

# 1) Cari compiler monkeyc.
if [[ -n "${CONNECTIQ_SDK:-}" ]]; then
    MONKEYC="$CONNECTIQ_SDK/bin/monkeyc"
elif command -v monkeyc >/dev/null 2>&1; then
    MONKEYC="$(command -v monkeyc)"          # install via Homebrew: brew install --cask connectiq
else
    SDK="$(ls -d "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks"/*/ 2>/dev/null | sort -V | tail -1 || true)"
    MONKEYC="${SDK%/}/bin/monkeyc"
fi

if [[ ! -x "$MONKEYC" ]]; then
    echo "ERROR: monkeyc tidak ditemukan." >&2
    echo "Install via Homebrew:  brew install --cask connectiq --appdir=\"\$HOME/Applications\"" >&2
    echo "atau set CONNECTIQ_SDK ke folder SDK Connect IQ." >&2
    exit 1
fi

# 2) Java — wajib untuk monkeyc. Homebrew openjdk bersifat keg-only,
#    jadi set JAVA_HOME kalau belum ada java yang terdeteksi.
if [[ -z "${JAVA_HOME:-}" ]] && [[ -d /opt/homebrew/opt/openjdk ]]; then
    export JAVA_HOME=/opt/homebrew/opt/openjdk
    export PATH="$JAVA_HOME/bin:$PATH"
fi
if ! command -v java >/dev/null 2>&1 && [[ -z "${JAVA_HOME:-}" ]]; then
    echo "ERROR: Java tidak ditemukan. Install: brew install openjdk" >&2
    exit 1
fi

# 3) Developer key (sekali saja).
KEY="${CONNECTIQ_KEY:-$PWD/developer_key.der}"
if [[ ! -f "$KEY" ]]; then
    echo "==> Membuat developer key baru (pertama kali saja)..."
    openssl genrsa -out developer_key.pem 4096
    openssl pkcs8 -topk8 -inform PEM -outform DER \
        -in developer_key.pem -out developer_key.der -nocrypt
    KEY="$PWD/developer_key.der"
fi

# 4) Build.
mkdir -p "$OUT_DIR"
echo "==> Building untuk device: $DEVICE"
"$MONKEYC" -f monkey.jungle -d "$DEVICE" -o "$PRG" -y "$KEY" -w

echo
echo "OK: $PRG"
echo "Jalankan di simulator (pastikan device support sudah di-download via SdkManager.app):"
echo "  monkeydo \"$PRG\" $DEVICE"
