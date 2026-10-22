#!/usr/bin/env bash
# PASS when inventory-cli in the inventory realm is a public client with direct
# access grants on and the standard flow off.
set -uo pipefail

NS="realmscapstone-demo"
kcadm() {
  kubectl -n "$NS" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/grader-kcadm.config
}
# Prints one field of inventory-cli in the inventory realm. One field per call,
# so the result never depends on the column order of the CSV output.
client_field() {
  kcadm get clients -r inventory -q clientId=inventory-cli --fields "$1" \
    --format csv --noquotes 2>/dev/null | head -n 1 | tr -d '[:space:]'
}

if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: the grader could not sign in to master as admin."
  exit 1
fi

if [ -z "$(client_field clientId)" ]; then
  echo "FAIL: the client inventory-cli does not exist in the realm inventory."
  exit 1
fi

PUBLIC_CLIENT="$(client_field publicClient)"
DIRECT_GRANTS="$(client_field directAccessGrantsEnabled)"
STANDARD_FLOW="$(client_field standardFlowEnabled)"

if [ "$PUBLIC_CLIENT" != "true" ]; then
  echo "FAIL: inventory-cli must be a public client (publicClient=true), found publicClient=$PUBLIC_CLIENT."
  exit 1
fi
if [ "$DIRECT_GRANTS" != "true" ]; then
  echo "FAIL: inventory-cli must allow direct access grants, found directAccessGrantsEnabled=$DIRECT_GRANTS."
  exit 1
fi
if [ "$STANDARD_FLOW" != "false" ]; then
  echo "FAIL: inventory-cli must have the standard flow off, found standardFlowEnabled=$STANDARD_FLOW."
  exit 1
fi

echo "PASS: inventory-cli is a public client with direct access grants on and the standard flow off."
exit 0
