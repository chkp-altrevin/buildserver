#!/bin/bash

# Function to filter containers based on name
filter_containers() {
    docker ps --format "{{.Names}}" | grep "$1"
}

# Function to filter logs based on container name and pattern
filter_logs() {
    container_name="$1"
    pattern="$2"
    docker logs "$container_name" 2>&1 | grep "$pattern"
}

# Check if the script is called with the correct arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <filter_type> <filter_value> [pattern]"
    echo "  filter_type: 'container' or 'logs'"
    echo "  filter_value: container name or pattern to search for"
    echo "  pattern (optional): pattern to search for in logs"
    exit 1
fi

filter_type="$1"
filter_value="$2"

case "$filter_type" in
    "container")
        filter_containers "$filter_value"
        ;;
    "logs")
        if [ $# -lt 3 ]; then
            echo "Please provide a pattern to search for in the logs."
            exit 1
        fi
        filter_logs "$filter_value" "$3"
        ;;
    *)
        echo "Invalid filter type. Use 'container' or 'logs'."
        exit 1
        ;;
esac
