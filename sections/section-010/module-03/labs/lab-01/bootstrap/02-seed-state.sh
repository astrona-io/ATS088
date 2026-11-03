#!/usr/bin/env bash
# Creates the starting state for ats-088-lab-010-03.
# Creates the realm inventory, the user alice, the client inventory-cli and the client
# inventory-api. Tokens of inventory-cli do not list inventory-api. Fixing that is the task.
set -euo pipefail

NAMESPACE="tokenval-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
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
if [ -z "$(kcadm get clients -r inventory -q clientId=inventory-api --fields id --format csv --noquotes)" ]; then
  kcadm create clients -r inventory -s clientId=inventory-api -s enabled=true \
    -s publicClient=false -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
    -s secret=inventory-api-secret
fi
echo "[lab] Starting state ready. Tokens of inventory-cli do not list inventory-api in aud."
