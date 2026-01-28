#!/usr/bin/env bash
set -euo pipefail

cd /home/container

echo "Hytale Server Startup Script"
echo "-----------------------------"

# ==============================
# Environment defaults
# ==============================
SERVER_PORT="${SERVER_PORT:-5520}"
AUTH_MODE="${AUTH_MODE:-authenticated}"
ASSETS_PATH="${ASSETS_PATH:-Assets.zip}"

ACCEPT_EARLY_PLUGINS="${ACCEPT_EARLY_PLUGINS:-0}"
ALLOW_OP="${ALLOW_OP:-0}"
ENABLE_BACKUPS="${ENABLE_BACKUPS:-0}"
BACKUP_DIR="${BACKUP_DIR:-backups}"
BACKUP_FREQUENCY="${BACKUP_FREQUENCY:-60}"

# ==============================
# Resolve toggle flags (0/1)
# ==============================
EARLY_PLUGINS_FLAG=""
ALLOW_OP_FLAG=""
BACKUPS_FLAGS=""

if [[ "${ACCEPT_EARLY_PLUGINS}" == "1" ]]; then
  EARLY_PLUGINS_FLAG="--accept-early-plugins"
fi

if [[ "${ALLOW_OP}" == "1" ]]; then
  ALLOW_OP_FLAG="--allow-op"
fi

if [[ "${ENABLE_BACKUPS}" == "1" ]]; then
  BACKUPS_FLAGS="--backup --backup-dir ${BACKUP_DIR} --backup-frequency ${BACKUP_FREQUENCY}"
fi

# ==============================
# Show downloader version & update
# ==============================
/node/bin/node /main.js

# ==============================
# Locate assets ZIP
# ==============================
if [[ ! -f "${ASSETS_PATH}" ]]; then
  echo "Assets not found, locating latest patchline..."
  ASSETS_PATH="$(ls -1 *.zip | head -n 1 || true)"
fi

if [[ ! -f "${ASSETS_PATH}" ]]; then
  echo "ERROR: Assets ZIP not found."
  exit 1
fi

echo "Using assets: ${ASSETS_PATH}"

# ==============================
# Ensure server jar exists
# ==============================
if [[ ! -f "./Server/HytaleServer.jar" ]]; then
  echo "Extracting server files..."
  unzip -qo "${ASSETS_PATH}" -d .
fi

if [[ ! -f "./Server/HytaleServer.jar" ]]; then
  echo "ERROR: HytaleServer.jar not found after extraction."
  exit 1
fi

# ==============================
# Start the server
# ==============================
echo "Starting Hytale server..."

exec java \
  -Xms128M \
  -XX:MaxRAMPercentage=95.0 \
  -Dterminal.jline=false \
  -Dterminal.ansi=true \
  -jar ./Server/HytaleServer.jar \
  --assets "${ASSETS_PATH}" \
  --auth-mode "${AUTH_MODE}" \
  --bind "0.0.0.0:${SERVER_PORT}" \
  ${EARLY_PLUGINS_FLAG} \
  ${ALLOW_OP_FLAG} \
  ${BACKUPS_FLAGS} \
  --transport QUIC
