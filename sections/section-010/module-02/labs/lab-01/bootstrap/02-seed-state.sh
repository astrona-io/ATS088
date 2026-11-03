#!/usr/bin/env bash
# Creates the starting state for ats-088-lab-010-02.
# Creates the realm inventory, the user alice and the client inventory-web registered
# the WRONG way: wildcard redirect URIs and web origins, PKCE not required and the
# password grant on. The corrected client is NOT created here; fixing it is the task.
set -euo pipefail

NAMESPACE="authcode-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

echo "[lab] Creating the inventory realm and the user alice..."
kcadm create realms -s realm=inventory -s enabled=true
kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example
kcadm set-password -r inventory --username alice --new-password alice-password

echo "[lab] Creating inventory-web with wildcards and no PKCE..."
kcadm create clients -r inventory -s clientId=inventory-web -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=true -s directAccessGrantsEnabled=true \
  -s 'redirectUris=["*"]' -s 'webOrigins=["*"]'

echo "[lab] Starting state ready. The client inventory-web is too open. Fixing that is the task."
