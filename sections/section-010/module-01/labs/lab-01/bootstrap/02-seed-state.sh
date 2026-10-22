#!/usr/bin/env bash
# Creates the starting state for ats-088-lab-010-01.
#
# Creates the realm inventory, the user alice and the public client
# inventory-cli as in the module, then creates inventory-reporter the WRONG
# way: as a public client with no service account, so the client credentials
# grant fails for it.
#
# The corrected client and the Kubernetes Secret are NOT created here —
# producing them is the task.
set -euo pipefail

NAMESPACE="protocols-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

echo "[lab] Creating the inventory realm, the user alice and inventory-cli..."
kcadm create realms -s realm=inventory -s enabled=true
kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example
kcadm set-password -r inventory --username alice --new-password alice-password
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true

echo "[lab] Creating inventory-reporter as a public client without a service account..."
kcadm create clients -r inventory -s clientId=inventory-reporter -s enabled=true \
  -s publicClient=true -s serviceAccountsEnabled=false \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=false

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
echo "[lab] The client credentials grant for inventory-reporter currently fails. Fixing that is the task."
