#!/usr/bin/env bash
# Restores a backup created by backup.sh. This REPLACES the current database contents.
# Usage: deploy/restore.sh deploy/backups/knot-YYYYMMDDTHHMMSSZ.dump
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f "${1:-}" ] || { echo "Usage: $0 <backup.dump>"; exit 1; }
set -a; source deploy/.env.production; set +a
read -r -p "This will overwrite database '$POSTGRES_DB'. Type the database name to continue: " CONFIRM
[ "$CONFIRM" = "$POSTGRES_DB" ] || { echo "Aborted."; exit 1; }
COMPOSE="docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env.production"
$COMPOSE stop api
$COMPOSE exec -T postgres pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --no-owner < "$1"
$COMPOSE start api
echo "Restore complete."
