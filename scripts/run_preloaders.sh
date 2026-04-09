#!/bin/bash
# scripts/run_preloaders.sh

SHARED_DIR="/shared"
LOGS_FILE="$SHARED_DIR/usable_logs.txt"
TESSERA_BASE_NAME="test-static-ct"

USER_ARGS="$@"

get_flag_value() {
    echo "$USER_ARGS" | grep -oP "(?<=--$1=)[^ ]+"
}

OVERRIDE_START=$(get_flag_value "start_index")

while [ ! -f "$SHARED_DIR/setup_done" ]; do
    echo "Waiting for setup..."
    sleep 5
done

echo "Booting Preloader..."
while read -r URL; do
    CLEAN_URL="$(echo $URL | sed 's/\/$//')"
    API_URL=$(echo "$CLEAN_URL" | sed 's/log\./mon\./' | sed 's/sun/sky/')
    LOG_NAME=$(echo $CLEAN_URL | sed 's/\//_/g')

    if [ ! -z "$OVERRIDE_START" ]; then
      CURRENT_START=$OVERRIDE_START
    else

      STH=$(curl -s -L --max-time 5 "${API_URL}/ct/v1/get-sth")
      CURRENT_START=$(echo "$STH" | jq -r '.tree_size' 2>/dev/null)

      if [[ -z "$CURRENT_START" || "$CURRENT_START" == "null" ]]; then
          STH_FILE=$(curl -s -L --max-time 5 "${API_URL}/checkpoint")
          CURRENT_START=$(echo "$STH_FILE" | sed -n '2p' | tr -d '\r' | xargs)
      fi
    fi
    echo ">>> Syncing $CLEAN_URL from index $CURRENT_START"

    CLEAN_ARGS=$(echo "$USER_ARGS" | sed 's/--start_index=[^ ]*//g')

    /usr/local/bin/preloader_bin \
      --source_log_uri="$API_URL" \
      --target_log_uri="http://localhost:6962/${TESSERA_BASE_NAME}" \
      --start_index="$CURRENT_START" \
      $CLEAN_ARGS &
done < $LOGS_FILE

# Keeps container on
wait
