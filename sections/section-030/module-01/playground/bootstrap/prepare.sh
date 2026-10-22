#!/usr/bin/env bash
# OS prep for the "Run Keycloak From The Container Image In Production Mode" playground (`ats-088-playground-030-01`).
#
# Environment preparation only. There is no task and no grading. This script:
#   1. applies the module's starting workloads (Keycloak 26.8.1 in development mode and tester),
#   2. waits until Keycloak answers on /health/ready.
set -euo pipefail

NAMESPACE="image-demo"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

# lab-start.yaml is also listed under bootstrap.manifests in config.yaml, so it
# may already be applied. kubectl apply is idempotent.
if [ -n "$MANIFEST_DIR" ] && [ -f "$MANIFEST_DIR/lab-start.yaml" ]; then
  echo "[playground] Applying starting workloads..."
  kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
fi

# The first rollout pulls a large image and Keycloak takes a while to start.
echo "[playground] Waiting for Keycloak (this can take a few minutes)..."
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
kubectl -n "$NAMESPACE" rollout status deployment/tester --timeout=300s

echo "[playground] Ready."
kubectl -n "$NAMESPACE" get pods -o wide
echo "[playground] Keycloak runs start-dev and answers at http://keycloak:8080 from the tester pod."
