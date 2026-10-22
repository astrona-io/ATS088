#!/usr/bin/env bash
# Creates the starting state for ats-088-lab-030-02.
#
# Keycloak already runs in development mode on the built-in dev-file database.
# This adds the inventory realm as a ConfigMap that nothing mounts yet.
#
# The PostgreSQL settings and the realm import are NOT configured here -
# producing them is the task.
set -euo pipefail

NAMESPACE="database-demo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Adding the inventory realm file as a ConfigMap..."
kubectl apply -f "$MANIFESTS/configmap-inventory-realm.yaml"

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
echo "[lab] Keycloak stores its data in dev-file and has no inventory realm. Changing that is the task."
