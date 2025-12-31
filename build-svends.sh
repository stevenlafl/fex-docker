#!/bin/bash
set -e

cd "$(dirname "$0")"

# Ensure steamcmd image exists
if ! docker image inspect stevenlafl/fex:steamcmd >/dev/null 2>&1; then
    echo "steamcmd image not found. Building it first..."
    ./build-steamcmd.sh
fi

echo "Starting steamcmd container..."
docker compose -f games/steamcmd/docker-compose.yml up -d

echo "Downloading Sven Co-op Dedicated Server (appid 276060)..."
docker compose -f games/steamcmd/docker-compose.yml exec -T fex bash -c '
  FEX ./linux32/steamcmd +login anonymous +app_update 276060 validate +quit
  cd /home/fex/Steam/steamapps/common
  tar czvf /tmp/svends.tar.gz "Sven Co-op Dedicated Server"
  mv /tmp/svends.tar.gz /home/fex/Steam/
'

echo "Stopping steamcmd container..."
docker compose -f games/steamcmd/docker-compose.yml down

echo "Copying svends.tar.gz to games/svends/..."
cp Steam/svends.tar.gz games/svends/

echo "Building svends image..."
cd games/svends
docker compose build

echo "Done! Image stevenlafl/fex:svends is ready."
