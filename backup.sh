#!/usr/bin/env bash
# Backs up the database AND the uploads volume (photos, videos, posters, chat images) with one timestamp.
# A database restored without its media would point at files that no longer exist.
# Keeps the 14 most recent pairs. Copy deploy/backups off the instance (object storage) — see docs/DEPLOYMENT.md.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source deploy/.env.production; set +a
COMPOSE="docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env.production"
mkdir -p deploy/backups
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
DB="deploy/backups/knot-$STAMP.dump"
MEDIA="deploy/backups/knot-$STAMP-uploads.tar.gz"

$COMPOSE exec -T postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom --compress=9 > "$DB"
# Media is archived after the dump, so every file the dump references already exists in the archive
# (uploads only ever add new random names; deletions are the only way a file disappears).
$COMPOSE exec -T api tar -C /data -czf - uploads > "$MEDIA"
[ -s "$DB" ] && [ -s "$MEDIA" ] || { echo "Backup failed: empty output" >&2; exit 1; }
echo "Backup written: $DB and $MEDIA"

ls -1t deploy/backups/knot-*.dump | tail -n +15 | xargs -r rm --
ls -1t deploy/backups/knot-*-uploads.tar.gz 2>/dev/null | tail -n +15 | xargs -r rm --
