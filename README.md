# SigNoz OTEL Observability Stack

Local OpenTelemetry metrics collection and visualization for Claude Code.

## Setup Complete ✅

All services are running and ready to accept OTEL data.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **SigNoz UI** | 8080 | Dashboard and visualization |
| **OTEL Collector (gRPC)** | 4317 | OTLP data ingestion |
| **OTEL Collector (HTTP)** | 4318 | OTLP data ingestion |

## Access SigNoz

**Dashboard:** http://localhost:8080

On first access, create an admin account.

## Claude Code Integration

### ✅ Configuration Applied

Claude Code has been configured to send OTEL metrics to SigNoz.

**Settings configured in `~/.claude/settings.json`:**
```json
"DISABLE_TELEMETRY": "0",
"OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4318",
"OTEL_EXPORTER_OTLP_PROTOCOL": "http/protobuf",
"OTEL_SERVICE_NAME": "claude-code"
```

### Next Steps to Start Collecting Metrics

**1. Restart Claude Code**
Exit the current Claude Code session and start a new one for the OTEL configuration to take effect.

**2. Create SigNoz Admin Account (First Time Only)**

On first access to http://localhost:8080, create an admin account.

**Recommended Simple Credentials:**
- **Email:** `admin@localhost` (doesn't need to be real)
- **Password:** `Admin123!` (requires 8+ chars, mix of upper/lower/numbers/symbols)
- **Name:** `Admin`

**3. Verify Metrics Collection**
After restarting Claude Code and using it for a few operations:

1. Open SigNoz Dashboard: http://localhost:8080 (login with credentials above)
2. Navigate to **Services** tab
3. Look for "claude-code" service in the list
4. Click on the service to view metrics
5. Go to **Metrics** tab to explore all collected metrics
6. Create custom dashboards as needed

**3. Troubleshoot (if no metrics appear)**

Check OTEL Collector logs:
```bash
cd ~/dev/prj/personal/signoz
docker compose logs -f otel-collector | grep -i claude
```

Verify SigNoz is receiving data:
```bash
docker compose logs -f signoz
```

## Data Export

### From SigNoz UI
- Export charts/panels to CSV
- Export query results to JSON
- Dashboard export/import via JSON

### Via ClickHouse Direct
```bash
# Connect to ClickHouse
docker exec -it signoz-clickhouse clickhouse-client

# Export data
docker exec signoz-clickhouse clickhouse-client --query="SELECT * FROM signoz_metrics.distributed_time_series_v4_1day LIMIT 100" --format CSV > metrics_export.csv
```

## Management Commands

### Using the Smart Script (Recommended)

The `signoz.sh` script provides intelligent management with health checks and status monitoring.

```bash
cd ~/dev/prj/personal/signoz

# Smart start (starts if not running, shows status if already running)
./signoz.sh

# Or explicitly
./signoz.sh start    # Start all services
./signoz.sh stop     # Stop all services
./signoz.sh restart  # Restart all services
./signoz.sh status   # Show service status
./signoz.sh health   # Run health checks
./signoz.sh logs     # Show all logs
./signoz.sh logs signoz  # Show logs for specific service
./signoz.sh cleanup  # Stop and remove containers (keeps data)
./signoz.sh purge    # Remove everything including data (requires confirmation)
```

### Using Docker Compose Directly

```bash
cd ~/dev/prj/personal/signoz

# Start services
docker compose up -d

# Stop services
docker compose stop

# View logs
docker compose logs -f
docker compose logs -f otel-collector

# Check status
docker compose ps

# Stop and remove (keep data)
docker compose down

# Stop and remove all (including data)
docker compose down -v
```

## Configuration

### Retention Periods

**Defaults:**
- Logs: 7 days
- Traces: 7 days
- Metrics: 30 days

**Adjust via UI:** SigNoz Dashboard → Settings → General

### Resource Requirements

- **RAM:** Minimum 4GB allocated to Docker
- **Disk:** ~1GB for images, data grows with retention

## Troubleshooting

### Check Service Health
```bash
docker exec signoz wget -q -O- http://localhost:8080/api/v1/health
```

### View Errors
```bash
docker compose logs --tail=50 | grep -i error
```
