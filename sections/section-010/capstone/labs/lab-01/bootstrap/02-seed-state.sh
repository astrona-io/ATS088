#!/usr/bin/env bash
# Creates the starting state for ats-088-capstone-010.
#
# Creates the realm inventory with three independent faults that each stop
# alice from getting tokens through inventory-cli:
#   1. inventory-cli has direct access grants (the password grant) switched off,
#   2. alice is disabled,
#   3. alice has a temporary password, so she carries the UPDATE_PASSWORD
#      required action.
# It also records the IDs of alice and inventory-cli in the ConfigMap
# capstone-baseline, so the grader can tell a fix from a delete-and-recreate.
#
# The fixes are NOT applied here — finding and applying them is the task.
set -euo pipefail

NAMESPACE="protocolscapstone-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

echo "[lab] Creating the realm inventory..."
kcadm create realms -s realm=inventory -s enabled=true

echo "[lab] Creating the user alice (disabled, temporary password)..."
kcadm create users -r inventory -s username=alice -s enabled=false \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example
kcadm set-password -r inventory --username alice --new-password alice-password --temporary

echo "[lab] Creating inventory-cli with direct access grants off..."
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=false

echo "[lab] Creating inventory-reporter (working, not part of the fault)..."
kcadm create clients -r inventory -s clientId=inventory-reporter -s enabled=true \
  -s publicClient=false -s serviceAccountsEnabled=true \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s secret=inventory-reporter-secret

ALICE_ID=$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes | tr -d '\r')
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')

kubectl -n "$NAMESPACE" create configmap capstone-baseline \
  --from-literal=alice-id="$ALICE_ID" \
  --from-literal=inventory-cli-id="$CLI_ID" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
echo "[lab] alice cannot get tokens through inventory-cli. Finding out why is the task."
