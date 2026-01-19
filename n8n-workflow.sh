#!/bin/bash
# n8n Workflow Management Shortcuts
# Usage: ./n8n-workflow.sh <command> [args]

set -e

# Configuration
N8N_API_URL="https://n8n.kynsoft.net"
N8N_API_KEY="${N8N_API_KEY:-}"
MCP_URL="http://localhost:3000"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if MCP server is running
check_mcp() {
    if ! curl -s "$MCP_URL/health" > /dev/null; then
        log_error "MCP server not running at $MCP_URL"
        log_info "Start with: docker-compose up -d n8n-mcp"
        exit 1
    fi
}

# List all workflows
list_workflows() {
    log_info "Listing workflows from n8n server..."
    response=$(curl -s -X GET "$N8N_API_URL/api/v1/workflows" \
        -H "X-N8N-API-KEY: $N8N_API_KEY" \
        -H "Content-Type: application/json")

    # Check if response contains workflows array directly
    if echo "$response" | jq -e '.[]? | select(.id?)' > /dev/null 2>&1; then
        echo "$response" | jq -r '.[] | "ID: \(.id) | Name: \(.name) | Active: \(.active) | Created: \(.createdAt) | Updated: \(.updatedAt)"'
    else
        log_error "Unexpected API response format"
        echo "$response" | head -20
    fi
}

# Get workflow by ID
get_workflow() {
    local workflow_id="$1"
    if [ -z "$workflow_id" ]; then
        log_error "Workflow ID required"
        echo "Usage: $0 get <workflow_id>"
        exit 1
    fi

    log_info "Getting workflow $workflow_id..."
    curl -s -X GET "$N8N_API_URL/api/v1/workflows/$workflow_id" \
        -H "X-N8N-API-KEY: $N8N_API_KEY" \
        -H "Content-Type: application/json"
}

# Update workflow
update_workflow() {
    local workflow_id="$1"
    local file_path="$2"

    if [ -z "$workflow_id" ] || [ -z "$file_path" ]; then
        log_error "Workflow ID and file path required"
        echo "Usage: $0 update <workflow_id> <file_path>"
        exit 1
    fi

    if [ ! -f "$file_path" ]; then
        log_error "File not found: $file_path"
        exit 1
    fi

    log_info "Updating workflow $workflow_id with $file_path..."
    curl -s -X PUT "$N8N_API_URL/api/v1/workflows/$workflow_id" \
        -H "X-N8N-API-KEY: $N8N_API_KEY" \
        -H "Content-Type: application/json" \
        -d @"$file_path" | jq .
}

# Delete workflow
delete_workflow() {
    local workflow_id="$1"
    if [ -z "$workflow_id" ]; then
        log_error "Workflow ID required"
        echo "Usage: $0 delete <workflow_id>"
        exit 1
    fi

    log_warning "Deleting workflow $workflow_id..."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled"
        exit 0
    fi

    curl -s -X DELETE "$N8N_API_URL/api/v1/workflows/$workflow_id" \
        -H "X-N8N-API-KEY: $N8N_API_KEY" \
        -H "Content-Type: application/json"
}

# Validate workflow
validate_workflow() {
    local file_path="$1"
    if [ -z "$file_path" ]; then
        log_error "File path required"
        echo "Usage: $0 validate <file_path>"
        exit 1
    fi

    log_info "Validating workflow JSON..."
    if jq . "$file_path" > /dev/null 2>&1; then
        log_success "JSON is valid"
    else
        log_error "JSON is invalid"
        exit 1
    fi
}

# Main command dispatcher
case "$1" in
    list)
        check_mcp
        list_workflows
        ;;
    get)
        check_mcp
        get_workflow "$2"
        ;;
    update)
        check_mcp
        update_workflow "$2" "$3"
        ;;
    delete)
        check_mcp
        delete_workflow "$2"
        ;;
    validate)
        validate_workflow "$2"
        ;;
    health)
        curl -s "$MCP_URL/health" | jq .
        ;;
    *)
        echo "n8n Workflow Management Tool"
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  list                    List all workflows"
        echo "  get <id>               Get workflow by ID"
        echo "  update <id> <file>     Update workflow from JSON file"
        echo "  delete <id>            Delete workflow"
        echo "  validate <file>        Validate workflow JSON"
        echo "  health                 Check MCP server health"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 get E5pYhC0Z0YlUgiWT"
        echo "  $0 update E5pYhC0Z0YlUgiWT workflow.json"
        echo "  $0 validate workflow.json"
        ;;
esac
