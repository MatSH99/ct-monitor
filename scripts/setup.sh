#!/bin/bash
# scripts/setup.sh

LOG_LIST_URL="https://www.gstatic.com/ct/log_list/v3/log_list.json"
SHARED_DIR="/shared"
ROOTS_FILE="$SHARED_DIR/combined_roots.pem"
LOGS_FILE="$SHARED_DIR/usable_logs.txt"

echo "[1/2] Retrieving logs URLs..."
curl -s $LOG_LIST_URL | jq -r '.. | objects | select(.state.usable?) | (.url // .submission_url)' > $LOGS_FILE

echo "[2/2] Generating roots file..."
rm -f $ROOTS_FILE && touch $ROOTS_FILE

while read -r URL; do
    URL=$(echo $URL | tr -d '\r\n' | xargs)
    CLEAN_URL="${URL%/}"
    echo "Processing: $CLEAN_URL"

    # Tua logica originale di recupero root
    JSON_ROOTS=$(curl -s -L -H "Accept: application/json" -A "Mozilla/5.0" "${CLEAN_URL}/ct/v1/get-roots")
    
    if [[ "$JSON_ROOTS" != *"certificates"* ]]; then
        API_URL=$(echo "$CLEAN_URL" | sed 's/log\./mon\./' | sed 's/sun/sky/')
        JSON_ROOTS=$(curl -s -L -A "Mozilla/5.0" "${API_URL}/ct/v1/get-roots")
    fi

    if [[ "$JSON_ROOTS" == *"certificates"* ]]; then
        CERTS=$(echo "$JSON_ROOTS" | jq -r '.certificates[]?' 2>/dev/null)
        if [ -n "$CERTS" ]; then
            COUNT=0
            for cert in $CERTS; do
            if [[ ${#cert} -gt 50 ]]; then
                echo "-----BEGIN CERTIFICATE-----" >> "$ROOTS_FILE"
                echo "$cert" | fold -w 64 >> "$ROOTS_FILE"
                echo "-----END CERTIFICATE-----" >> "$ROOTS_FILE"
                ((COUNT++))
            fi
            done
            echo "  -> OK"
        fi
    fi
done < $LOGS_FILE

# Segnale di fine per gli altri container
touch "$SHARED_DIR/setup_done"
echo "Setup done."
