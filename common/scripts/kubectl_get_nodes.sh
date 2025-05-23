#!/usr/bin/env bash

# kubectl get nodes -o wide
LOG_FILE="${HOME}/k8s_node_check.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_k8s_nodes() {
    log "Checking Kubernetes nodes..."

    OUTPUT=$(kubectl get nodes -o wide 2>&1)
    STATUS=$?

    if [[ $STATUS -ne 0 ]]; then
        log "❌ Error running 'kubectl get nodes': $OUTPUT"
        echo "🚫 It does not appear here. Please check your cluster context or kubectl configuration."
        return 1
    fi

    if echo "$OUTPUT" | grep -q "No resources found"; then
        log "⚠️ No nodes found."
        echo "📭 It does not appear here. No nodes are registered in this cluster."
        return 0
    fi

    echo "✅ Nodes found:"
    echo "$OUTPUT" | tee -a "$LOG_FILE"
}

check_k8s_nodes
