#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

REQUIRED_CONTAINERS=("signoz-clickhouse" "signoz-zookeeper-1" "signoz" "signoz-otel-collector")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi

    if ! docker ps &> /dev/null; then
        log_error "Docker daemon is not running or you don't have permission"
        exit 1
    fi
}

get_container_status() {
    local container=$1
    docker ps -a --filter "name=^${container}$" --format "{{.Status}}" 2>/dev/null || echo "not found"
}

is_container_running() {
    local container=$1
    local status=$(get_container_status "$container")
    [[ "$status" == Up* ]]
}

are_all_running() {
    for container in "${REQUIRED_CONTAINERS[@]}"; do
        if ! is_container_running "$container"; then
            return 1
        fi
    done
    return 0
}

show_status() {
    log_info "SigNoz Stack Status:"
    echo ""

    local all_running=true
    for container in "${REQUIRED_CONTAINERS[@]}"; do
        local status=$(get_container_status "$container")
        if [[ "$status" == Up* ]]; then
            echo -e "  ${GREEN}✓${NC} $container: $status"
        elif [[ "$status" == "not found" ]]; then
            echo -e "  ${RED}✗${NC} $container: not created"
            all_running=false
        else
            echo -e "  ${YELLOW}!${NC} $container: $status"
            all_running=false
        fi
    done

    echo ""
    if $all_running; then
        log_info "All services running"
        log_info "SigNoz UI: http://localhost:8095"
        log_info "OTLP gRPC: localhost:4317"
        log_info "OTLP HTTP: http://localhost:4318"
    else
        log_warn "Not all services are running"
    fi
}

start_services() {
    if are_all_running; then
        log_info "All services already running"
        show_status
        return 0
    fi

    log_info "Starting SigNoz services..."
    docker compose up -d

    log_info "Waiting for services to be ready..."
    sleep 5

    local max_wait=60
    local waited=0
    while ! are_all_running && [ $waited -lt $max_wait ]; do
        echo -n "."
        sleep 2
        waited=$((waited + 2))
    done
    echo ""

    if are_all_running; then
        log_info "All services started successfully"
        show_status
    else
        log_warn "Some services may not be fully started yet"
        show_status
    fi
}

stop_services() {
    log_info "Stopping SigNoz services..."
    docker compose stop
    log_info "Services stopped"
}

restart_services() {
    log_info "Restarting SigNoz services..."
    docker compose restart
    log_info "Services restarted"
    show_status
}

show_logs() {
    local service=$1
    if [ -z "$service" ]; then
        docker compose logs -f
    else
        docker compose logs -f "$service"
    fi
}

cleanup() {
    log_warn "This will stop and remove all containers (data will be preserved in volumes)"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker compose down
        log_info "Cleanup complete"
    else
        log_info "Cancelled"
    fi
}

full_cleanup() {
    log_error "This will REMOVE ALL DATA including volumes!"
    read -p "Are you absolutely sure? Type 'DELETE' to confirm: " -r
    echo
    if [[ $REPLY == "DELETE" ]]; then
        docker compose down -v
        log_info "Full cleanup complete (all data removed)"
    else
        log_info "Cancelled"
    fi
}

health_check() {
    log_info "Checking service health..."
    echo ""

    # Check ClickHouse
    if docker exec signoz-clickhouse clickhouse-client --query="SELECT 1" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} ClickHouse: healthy"
    else
        echo -e "  ${RED}✗${NC} ClickHouse: unhealthy"
    fi

    # Check SigNoz UI
    if curl -s http://localhost:8095/api/v1/health &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} SigNoz UI: healthy"
    else
        echo -e "  ${YELLOW}!${NC} SigNoz UI: not responding"
    fi

    # Check OTLP Collector - check if container is running and ports are listening
    if is_container_running "signoz-otel-collector"; then
        # Check if OTLP gRPC port is listening
        if nc -z localhost 4317 2>/dev/null || (command -v lsof &>/dev/null && lsof -i :4317 &>/dev/null); then
            echo -e "  ${GREEN}✓${NC} OTLP Collector: healthy (gRPC:4317, HTTP:4318)"
        else
            echo -e "  ${YELLOW}!${NC} OTLP Collector: running but ports may not be ready"
        fi
    else
        echo -e "  ${RED}✗${NC} OTLP Collector: not running"
    fi
}

show_help() {
    cat << EOF
SigNoz Management Script

Usage: $0 [command]

Commands:
    start       Start all SigNoz services (default if already running, shows status)
    stop        Stop all services
    restart     Restart all services
    status      Show status of all services
    logs        Show logs from all services
    logs <svc>  Show logs from specific service (signoz, clickhouse, otel-collector, zookeeper-1)
    health      Run health checks on all services
    cleanup     Stop and remove containers (keeps data)
    purge       Stop and remove everything including data volumes
    help        Show this help message

Examples:
    $0              # Smart start (starts if not running, shows status if running)
    $0 start        # Start services
    $0 logs signoz  # Show logs for signoz service
    $0 health       # Check service health

EOF
}

# Main script logic
check_docker

case "${1:-start}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    health)
        health_check
        ;;
    cleanup)
        cleanup
        ;;
    purge)
        full_cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
