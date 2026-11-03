#!/usr/bin/env bash
# Creates the starting state for ats-088-lab-020-02.
# Creates the realm inventory, the user alice and the client inventory-auditor with a
# service account that has NO administration roles. Assigning the role is the task.
set -euo pipefail

NAMESPACE="adminapi-demo"

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

echo "[lab] Creating inventory-auditor without administration roles..."
kcadm create clients -r inventory -s clientId=inventory-auditor -s enabled=true \
  -s publicClient=false -s serviceAccountsEnabled=true \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s secret=inventory-auditor-secret

echo "[lab] Starting state ready. The auditor gets 403 from the user list. Fixing that is the task."
