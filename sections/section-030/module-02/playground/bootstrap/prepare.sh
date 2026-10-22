#!/usr/bin/env bash
# OS prep for the "Store Keycloak Data In PostgreSQL And Import A Realm" playground (`ats-088-playground-030-02`).
#
# Environment preparation only. There is no task and no grading. This script:
#   1. applies the starting workloads (PostgreSQL 17, Keycloak 26.8.1 on dev-file, tester),
#   2. adds the inventory realm file as a ConfigMap that nothing mounts yet,
#   3. waits until PostgreSQL and Keycloak are ready.
set -euo pipefail

NAMESPACE="database-demo"
EXTRA_MANIFESTS="configmap-inventory-realm.yaml"

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
if [ -n "$MANIFEST_DIR" ]; then
  for manifest in $EXTRA_MANIFESTS; do
    [ -f "$MANIFEST_DIR/$manifest" ] || continue
    echo "[playground] Applying $manifest..."
    kubectl apply -f "$MANIFEST_DIR/$manifest"
  done
fi

echo "[playground] Waiting for PostgreSQL and Keycloak (this can take a few minutes)..."
kubectl -n "$NAMESPACE" rollout status deployment/postgres --timeout=300s
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
kubectl -n "$NAMESPACE" rollout status deployment/tester --timeout=300s

echo "[playground] Ready."
kubectl -n "$NAMESPACE" get pods -o wide
echo "[playground] Keycloak still stores its data in dev-file. Moving it to PostgreSQL is the module's subject."
