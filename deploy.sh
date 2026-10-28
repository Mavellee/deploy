#!/usr/bin/env bash
# Controlled deployment: back up, build, migrate, then switch traffic. Run on the server from the repo root.
set -euo pipefail
cd "$(dirname "$0")/.."
COMPOSE="docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env.production"

echo "==> Building images"
$COMPOSE build

echo "==> Starting database"
$COMPOSE up -d --wait postgres

echo "==> Backing up database before migrating"
./deploy/backup.sh

echo "==> Applying migrations (non-destructive; review new migrations before deploying)"
$COMPOSE run --rm --no-deps api npx prisma migrate deploy

echo "==> Loading reference data (interests, questions, games; skips dev members in production)"
$COMPOSE run --rm --no-deps api npx tsx prisma/seed.ts

echo "==> Starting services"
$COMPOSE up -d api web

echo "==> Waiting for health check"
for i in $(seq 1 30); do
  if $COMPOSE exec -T api node -e "fetch('http://127.0.0.1:4000/readyz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"; then
    echo "API is healthy."; exit 0
  fi
  sleep 2
done
echo "API did not become healthy. Check: $COMPOSE logs api" >&2
exit 1
