#!/usr/bin/env bash
# OS prep for the "Get Tokens From Keycloak With OAuth 2.0 And OpenID Connect" playground (`ats-088-playground-010-01`).
#
# Environment preparation only. There is no task and no grading. This script:
#   1. applies the module's starting workloads (Keycloak 26.8.1 and tester),
#   2. waits until Keycloak answers on /health/ready,
#   3. creates the inventory realm, the user alice and the module's clients.
set -euo pipefail

NAMESPACE="protocols-demo"

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
for _ in $(seq 1 30); do
  kcadm config credentials --server http://localhost:8080 --realm master \
    --user admin --password admin >/dev/null 2>&1 && break
  sleep 5
done

echo "[playground] Creating the inventory realm, the user alice and the clients..."
if ! kcadm get realms/inventory >/dev/null 2>&1; then
  kcadm create realms -s realm=inventory -s enabled=true
fi
if [ -z "$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes)" ]; then
  kcadm create users -r inventory -s username=alice -s enabled=true \
    -s email=alice@example.com -s emailVerified=true \
    -s firstName=Alice -s lastName=Example
  kcadm set-password -r inventory --username alice --new-password alice-password
fi
if [ -z "$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes)" ]; then
  kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
    -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
fi
if [ -z "$(kcadm get clients -r inventory -q clientId=inventory-reporter --fields id --format csv --noquotes)" ]; then
  kcadm create clients -r inventory -s clientId=inventory-reporter -s enabled=true \
    -s publicClient=false -s serviceAccountsEnabled=true \
    -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
    -s secret=inventory-reporter-secret
fi

echo "[playground] Ready."
kubectl -n "$NAMESPACE" get pods -o wide
echo "[playground] Keycloak answers at http://keycloak:8080 from the tester pod."
