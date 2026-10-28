# vSphere Auditor

A lightweight VMware vSphere audit tool built with Rails. Collects events from vCenter, stores them in PostgreSQL, and provides a web UI and email reports for change tracking and compliance — a self-hosted alternative to Netwrix Auditor for VMware.

## Features

- **Event Collection** — Polls vCenter EventManager every 5 minutes via rbvmomi, with deduplication
- **Smart Categorization** — Classifies events into categories (VM lifecycle, power, config, snapshots, sessions, permissions, host, folder, datastore) including TaskEvent message parsing
- **Web Dashboard** — Summary stats, recent warnings, activity breakdowns by category and user
- **Event Browser** — Filterable and paginated event list with detail view
- **CSV Export** — Export filtered events for audits and reporting
- **Email Reports** — Daily HTML and plain text audit report emails
- **Data Retention** — Automatic monthly purge of events older than a configurable threshold
- **Basic Auth** — Optional HTTP basic authentication

## Requirements

- Ruby 3.4+
- PostgreSQL 14+
- A VMware vCenter Server (tested with vCenter 7.x and 8.x)

## Setup

### 1. Clone and install dependencies

```bash
git clone https://github.com/chris1984/vsphere-auditor.git
cd vsphere-auditor
bundle install
```

### 2. Set up PostgreSQL

Create the database user and databases:

```bash
sudo -u postgres createuser --createdb vsphere_auditor
sudo -u postgres psql -c "CREATE DATABASE vsphere_auditor_development OWNER vsphere_auditor ENCODING 'UTF8' TEMPLATE template0;"
sudo -u postgres psql -c "CREATE DATABASE vsphere_auditor_test OWNER vsphere_auditor ENCODING 'UTF8' TEMPLATE template0;"
```

### 3. Configure environment

```bash
cp .env.example .env
```

Edit `.env` with your settings:

| Variable | Description | Required |
|---|---|---|
| `VCENTER_HOST` | vCenter hostname or IP | Yes |
| `VCENTER_USER` | vCenter username | Yes |
| `VCENTER_PASSWORD` | vCenter password | Yes |
| `VCENTER_INSECURE` | Allow self-signed certs (`true`/`false`) | No (default: `true`) |
| `DATABASE_HOST` | PostgreSQL host | No (default: `localhost`) |
| `DATABASE_USERNAME` | PostgreSQL username | No (default: `vsphere_auditor`) |
| `DATABASE_PASSWORD` | PostgreSQL password | No (default: empty) |
| `REPORT_FROM_EMAIL` | Sender address for reports | No |
| `REPORT_RECIPIENTS` | Comma-separated recipient addresses | No |
| `AUTH_USERNAME` | HTTP basic auth username | No (auth disabled if blank) |
| `AUTH_PASSWORD` | HTTP basic auth password | No (auth disabled if blank) |
| `RETENTION_MONTHS` | Months of events to keep | No (default: `12`) |

### 4. Run migrations

```bash
bin/rails db:migrate
```

### 5. Start the app

```bash
bin/dev
```

This starts both Puma (web server) and Solid Queue (background jobs). Browse to `http://localhost:3000`.

## Usage

### Manual operations

```bash
# Collect events from vCenter now
rake vcenter:collect

# Re-categorize existing events (after updating classification rules)
rake vcenter:recategorize

# Send daily report email
rake vcenter:send_daily_report

# Send weekly report email
rake vcenter:send_weekly_report
```

### Scheduled jobs

These run automatically via Solid Queue:

| Job | Schedule |
|---|---|
| `CollectEventsJob` | Every 5 minutes |
| `DailyReportJob` | 7:00 AM daily |
| `DataRetentionJob` | 2:00 AM on the 1st of each month |

## Testing

```bash
bin/rails test
```

Tests use mocked vSphere connections so no real vCenter is needed. The test suite covers:

- Event categorization and severity classification
- Scope filtering (category, user, severity, date range)
- vCenter event collector with mocked rbvmomi
- Dashboard and event browser controllers
- CSV export
- HTTP basic authentication
- Data retention job

## Event Categories

| Category | Event Types |
|---|---|
| VM Lifecycle | Create, deploy, clone, remove |
| VM Power | Power on/off, suspend, reset |
| VM Config | Reconfigure, rename, migrate, relocate |
| VM Snapshot | Create, remove, revert snapshot |
| Session | Login, logout, failed login |
| Permission | Add/remove/update permissions and roles |
| Host | Maintenance mode, connection events |
| Folder | Create, rename, remove folder |
| Datastore | File move, delete, copy |

## License

This project is available as open source.
