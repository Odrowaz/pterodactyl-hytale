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

if [[ ! -f "./Server/HytaleServer.jar" ]]; then
  echo "Downloading server files..."
  /node/bin/node /main.js
fi


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

while true; do
    APPLIED_UPDATE=false

    # Apply staged update if present
    if [ -f "updater/staging/Server/HytaleServer.jar" ]; then
        echo "[Launcher] Applying staged update..."
        # Only replace update files, preserve config/saves/mods
        cp -f updater/staging/Server/HytaleServer.jar Server/
        #[ -f "updater/staging/Server/HytaleServer.aot" ] && cp -f updater/staging/Server/HytaleServer.aot Server/
        [ -d "updater/staging/Server/Licenses" ] && rm -rf Server/Licenses && cp -r updater/staging/Server/Licenses Server/
        [ -f "updater/staging/Assets.zip" ] && cp -f updater/staging/Assets.zip ./
        [ -f "updater/staging/start.sh" ] && cp -f updater/staging/start.sh ./
        [ -f "updater/staging/start.bat" ] && cp -f updater/staging/start.bat ./
        rm -rf updater/staging
        APPLIED_UPDATE=true
    fi

    # Run server from inside Server/ folder so config/backups/etc. are generated there
    cd Server

    # JVM arguments for AOT cache (faster startup)
    JVM_ARGS=""
    if [ -f "HytaleServer.aot" ]; then
        echo "[Launcher] Using AOT cache for faster startup"
        JVM_ARGS="-XX:AOTCache=HytaleServer.aot"
    fi

    if [ ! -f "HytaleServer.aot" ]; then
        echo "[Launcher] Using AOT cache for faster startup"
        JVM_ARGS="-XX:AOTCacheOutput=HytaleServer.aot"
    fi

    # Start server and track time
    START_TIME=$(date +%s)

    java \
    -Xms128M \
    -XX:MaxRAMPercentage=95.0 \
    -Dterminal.jline=false \
    -Dterminal.ansi=true \
    $JVM_ARGS \
    -jar HytaleServer.jar \
    --disable-sentry \
    --assets "../Assets.zip" \
    --auth-mode "${AUTH_MODE}" \
    --bind "0.0.0.0:${SERVER_PORT}" \
    ${EARLY_PLUGINS_FLAG} \
    ${ALLOW_OP_FLAG} \
    ${BACKUPS_FLAGS} \
    --transport QUIC \
    "$@"

    EXIT_CODE=$?
    ELAPSED=$(( $(date +%s) - START_TIME ))

    # Return to script dir for next iteration
    cd "$SCRIPT_DIR"

    # Exit code 8 = restart for update
    if [ $EXIT_CODE -eq 8 ]; then
        echo "[Launcher] Restarting to apply update..."
        continue
    fi

    # Warn on crash shortly after update
    if [ $EXIT_CODE -ne 0 ] && [ "$APPLIED_UPDATE" = true ] && [ $ELAPSED -lt 30 ]; then
        echo ""
        echo "[Launcher] ERROR: Server exited with code $EXIT_CODE within ${ELAPSED}s of starting."
        echo "[Launcher] This may indicate the update failed to start correctly."
        echo "[Launcher]"
        echo "[Launcher] Your previous files are in the updater/backup/ folder."
        echo "[Launcher] To rollback: delete Server/ and Assets.zip, then move from updater/backup/"
        echo ""
        # Only prompt if running interactively (has terminal)
        if [ -t 0 ]; then
            read -p "Press Enter to exit..."
        fi
    fi

    exit $EXIT_CODE
done
