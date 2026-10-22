#!/usr/bin/env bash
# Deploys Keycloak 26.8.1 (development mode) and the tester pod into realmscapstone-demo.
#
# Graded lab bootstrap: this prepares the environment ONLY. It never creates
# the objects the task asks for.
set -euo pipefail

NAMESPACE="realmscapstone-demo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Applying starting workloads..."
kubectl apply -f "$MANIFESTS/lab-start.yaml"

# The first rollout pulls a large image and Keycloak takes a while to start.
echo "[lab] Waiting for Keycloak (this can take a few minutes)..."
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
kubectl -n "$NAMESPACE" rollout status deployment/tester --timeout=300s

echo "[lab] Keycloak ready."
