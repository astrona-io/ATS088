#!/usr/bin/env bash
# Deploys the starting workloads for ats-088-capstone-030.
#
# Graded lab bootstrap: this prepares the environment ONLY. It never creates
# the objects the task asks for. Keycloak starts here in a healthy state so the
# large image is pulled once; the next script puts the lab's fault in place.
set -euo pipefail

NAMESPACE="runcapstone-demo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Applying starting workloads..."
kubectl apply -f "$MANIFESTS/lab-start.yaml"

kubectl -n "$NAMESPACE" rollout status deployment/postgres --timeout=300s
# The first rollout pulls a large image and Keycloak takes a while to start.
echo "[lab] Waiting for Keycloak (this can take a few minutes)..."
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
kubectl -n "$NAMESPACE" rollout status deployment/tester --timeout=300s

echo "[lab] Workloads ready."
