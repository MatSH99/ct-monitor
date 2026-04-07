#!/bin/bash
# scripts/run_preloaders.sh

SHARED_DIR="/shared"
LOGS_FILE="$SHARED_DIR/usable_logs.txt"
TESSERA_BASE_NAME="test-static-ct"

while [ ! -f "$SHARED_DIR/setup_done" ]; do
    echo "Waiting for setup..."
    sleep 5
done

echo "Booting Preloader..."
while read -r URL; do
    CLEAN_URL="$(echo $URL | sed 's/\/$//')"
    LOG_NAME=$(echo $CLEAN_URL | sed 's/\//_/g')

    STH=$(curl -s -L --max-time 5 "${CLEAN_URL}/ct/v1/get-sth")
    CURRENT_SIZE=$(echo "$STH" | jq -r '.tree_size' 2>/dev/null)

    if [[ -z "$CURRENT_SIZE" || "$CURRENT_SIZE" == "null" ]]; then
        STH_FILE=$(curl -s -L --max-time 5 "${API_URL}/checkpoint")
        CURRENT_SIZE=$(echo "$STH_FILE" | sed -n '2p' | tr -d '\r' | xargs)
    fi

ww    echo ">>> Syncing $CLEAN_URL from index $CURRENT_SIZE"

    /usr/local/bin/preloader_bin \
      --source_log_uri="$API_URL" \
      --target_log_uri="http://localhost:6962/${TESSERA_BASE_NAME}" \
      --start_index="$CURRENT_SIZE" \
      --num_workers=32 \
      --batch_size=1000 \
      --parallel_submit=16 \
      --parallel_fetch=4
      --continuous=true &
done < $LOGS_FILE

# Keeps container on
wait
