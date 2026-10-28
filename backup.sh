#!/usr/bin/env bash
# Writes a compressed logical backup to deploy/backups and keeps the newest 14.
# Schedule daily with cron, e.g.: 30 2 * * * /home/ubuntu/knot/deploy/backup.sh >> /var/log/knot-backup.log 2>&1
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source deploy/.env.production; set +a
mkdir -p deploy/backups
FILE="knot-$(date -u +%Y%m%dT%H%M%SZ).dump"
docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env.production exec -T postgres \
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom --compress=9 > "deploy/backups/$FILE"
echo "Backup written: deploy/backups/$FILE"
ls -1t deploy/backups/knot-*.dump | tail -n +15 | xargs -r rm --
# Optional off-site copy (recommended): aws s3 cp "deploy/backups/$FILE" "s3://YOUR-BUCKET/knot/$FILE"
