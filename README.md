# vSphere Auditor

A self-hosted VMware vSphere audit tool built with Ruby on Rails. Collects events from one or more vCenter servers, stores them in PostgreSQL, and provides a web UI, email reports, and real-time alerts for change tracking and compliance.

## Features

- **Multi-vCenter Support** — Manage multiple vCenter connections via the web UI with encrypted credential storage and per-connection health tracking
- **Automated Event Collection** — Polls vCenter EventManager every 5 minutes via rbvmomi, with deduplication and per-connection error handling
- **Smart Categorization** — Classifies events into categories (VM lifecycle, power, config, snapshots, sessions, permissions, host, folder, network, datastore) including TaskEvent message parsing
- **Web Dashboard** — Summary stats, recent warnings, activity breakdowns by category and user with clickable drill-downs
- **Event Browser** — Full-text search, filterable by vCenter, category, user, severity, object type, and date range with pagination
- **CSV Export** — Export filtered events for audits and reporting
- **Email Reports** — Styled HTML daily and weekly audit report emails with summary stats, warnings section, and full event listing
- **Real-Time Alerts** — Configurable alert rules via web UI that send immediate email notifications when matching events are detected
- **System Status** — Service health indicators (Rails, PostgreSQL, Solid Queue, vCenter), event activity sparkline, collection timing, data retention countdown, database table breakdown, and scheduled job overview
- **Dark Mode** — Automatic theme switching via `prefers-color-scheme`
- **Basic Auth** — Optional HTTP basic authentication
- **Data Retention** — Automatic monthly purge of events older than a configurable threshold
- **CI Pipeline** — GitHub Actions with tests, RuboCop, Brakeman, and bundler-audit

## Requirements

- Ruby 3.4+
- PostgreSQL 14+
- One or more VMware vCenter Servers

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
| `DATABASE_HOST` | PostgreSQL host | No (default: `localhost`) |
| `DATABASE_USERNAME` | PostgreSQL username | No (default: `vsphere_auditor`) |
| `DATABASE_PASSWORD` | PostgreSQL password | No (default: empty) |
| `REPORT_FROM_EMAIL` | Sender address for reports | No |
| `REPORT_RECIPIENTS` | Comma-separated recipient addresses | No |
| `AUTH_USERNAME` | HTTP basic auth username | No (auth disabled if blank) |
| `AUTH_PASSWORD` | HTTP basic auth password | No (auth disabled if blank) |
| `SMTP_ADDRESS` | SMTP server hostname | No (default: `localhost`) |
| `SMTP_PORT` | SMTP server port | No (default: `25`) |
| `AR_ENCRYPTION_PRIMARY_KEY` | Active Record encryption key | Yes (generate with `bin/rails db:encryption:init`) |
| `AR_ENCRYPTION_DETERMINISTIC_KEY` | Active Record deterministic key | Yes |
| `AR_ENCRYPTION_KEY_DERIVATION_SALT` | Active Record key derivation salt | Yes |
| `RETENTION_MONTHS` | Months of events to keep | No (default: `12`) |

### 4. Run migrations

```bash
bin/rails db:migrate
```

### 5. Start the app

```bash
bin/dev
```

This starts both Puma (web server) and Solid Queue (background jobs) via foreman. Browse to `http://localhost:3000`.

### 6. Add vCenter connections

Navigate to **vCenter Connections** in the sidebar and add your vCenter server(s). You can test each connection before enabling it. The collector will begin polling enabled connections every 5 minutes.

## Usage

### vCenter connections

Manage vCenter servers through the web UI at `/vcenter_connections`. Each connection stores:
- Hostname, username, and encrypted password
- Enabled/disabled status
- Last collection time and error tracking

Use the **Test Connection** button to verify credentials before enabling collection.

### Manual operations

```bash
# Collect events from all active vCenter connections
rake vcenter:collect

# Re-categorize existing events (after updating classification rules)
rake vcenter:recategorize

# Send daily report email
rake vcenter:send_daily_report

# Send weekly report email
rake vcenter:send_weekly_report
```

### Alert rules

Configure real-time email alerts at `/alert_rules`. Each rule can match on:
- Event category (e.g., permission changes, snapshots)
- Severity level (warning, error, critical)
- Username pattern

When an incoming event matches an active rule, an alert email is sent immediately.

### Scheduled jobs

These run automatically via Solid Queue:

| Job | Schedule |
|---|---|
| `CollectEventsJob` | Every 5 minutes |
| `DailyReportJob` | 7:00 AM daily |
| `WeeklyReportJob` | 7:00 AM Monday |
| `DataRetentionJob` | 2:00 AM on the 1st of each month |

## Testing

```bash
bin/rails test
```

Tests use mocked vSphere connections so no real vCenter is needed. The test suite covers:

- Event categorization and severity classification
- Scope filtering (vCenter, category, user, severity, date range, search)
- vCenter event collector with mocked rbvmomi
- VcenterConnection model (encryption, validation, status tracking)
- Dashboard, event browser, and system status controllers
- Alert rules CRUD and matching logic
- vCenter connections CRUD and test connection
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
| Network | vSwitch, port group, VMkernel, network config |
| Datastore | File move, delete, copy |

## License

This project is available as open source.
