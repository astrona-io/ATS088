#!/usr/bin/env bash
# PASS when inventory-reporter has direct access grants and the standard flow
# still switched off. Turning on the password grant is the wrong fix.
set -uo pipefail

NAMESPACE="protocols-demo"
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: could not sign in to Keycloak as the administrator."
  exit 1
fi

client_field() {
  kcadm get clients -r inventory -q clientId=inventory-reporter \
    --fields "$1" --format csv --noquotes 2>/dev/null | tr -d '\r'
}

DIRECT_GRANTS="$(client_field directAccessGrantsEnabled)"
STANDARD_FLOW="$(client_field standardFlowEnabled)"

if [ "$DIRECT_GRANTS" != "false" ]; then
  echo "FAIL: direct access grants (the password grant) are on for inventory-reporter. A service client needs only client credentials."
  exit 1
fi
if [ "$STANDARD_FLOW" != "false" ]; then
  echo "FAIL: the standard flow (authorization code) is on for inventory-reporter. A service client has no browser sign-in."
  exit 1
fi

echo "PASS: inventory-reporter allows no grant besides client credentials."
exit 0
