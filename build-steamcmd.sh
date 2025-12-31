#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Starting FEX container..."
docker compose up -d

echo "Downloading and updating SteamCMD..."
docker compose exec -T fex bash << 'EOFSCRIPT'
  cd /home/fex
  curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
  # Run steamcmd.sh to update
  FEX ./steamcmd.sh +quit
  tar czvf /tmp/steamcmd.tar.gz linux32/ linux64/ package/ public/ siteserverui/ steamcmd.sh
  mv /tmp/steamcmd.tar.gz /home/fex/Steam/
EOFSCRIPT

echo "Stopping FEX container..."
docker compose down

echo "Copying steamcmd.tar.gz to games/steamcmd/..."
cp Steam/steamcmd.tar.gz games/steamcmd/

echo "Building steamcmd image..."
cd games/steamcmd
docker compose build

echo "Done! Image stevenlafl/fex:steamcmd is ready."
