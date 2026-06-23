# Karkonoska Ostoja Leads Collector API

Rails API-only backend for collecting accommodation leads from Facebook groups, checking BedBooking iCal availability, and sending Telegram notifications.

## Requirements

- Ruby 3.4+
- PostgreSQL 16+
- Docker (optional)

## Environment variables

Copy `.env.example` to `.env` and set:

- `API_KEY` – shared secret for API authentication
- `TELEGRAM_BOT_TOKEN` – Telegram bot token
- `TELEGRAM_CHAT_ID` – target chat ID for notifications
- `BEDBOOKING_ICAL_URL` – BedBooking iCal feed URL
- `DATABASE_URL` – PostgreSQL connection URL (required in production; optional locally when using Docker Compose)

## Setup

```bash
bundle install
bin/rails db:create db:migrate
```

With Docker:

```bash
docker-compose up --build
```

## API

All endpoints require header:

```
X-API-Key: <API_KEY>
```

### Health check

```
GET /api/health
```

### Create lead

```
POST /api/leads
Content-Type: application/json
```

Optional fields: `date_from`, `date_to` (ISO 8601 date strings, e.g. `"2026-07-07"`). When both are provided, iCal availability is checked before notifying. When omitted, the lead is still saved and notified without an availability check.

Example:

```bash
curl -X POST http://localhost:3000/api/leads \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  -d '{
    "source": "facebook",
    "group_name": "Noclegi Karkonosze",
    "post_url": "https://facebook.com/...",
    "post_text": "Szukam noclegu dla 2+2 w Szklarskiej Porębie",
    "posted_at": "2026-06-23T10:30:00+02:00",
    "date_from": "2026-07-07",
    "date_to": "2026-07-10"
  }'
```

## Tests

```bash
bundle exec rspec
```

With Docker:

```bash
docker-compose run --rm test rspec
```

RuboCop:

```bash
docker-compose run --rm test rubocop -a
```

## Production (Railway)

Railway auto-detects [`railway.json`](railway.json) and runs `./bin/railway-deploy` on deploy (waits for DB, runs `db:prepare`, starts Puma on `$PORT`).

Set these environment variables in Railway:

- `RAILS_ENV=production`
- `RAILS_MASTER_KEY`
- `DATABASE_URL` (usually auto-set when Postgres is linked)
- `API_KEY`
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`
- `BEDBOOKING_ICAL_URL`

Health checks after deploy:

```bash
curl https://leadscollector-production.up.railway.app/up
curl -H "X-API-Key: $API_KEY" https://leadscollector-production.up.railway.app/api/health
```

- `GET /up` — Rails built-in health check (no auth)
- `GET /api/health` — app health check (requires `X-API-Key`)
