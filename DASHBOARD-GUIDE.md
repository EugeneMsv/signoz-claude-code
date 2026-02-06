# Claude Code Dashboard Guide

## Dashboard Overview

This dashboard provides comprehensive monitoring for Claude Code with 4 main sections:

### 📊 Section 1: Code Productivity (Top Priority)
**Metrics:**
- Lines of Code Added/Removed (total + timeline)
- Productivity Rate (lines per hour)
- Total Commits + Timeline + Rate
- Total Pull Requests + Timeline + Rate

### ⏱️ Section 2: Sessions & Active Time
**Metrics:**
- Total Sessions + Timeline
- Active Time (formatted as "Xh Ym") + Timeline
- Average Tokens per Session

### 💰 Section 3: Cost & Tokens
**Metrics:**
- Total Cost (USD) + Timeline
- Cost by Model comparison
- Average Cost per Session
- Total Tokens + Timeline
- Tokens by Type (Input, Output, Cache Read, Cache Creation)
- Tokens by Model
- Cache Hit Rate (%)

### 🛠️ Section 4: Tool Analysis
**Metrics:**
- Tool Decisions by Type (Accept vs Reject)
- Tool Decisions by Tool (Edit, Write, NotebookEdit)
- Tool Decisions by Language (Python, TypeScript, etc.)

## How to Import Dashboard

### Method 1: Via SigNoz UI (Recommended)

1. **Open SigNoz Dashboard**
   ```
   http://localhost:8080
   ```

2. **Navigate to Dashboards**
   - Click **Dashboards** in left sidebar
   - Click **+ New Dashboard** button

3. **Import Dashboard**
   - Click the **⋮** (three dots) menu
   - Select **Import Dashboard**
   - Upload `claude-code-dashboard.json`
   - Click **Import**

### Method 2: Via API

```bash
cd ~/dev/prj/personal/signoz

curl -X POST http://localhost:8080/api/v1/dashboards \
  -H "Content-Type: application/json" \
  -d @claude-code-dashboard.json
```

### Method 3: Manual JSON Import

1. Go to http://localhost:8080/dashboards
2. Click **+ New Dashboard**
3. Click **Settings** (gear icon)
4. Click **JSON Model**
5. Paste contents of `claude-code-dashboard.json`
6. Click **Save**

## Dashboard Features

### Time Range Selector
- Located at top-right of dashboard
- Switch between: Last 1h, 6h, 24h, 7d, 30d, custom
- All panels update automatically

### Refresh Interval
- Auto-refresh available (5s, 10s, 30s, 1m, 5m)
- Manual refresh button
- Recommended: 30s for active monitoring

### Panel Interactions
- **Click chart** - Drill down into details
- **Hover** - See exact values
- **Legend click** - Toggle series on/off
- **Drag time range** - Zoom into specific period

## Understanding the Metrics

### Productivity Metrics

**Lines of Code:**
- Shows actual code modifications
- "Added" = new lines written
- "Removed" = lines deleted
- High values indicate heavy coding sessions

**Productivity Rate:**
- Formula: Total lines changed / Active hours
- Higher = more productive coding
- Varies by task complexity

**Commits & PRs:**
- Tracks completed work
- Rate shows consistency over time
- Zero values normal if not using git features

### Session Metrics

**Session Count:**
- Each `claude` command = 1 session
- Interactive sessions only (not `--print` mode)

**Active Time:**
- Only counts actual interaction time
- Excludes idle periods
- More accurate than total session time

**Tokens per Session:**
- Average conversation size
- Higher = more complex discussions
- Lower = quick questions

### Cost Metrics

**Total Cost:**
- Cumulative spending
- Based on token usage and model
- Approximate (check official billing for exact)

**Cost by Model:**
- Opus > Sonnet > Haiku (typical)
- Shows model selection patterns

**Cache Hit Rate:**
- % of tokens from cache (cheaper)
- Higher = better cost efficiency
- >50% is good caching utilization

### Token Metrics

**Token Types:**
- **Input:** Your prompts and context
- **Output:** Claude's responses
- **Cache Read:** Tokens from cache (5x cheaper)
- **Cache Creation:** Building new cache entries

**Typical Ratios:**
- Output usually > Input (Claude writes more)
- High Cache Read = good efficiency
- Cache Creation appears once, then reused

### Tool Decisions

**Accept/Reject:**
- Acceptance rate shows trust/confidence
- High reject rate may indicate:
  - Claude making mistakes
  - Conservative user behavior
  - Complex/risky changes

**By Tool:**
- **Edit:** Modifying existing files
- **Write:** Creating new files
- **NotebookEdit:** Jupyter notebook edits

**By Language:**
- Shows which languages you work with
- Useful for understanding work patterns

## Troubleshooting

### "No Data" on Panels

**Possible causes:**

1. **Metric not generated yet**
   - Some metrics only appear after specific actions
   - Example: Commits only show after creating commits

2. **Time range too narrow**
   - Try expanding to "Last 7 days"
   - Check if any data exists in wider range

3. **Service name mismatch**
   - Verify metrics use `service_name="claude-code"`
   - Check: `docker exec signoz-clickhouse clickhouse-client --query="SELECT DISTINCT resource_attrs['service.name'] FROM signoz_metrics.distributed_time_series_v4_1day"`

4. **Metrics not exported yet**
   - Wait for export interval (10s for metrics, 5s for logs)
   - Generate activity: run some Claude Code commands

### Wrong Values

**Check metric configuration:**
```bash
# View available metrics
docker exec signoz-clickhouse clickhouse-client --query="
  SELECT metric_name, COUNT(*)
  FROM signoz_metrics.distributed_time_series_v4_1day
  WHERE resource_attrs['service.name'] = 'claude-code'
  GROUP BY metric_name
"
```

**Verify OTEL settings:**
```bash
cat ~/.claude/settings.json | grep -A 10 CLAUDE_CODE_ENABLE_TELEMETRY
```

### Panels Not Loading

1. **Check SigNoz health:**
   ```bash
   cd ~/dev/prj/personal/signoz
   docker compose ps
   docker compose logs signoz | tail -50
   ```

2. **Check ClickHouse:**
   ```bash
   docker exec signoz-clickhouse clickhouse-client --query="SELECT 1"
   ```

3. **Restart SigNoz:**
   ```bash
   docker compose restart signoz
   ```

## Customization

### Adding New Panels

1. Click **Add Panel** button
2. Select metric from dropdown
3. Choose visualization type
4. Configure legend, units, colors
5. Save panel

### Modifying Queries

1. Click panel title → **Edit**
2. Modify PromQL query
3. Test query with **Run Query**
4. Save changes

### Changing Layout

1. **Drag panels** to reposition
2. **Resize** by dragging corners
3. **Delete** via panel menu (⋮)
4. Save dashboard when done

## Export Options

### Export Dashboard

1. Dashboard Settings (gear icon)
2. **JSON Model** → Copy
3. Save to file for backup/sharing

### Export Panel Data

1. Click panel title
2. **Inspect** → **Data**
3. Download as CSV or JSON

### Export via ClickHouse

```bash
# Export specific metric data
docker exec signoz-clickhouse clickhouse-client --query="
  SELECT
    toDateTime(unix_milli / 1000) as time,
    metric_name,
    resource_attrs['service.name'] as service,
    attrs
  FROM signoz_metrics.distributed_time_series_v4_1day
  WHERE resource_attrs['service.name'] = 'claude-code'
  ORDER BY time DESC
  LIMIT 1000
" --format CSV > claude_code_metrics.csv
```

## Best Practices

### Daily Monitoring

1. Check **Cost Over Time** - Stay within budget
2. Review **Productivity Rate** - Track output
3. Monitor **Cache Hit Rate** - Optimize costs

### Weekly Review

1. Compare **Sessions** week-over-week
2. Analyze **Cost by Model** - Optimize model selection
3. Review **Tool Decisions** - Improve workflows

### Monthly Analysis

1. Calculate ROI: Productivity vs Cost
2. Identify patterns in **Active Time**
3. Adjust usage based on metrics

## Support

**Dashboard Issues:**
- Check: `~/dev/prj/personal/signoz/README.md`
- SigNoz Docs: https://signoz.io/docs/
- GitHub: https://github.com/SigNoz/signoz/issues

**Claude Code Telemetry:**
- Docs: https://code.claude.com/docs/en/monitoring-usage
- Settings: `~/.claude/settings.json`

**Quick Health Check:**
```bash
# Verify everything is working
cd ~/dev/prj/personal/signoz
docker compose ps
claude --print "test" && echo "✅ Claude Code + OTEL working"
```
