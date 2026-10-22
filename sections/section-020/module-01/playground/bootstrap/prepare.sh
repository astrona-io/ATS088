#!/usr/bin/env bash
# OS prep for the "Separate Administration From Applications With Realms" playground (`ats-088-playground-020-01`).
#
# Environment preparation only. There is no task and no grading. This script:
#   1. applies the module's starting workloads (Keycloak 26.8.1 and tester),
#   2. waits until Keycloak answers on /health/ready,
#   3. checks that the bootstrap administrator can sign in.
# It creates no realm, user or client: the reader builds them in the module.
set -euo pipefail

NAMESPACE="realms-demo"

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

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}

# The bootstrap administrator can need a few seconds after /health/ready.
signed_in=false
for _ in $(seq 1 30); do
  if kcadm config credentials --server http://localhost:8080 --realm master \
       --user admin --password admin >/dev/null 2>&1; then
    signed_in=true
    break
  fi
  sleep 5
done
if [ "$signed_in" != "true" ]; then
  echo "[playground] ERROR: the bootstrap administrator could not sign in to master." >&2
  exit 1
fi

echo "[playground] Ready."
kubectl -n "$NAMESPACE" get pods -o wide
echo "[playground] Keycloak answers at http://keycloak:8080 from the tester pod. Only the master realm exists."
