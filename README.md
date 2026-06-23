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

Example:

```bash
curl -X POST http://localhost:3000/api/leads \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  -d '{
    "source": "facebook",
    "group_name": "Noclegi Karkonosze",
    "post_url": "https://facebook.com/...",
    "post_text": "Szukam noclegu dla 2+2 od 15 do 18 sierpnia w Szklarskiej Porębie",
    "posted_at": "2026-06-23T10:30:00+02:00"
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

Set `DATABASE_URL` in Railway environment variables. Rails uses it for the primary database as well as Solid Cache, Solid Queue, and Solid Cable (all share the same PostgreSQL instance).

Run migrations on deploy:

```bash
bundle exec rails db:prepare
```
