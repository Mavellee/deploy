#!/bin/sh
# Applies migrations and reference-data seeding on every boot (both are idempotent/upsert-based,
# matching what deploy.sh already does), then runs the API and Caddy side by side in one container.
set -e

echo "==> Applying migrations"
npx prisma migrate deploy

echo "==> Seeding reference data"
npx tsx prisma/seed.ts

echo "==> Starting API on :4000"
PORT=4000 node dist/index.js &

echo "==> Starting Caddy on :10000"
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
