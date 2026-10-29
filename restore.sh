#!/usr/bin/env bash
# Restores a backup created by backup.sh. This REPLACES the current database contents, and restores the
# matching uploads archive (photos, videos, posters, chat images) when one exists next to the dump.
# Usage: deploy/restore.sh deploy/backups/knot-YYYYMMDDTHHMMSSZ.dump
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f "${1:-}" ] || { echo "Usage: $0 <backup.dump>"; exit 1; }
MEDIA="${1%.dump}-uploads.tar.gz"
set -a; source deploy/.env.production; set +a
if [ -f "$MEDIA" ]; then echo "Will also restore media from $MEDIA"; else echo "WARNING: no media archive found ($MEDIA). Only the database will be restored."; fi
read -r -p "This will overwrite database '$POSTGRES_DB'. Type the database name to continue: " CONFIRM
[ "$CONFIRM" = "$POSTGRES_DB" ] || { echo "Aborted."; exit 1; }
COMPOSE="docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env.production"
$COMPOSE stop api
$COMPOSE exec -T postgres pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --no-owner < "$1"
if [ -f "$MEDIA" ]; then
  # Extracts into the uploads volume with the API stopped; files are written as the API's user.
  $COMPOSE run --rm --no-deps -T --entrypoint sh api -c 'tar -C /data -xzf -' < "$MEDIA"
fi
$COMPOSE start api
echo "Restore complete."
