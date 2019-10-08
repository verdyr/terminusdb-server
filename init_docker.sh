#!/bin/sh
SERVER_NAME=${SERVER_NAME:-localhost}
ADMIN_PASS=${ADMIN_PASS:-root}
SERVER_PORT=${SERVER_PORT:-6363}
WORKERS=${WORKERS:-8}
if [ ! -f /app/terminusdb/storage/prefix.db ]; then
    /app/terminusdb/utils/initialize_database -s "$SERVER_NAME" -k "$ADMIN_PASS" --port "$SERVER_PORT" --workers "$WORKERS"
fi
/app/terminusdb/start.pl
