#!/bin/bash
set -e

cd /home/container || exit 1

BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# Ensure downloader exists
if [ ! -f hytale-downloader ]; then
  echo -e "${YELLOW}Hytale downloader not found. Downloading...${NC}"

  curl -L -o hytale-downloader.zip https://downloader.hytale.com/hytale-downloader.zip
  unzip -o hytale-downloader.zip

  mv hytale-downloader-linux-amd64 hytale-downloader
  chmod +x hytale-downloader

  rm -f hytale-downloader-windows-amd64.exe
  rm -f QUICKSTART.md
  rm -f hytale-downloader.zip

  echo -e "${GREEN}Downloader installed.${NC}"
  echo
fi

# First run: download server + assets
if [ ! -f HytaleServer.jar ]; then
  echo -e "${YELLOW}Hytale server files not found.${NC}"
  echo -e "${GREEN}Authentication required to download server files.${NC}"
  echo
  echo -e "${BLUE}When prompted below:${NC}"
  echo -e "  • Open the URL shown"
  echo -e "  • Enter the device code"
  echo -e "  • Complete login in your browser"
  echo
  echo -e "${RED}Do NOT restart the server during authentication.${NC}"
  echo

  ./hytale-downloader --skip-update-check || true

  echo
  echo -e "${YELLOW}Waiting for authentication to complete...${NC}"

  while [ ! -f HytaleServer.jar ]; do
    echo -e "${BLUE}Still waiting for OAuth login...${NC}"
    sleep 5
  done

  echo -e "${GREEN}Authentication successful. Server files downloaded.${NC}"
  echo
fi

# Final sanity check
if [ ! -f HytaleServer.jar ]; then
  echo -e "${RED}ERROR: Server files missing after authentication.${NC}"
  exit 1
fi

echo -e "${GREEN}Starting Hytale server...${NC}"
echo

exec java -Xms128M -Xmx${SERVER_MEMORY}M -jar HytaleServer.jar --assets assets.zip